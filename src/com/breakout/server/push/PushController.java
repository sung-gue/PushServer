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
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.context.ServletContextAware;

import com.google.gson.Gson;

/**
 * push controller
 * 
 * @author gue
 * @since 2016. 6. 13.
 * @copyright Copyright.2016.gue.All rights reserved.
 * @version 1.0
 * @history
 *          <ol>
 *          <li>변경자/날짜 : 변경사항</li>
 *          </ol>
 */
@Controller
public class PushController implements ServletContextAware {
    private Logger _logger = LoggerFactory.getLogger(PushController.class);
    private Gson _gson;
    private PushService _pushService;
    private PushDAO _pushDao;

    /**
     * @param gson the {@link #_gson} to set
     */
    public void setGson(Gson gson) {
        this._gson = gson;
    }

    /**
     * @param pushService the {@link #_pushService} to set
     */
    public void setPushService(PushService pushService) {
        this._pushService = pushService;
    }

    /**
     * @param _pushDao the {@link #_pushDao} to set
     */
    public void setPushDao(PushDAO pushDao) {
        this._pushDao = pushDao;
    }

    @Autowired
    private ServletContext servletContext;

    /* (non-Javadoc)
     * @see org.springframework.web.context.ServletContextAware#setServletContext(javax.servlet.ServletContext)
     */
    @Override
    public void setServletContext(ServletContext servletContext) {
        this.servletContext = servletContext;
    }

    public synchronized void init(HttpServletRequest request) throws Exception {
        if (null == null) {
            String path = servletContext.getRealPath("/WEB-INF/hannanum_dic");

            _logger.info("[{}-{}({}:init)] complete", new Object[] {
                    request.getRemoteAddr(), request.getRequestURI(), request.getMethod()
            });
        }
    }

    @RequestMapping("/sendMsg")
    public @ResponseBody String sendMsg(@RequestParam(value = "sendKey", required = true, defaultValue = "") String sendKey, HttpServletRequest request, HttpServletResponse response,
            HttpSession session) throws Exception {
        long startTime = System.currentTimeMillis();

        Map<String, Object> requestMap = new HashMap<>();
        requestMap.put("SEND_KEY", sendKey);

        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("code", "00000");
        responseMap.put("msg", "success");

        if (sendKey != null && sendKey.length() > 0) {
            responseMap.put("result", _pushService.sendMsg(requestMap, request));
        }
        else {
            responseMap.put("code", "10001");
            responseMap.put("msg", "sendKey is null");
        }

        String resJson = _gson.toJson(responseMap);

        _logger.info("[{}-{}({}:{}ms)] req= {}, res= {}", new Object[] {
                request.getRemoteAddr(), request.getRequestURI(), request.getMethod(), (System.currentTimeMillis() - startTime), _gson.toJson(requestMap), resJson
        });

        return resJson;
    }

    @RequestMapping("/sendMsgTest")
    public @ResponseBody String sendMsgTest(@RequestParam(value = "sendKey", required = true, defaultValue = "") String sendKey, HttpServletRequest request, HttpServletResponse response,
            HttpSession session) throws Exception {
        Map<String, Object> requestMap = new HashMap<>();
        requestMap.put("SEND_KEY", sendKey);
        String GCM_SEND_URL = "https://gcm-http.googleapis.com/gcm/send";

        long startTime = System.currentTimeMillis();
//      _logger.info("[{}] PushService batch start", startTime);

        String log = "startTime= " + startTime + ", requestMap= " + requestMap;
        int cnt = 0;
        List<Map<String, Object>> resultList = _pushDao.readPrepareMessage(requestMap);
        for (Map<String, Object> rowMap : resultList) {
            cnt++;
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
//          gcmData.put("delay_while_idle", (int) rowMap.get("DELAY_WHILE_IDLE") == 1 ? true : false);
//          gcmData.put("content_available", (int) rowMap.get("CONTENT_AVAILABLE") == 1 ? true : false);
            gcmData.put("delay_while_idle", rowMap.get("DELAY_WHILE_IDLE"));
            gcmData.put("content_available", rowMap.get("CONTENT_AVAILABLE"));
            gcmData.put("data", _gson.fromJson(data, Map.class));

        }
        System.out.println(log + ", cnt= " + cnt + ", " + (System.currentTimeMillis() - startTime) + "ms");
        return log;
    }

}