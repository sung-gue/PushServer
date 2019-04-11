package com.breakout.server.push;

import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
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
import com.google.gson.annotations.SerializedName;


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
    private static final String FCM_SEND_URL = "https://fcm.googleapis.com/fcm/send";
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
     * @param gson
     *            the {@link #_gson} to set
     */
    public void setGson(Gson gson) {
        this._gson = gson;
    }

    /**
     * @param _pushDao
     *            the {@link #_pushDao} to set
     */
    public void setPushDao(PushDAO pushDao) {
        this._pushDao = pushDao;
    }

    /**
     * @param apiKey
     *            the {@link #_apiKey} to set
     */
    public void setApiKey(String apiKey) {
        this._apiKey = apiKey;
    }

    /**
     * send push service
     * 
     * @param requestMap
     *            SEND_KEY,...
     * @param request
     * @throws Exception
     * @author gue
     * @since 2016. 6. 10.
     * @history
     *          <ol>
     *          <li>변경자/날짜 : 변경사항</li>
     *          </ol>
     */
    @Transactional(propagation = Propagation.REQUIRED, rollbackFor = { Exception.class })
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
                // 1: android, 2:ios, 3:web
                int channel = (int) rowMap.get("CHANNEL");
                String apiServerKey = (String) rowMap.get("API_SERVER_KEY");
                apiServerKey = (apiServerKey != null ? apiServerKey : _apiKey);
                // 1:단일디바이스(to), 2:주제(to), 3:조건주제(condition), 4:다수디바이스(registration_ids)
                int targetType = (int) rowMap.get("TARGET_TYPE");
                String targetKey = (String) rowMap.get("TARGET_KEY");
                String sendTarget = (String) rowMap.get("SEND_TARGET");
                String data = (String) rowMap.get("DATA");

                Map<String, Object> gcmData = new HashMap<>();

                if (targetType == 4) {
                    if (sendTarget == null || sendTarget.trim().length() == 0 || data == null || data.length() == 0) {
                        continue;
                    }
                    gcmData.put(targetKey, Pattern.compile("\\s").split(sendTarget));
                } else {
                    gcmData.put(targetKey, sendTarget);
                }

                gcmData.put("collapse_key", rowMap.get("COLLAPSE_KEY") != null ? rowMap.get("COLLAPSE_KEY") : "1");
                gcmData.put("time_to_live", rowMap.get("TIME_TO_LIVE") != null ? rowMap.get("TIME_TO_LIVE") : 43200);
                gcmData.put("priority", rowMap.get("PRIORITY") != null ? rowMap.get("PRIORITY") : "high");
                gcmData.put("delay_while_idle", rowMap.get("DELAY_WHILE_IDLE"));
                gcmData.put("content_available", rowMap.get("CONTENT_AVAILABLE"));
                gcmData.put("data", _gson.fromJson(data, Map.class));
                if (channel == 2) {
                    gcmData.put("notification", _gson.fromJson(data, Map.class));
                }

                // Create connection to send GCM Message request.
                URL url = new URL(FCM_SEND_URL);
                HttpURLConnection http = (HttpURLConnection) url.openConnection();
                http.setDoOutput(true);

                // Http request header
                http.setRequestProperty("Content-Type", "application/json");
                http.setRequestProperty("Authorization", "key=" + apiServerKey);
                http.setRequestMethod("POST");
                /*
                 * http.setRequestProperty("content", "charset=utf-8"); http.setUseCaches(false); http.setDefaultUseCaches(false); http.setDoInput(true);
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
                
                
                try {
                    FcmResponse fcmResponse = new Gson().fromJson(responseBody, FcmResponse.class);
                    responseMap.put("I_STR_RES_MULTICAST_ID", String.valueOf(fcmResponse.multicast_id));
                    responseMap.put("I_INT_RES_SUCCESS", fcmResponse.success);
                    responseMap.put("I_INT_RES_FAILURE", fcmResponse.failure);
                    responseMap.put("I_INT_RES_CANONICAL_IDS", fcmResponse.canonical_ids);
                    responseMap.put("I_STR_RES_RESULTS", _gson.toJson(fcmResponse.results));
                    responseMap.put("I_STR_RES_MESSAGE_ID", String.valueOf(fcmResponse.message_id));
                    responseMap.put("I_STR_RES_ERROR", fcmResponse.error);
                } catch (Exception e) {
                    _logger.warn("Warn | " + conLog + " | " + e.getMessage(), e);
                    @SuppressWarnings("unchecked")
                    HashMap<String, Object> bodyMap = (HashMap<String, Object>) _gson.fromJson(responseBody, Map.class);
                    responseMap.put("I_STR_RES_MULTICAST_ID", String.valueOf(bodyMap.get("multicast_id")));
                    if (bodyMap.get("success") != null) {
                        responseMap.put("I_INT_RES_SUCCESS", (long) (double) bodyMap.get("success"));
                    }
                    else {
                        responseMap.put("I_INT_RES_SUCCESS", null);
                    }
                    if (bodyMap.get("failure") != null) {
                        responseMap.put("I_INT_RES_FAILURE", (long) (double) bodyMap.get("failure"));
                    }
                    else {
                        responseMap.put("I_INT_RES_FAILURE", null);
                    }
                    if (bodyMap.get("canonical_ids") != null) {
                        responseMap.put("I_INT_RES_CANONICAL_IDS", (long) (double) bodyMap.get("canonical_ids"));
                    }
                    else {
                        responseMap.put("I_INT_RES_CANONICAL_IDS", null);
                    }
                    responseMap.put("I_STR_RES_RESULTS", _gson.toJson(bodyMap.get("results")));
                    responseMap.put("I_STR_RES_MESSAGE_ID", String.valueOf(bodyMap.get("message_id")));
                    responseMap.put("I_STR_RES_ERROR", bodyMap.get("error"));
                }

                Map<String, Object> processResultMap = _pushDao.processSendMessage(responseMap);

                conLog += String.format(", process=%d", processResultMap.get("O_INT_RES_CODE"));
                // _logger.info(conLog);
                successCnt++;
            } catch (Exception e) {
                _logger.error("Exception | " + conLog, e);
                // throw e;
            }
        }
        long endTime = System.currentTimeMillis();
        _logger.info(log + " cnt= {}, {}ms", new Object[] { cnt, (endTime - startTime) });
        resultMap.put("total", cnt);
        resultMap.put("success", successCnt);
        return _gson.toJson(resultMap);
    }

    /**
     * Firebase 응답 본문
     * 
     * @author gue
     * @since 2017. 1. 17.
     * @copyright Copyright.2012.gue.All rights reserved.
     * @version 1.0
     * @history
     *          <ol>
     *          <li>변경자/날짜 : 변경사항</li>
     *          </ol>
     */
    public class FcmResponse {
        /**
         * 필수항목, 숫자 - 멀티캐스트 메시지를 식별하는 숫자로 된 고유 ID입니다.
         */
        @SerializedName("multicast_id")
        public Long multicast_id;
        /**
         * 필수항목, 숫자 - 오류 없이 처리된 메시지 수입니다.
         */
        @SerializedName("success")
        public Long success;
        /**
         * 필수항목, 숫자 - 처리하지 못한 메시지 수입니다.
         */
        @SerializedName("failure")
        public Long failure;
        /**
         * 필수항목, 숫자 - 정식 등록 토큰이 포함된 결과 수입니다.
         */
        @SerializedName("canonical_ids")
        public Long canonical_ids;
        /**
         * 선택사항, 배열 개체 - 처리된 메시지의 상태를 나타내는 개체의 배열입니다. 개체는 요청과 동일한 순서로 표시됩니다. 즉, 요청의 각 등록 ID마다 응답의 동일한 색인에 표시됩니다.
         */
        @SerializedName("results")
        public ArrayList<FcmResponseResult> results;
        /**
         * 선택사항, 숫자 - FCM이 성공적으로 요청을 수신한 경우 모든 구독 기기로 전송을 시도하는 주제 메시지 ID입니다.
         */
        @SerializedName("message_id")
        public Long message_id;
        /**
         * 선택사항, 문자열 - 메시지를 처리할 때 발생한 오류입니다.
         */
        @SerializedName("error")
        public String error;

        public FcmResponse() {
        }

    }

    /**
     * 처리된 메시지의 상태를 나타내는 개체의 배열입니다. 개체는 요청과 동일한 순서로 표시됩니다. 즉, 요청의 각 등록 ID마다 응답의 동일한 색인에 표시됩니다.
     * 
     * @author gue
     * @since 2017. 1. 17.
     * @copyright Copyright.2012.gue.All rights reserved.
     * @version 1.0
     * @history
     *          <ol>
     *          <li>변경자/날짜 : 변경사항</li>
     *          </ol>
     */
    public class FcmResponseResult {
        /**
         * message_id: 성공적으로 처리된 각 메시지의 고유 ID를 지정하는 문자열입니다.
         */
        @SerializedName("message_id")
        public String message_id;
        /**
         * registration_id: 메시지가 처리되어 전송된 클라이언트 앱의 정식 등록 토큰을 지정하는 선택적인 문자열입니다. 발신자는 이후 요청에서 이 값을 등록 토큰으로 사용해야 합니다. 그렇지 않으면 메시지가 거부될 수 있습니다.
         */
        @SerializedName("registration_id")
        public String registration_id;
        /**
         * error: 수신자의 메시지를 처리할 때 발생한 오류를 지정하는 문자열입니다. 가능한 값은 표 9에서 확인할 수 있습니다.
         */
        @SerializedName("error")
        public String error;

        public FcmResponseResult() {
        }
    }
    
    /**
     * 알림페이로드
     * @author gue
     * @since 2017. 1. 19.
     * @copyright Copyright.2012.gue.All rights reserved.
     * @version 1.0
     * @history <ol>
     * 		<li>변경자/날짜 : 변경사항</li>
     * </ol>
     */
    public class FcmPayloadNotification {
        /**
         * title: 선택사항, 문자열 - 알림 제목을 나타냅니다. 이 필드는 iOS 휴대전화(iPhone)와 태블릿(iPad)에는 표시되지 않습니다.
         */
        @SerializedName("title")
        public String title;
        /**
         * body: 선택사항, 문자열 - 알림 본문 텍스트를 나타냅니다.
         */
        @SerializedName("body")
        public String body;
        public FcmPayloadNotification(){
        }
    }

}