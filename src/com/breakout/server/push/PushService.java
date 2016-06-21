package com.breakout.server.push;

import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;

import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.ServletContextAware;

import com.google.gson.Gson;

/**
 * push service
 * 
 * @author gue
 * @since 2016. 6. 9.
 * @copyright Copyright.2016.gue.All rights reserved.
 * @version 1.0
 * @history
 *          <ol>
 *          <li>변경자/날짜 : 변경사항</li>
 *          </ol>
 */
public class PushService implements ServletContextAware {
    private Logger _logger = LoggerFactory.getLogger(PushService.class);
    private static final String GCM_SEND_URL = "https://gcm-http.googleapis.com/gcm/send";
    @Autowired
    private ServletContext servletContext;
    private Gson _gson;
    private PushDAO _pushDao;
    private String _apiKey;

    /*
     * (non-Javadoc)
     * 
     * @see org.springframework.web.context.ServletContextAware#setServletContext(javax.servlet.ServletContext)
     */
    @Override
    public void setServletContext(ServletContext servletContext) {
        this.servletContext = servletContext;
    }

    /**
     * @param gson the {@link #_gson} to set
     */
    public void setGson(Gson gson) {
        this._gson = gson;
    }

    /**
     * @param _pushDao the {@link #_pushDao} to set
     */
    public void setPushDao(PushDAO pushDao) {
        this._pushDao = pushDao;
    }

    /**
     * @param apiKey the {@link #_apiKey} to set
     */
    public void setApiKey(String apiKey) {
        this._apiKey = apiKey;
    }

    /**
     * send push service
     * 
     * @param requestMap SEND_KEY,...
     * @param request
     * @throws Exception
     * @author gue
     * @since 2016. 6. 10.
     * @history
     *          <ol>
     *          <li>변경자/날짜 : 변경사항</li>
     *          </ol>
     */
    @Transactional(propagation = Propagation.REQUIRED, rollbackFor = {
            Exception.class
    })
    public String sendMsg(Map<String, Object> requestMap, HttpServletRequest request) throws Exception {
        long startTime = System.currentTimeMillis();
        Map<String, Object> resultMap = new HashMap<>();

        String log = String.format("[%d %s]", startTime, requestMap.get("SEND_KEY"));
        String conLog = "";
        int cnt = 0;
        int successCnt = 0;
        List<Map<String, Object>> resultList = _pushDao.readPrepareMessage(requestMap);
        for (Map<String, Object> rowMap : resultList) {
            cnt++;
            conLog = String.format("[%d %05d] seq=%d", startTime, cnt, rowMap.get("SEQ_NO"));
            try {
                // Prepare JSON containing the GCM message content. What to send and where to send.
                String registration_ids = (String) rowMap.get("REGISTRATION_IDS");
                String data = (String) rowMap.get("DATA");
                if (rowMap.get("REGISTRATION_IDS") == null || (registration_ids = registration_ids.trim()).length() == 0 || data == null || data.length() == 0) {
                    continue;
                }
                Map<String, Object> gcmData = new HashMap<>();
                boolean multiple = Pattern.compile(".*\\s.*").matcher(registration_ids).matches();
                if (multiple) {
                    gcmData.put("to", registration_ids);
                }
                else {
                    gcmData.put("registration_ids", Pattern.compile("\\s").split(registration_ids));
                }

                gcmData.put("collapse_key", rowMap.get("COLLAPSE_KEY") != null ? rowMap.get("COLLAPSE_KEY") : "1");
                gcmData.put("time_to_live", rowMap.get("TIME_TO_LIVE") != null ? rowMap.get("TIME_TO_LIVE") : 43200);
                gcmData.put("priority", rowMap.get("PRIORITY") != null ? rowMap.get("PRIORITY") : "high");
                gcmData.put("delay_while_idle", rowMap.get("DELAY_WHILE_IDLE"));
                gcmData.put("content_available", rowMap.get("CONTENT_AVAILABLE"));
                gcmData.put("data", _gson.fromJson(data, Map.class));

                // Create connection to send GCM Message request.
                URL url = new URL(GCM_SEND_URL);
                HttpURLConnection http = (HttpURLConnection) url.openConnection();
                http.setRequestProperty("Authorization", "key=" + _apiKey);
                http.setRequestProperty("Content-Type", "application/json");
                http.setRequestMethod("POST");
                http.setDoOutput(true);
                /*
                http.setRequestProperty("content", "charset=utf-8");
                http.setUseCaches(false);
                http.setDefaultUseCaches(false);
                http.setDoInput(true);
                */

                // Send GCM message content.
                OutputStream outputStream = http.getOutputStream();
                outputStream.write(_gson.toJson(gcmData).getBytes());

                // Read GCM response.
                Map<String, Object> responseMap = new HashMap<>();
                InputStream inputStream = http.getInputStream();

                responseMap.put("I_INT_SEQ_NO", rowMap.get("SEQ_NO"));
                responseMap.put("I_STR_RES_IP", request.getRemoteAddr());
                responseMap.put("I_STR_RES_CODE", String.valueOf(http.getResponseCode()));
                responseMap.put("I_STR_RES_MSG", http.getResponseMessage());

                String responseBody = IOUtils.toString(inputStream);
                conLog += String.format(", gcm-%d:%s", http.getResponseCode(), http.getResponseMessage());

                responseMap.put("I_STR_RES_BODY", responseBody);

                @SuppressWarnings("unchecked")
                HashMap<String, Object> bodyMap = (HashMap<String, Object>) _gson.fromJson(responseBody, Map.class);

                responseMap.put("I_STR_RES_MULTICAST_ID", String.valueOf(bodyMap.get("multicast_id")));
                responseMap.put("I_INT_RES_SUCCESS", (int) (double) bodyMap.get("success"));
                responseMap.put("I_INT_RES_FAILURE", (int) (double) bodyMap.get("failure"));
                responseMap.put("I_STR_RES_CANONICAL_IDS", String.valueOf(bodyMap.get("canonical_ids")));
                responseMap.put("I_STR_RES_RESULTS", _gson.toJson(bodyMap.get("results")));
                responseMap.put("I_STR_RES_MESSAGE_ID", String.valueOf(bodyMap.get("message_id")));
                responseMap.put("I_STR_RES_ERROR", bodyMap.get("error"));

                Map<String, Object> processResultMap = _pushDao.processSendMessage(responseMap);

                conLog += String.format(", process=%d", processResultMap.get("O_INT_RES_CODE"));
//                _logger.info(conLog);
                successCnt++;
            }
            catch (Exception e) {
                _logger.error("Exception | " + conLog, e);
                throw e;
            }
        }
        long endTime = System.currentTimeMillis();
        _logger.info(log + " cnt= {}, {}ms", new Object[] {
                cnt, (endTime - startTime)
        });
        resultMap.put("total", cnt);
        resultMap.put("success", successCnt);
        return _gson.toJson(resultMap);
    }

}