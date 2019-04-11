package com.breakout.server.push;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.ProtocolException;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

import javax.servlet.ServletContext;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.ServletContextAware;

import com.google.gson.Gson;

/**
 * push schedular
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
public class PushScheduler implements ServletContextAware {
    private Logger _logger = LoggerFactory.getLogger(PushScheduler.class);
    @Autowired
    private ServletContext servletContext;
    private Gson _gson;
    private PushDAO _pushDao;
    private int _readCount;
    private String _pushUrl;

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
     * @param _readCount the {@link #_readCount} to set
     */
    public void setReadCount(int readCount) {
        this._readCount = readCount;
    }

    /**
     * @param pushUrl the {@link #_pushUrl} to set
     */
    public void setPushUrl(String pushUrl) {
        this._pushUrl = pushUrl;
    }

    /**
     * pns scheduler
     * 
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
    public synchronized void work() throws Exception {
        long startTime = System.currentTimeMillis();

        Map<String, Object> requestMap = new HashMap<>();
        requestMap.put("I_INT_PAGE_COUNT", _readCount);
        String log = "";
        int cnt = 0;
        String keys = null;

        Map<String, Object> resultMap = _pushDao.readStandByMessage(requestMap);
        if (resultMap.containsKey("O_STR_SEND_KEY") && (keys = (String) resultMap.get("O_STR_SEND_KEY")) != null && (keys = keys.trim()).length() > 0) {
            String[] sendKeys = Pattern.compile(" ").split(keys);
            for (String sendKey : sendKeys) {
                workThread(startTime, sendKey);
                cnt++;
            }
        }

        if (cnt > 0) {
            log += String.format("%d keys(%s)", cnt, keys);
            long endTime = System.currentTimeMillis();
            _logger.info("[{}] work end, {}ms | {}", new Object[] {
                    startTime, endTime - startTime, log
            });
        }
    }
    
    //@Async
    private void workThread(final long startTime, final String sendKey) throws Exception {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    String log = String.format("[%d] sendKey=%s", startTime, sendKey);

                    URL url = new URL(_pushUrl);
                    HttpURLConnection http = (HttpURLConnection) url.openConnection();
                    http.setUseCaches(false);
                    http.setDefaultUseCaches(false);
                    http.setDoInput(true);
                    http.setDoOutput(true);
                    http.setRequestMethod("POST");
                    http.setRequestProperty("content", "charset=utf-8");

                    StringBuffer buffer = new StringBuffer();
                    buffer.append("sendKey=").append(sendKey);

                    OutputStreamWriter outStream = new OutputStreamWriter(http.getOutputStream(), "UTF-8");
//                    log += ", encoding= " + outStream.getEncoding();

                    PrintWriter writer = new PrintWriter(outStream);
                    writer.write(buffer.toString());
                    writer.flush();
                    writer.close();

                    log += String.format(", (%d-%s)", http.getResponseCode(), http.getResponseMessage());

                    BufferedReader reader = new BufferedReader(new InputStreamReader(http.getInputStream(), "UTF-8"));
                    StringBuilder builder = new StringBuilder();
                    String str;
                    while ((str = reader.readLine()) != null) {
                        builder.append(str);
                    }

                    log += String.format(" res=%s", builder.toString());
                    _logger.info(log);
                }
                catch (MalformedURLException e) {
                    _logger.error("MalformedURLException", e);
                }
                catch (ProtocolException e) {
                    _logger.error("ProtocolException", e);
                }
                catch (UnsupportedEncodingException e) {
                    _logger.error("UnsupportedEncodingException", e);
                }
                catch (IOException e) {
                    _logger.error("IOException", e);
                }
                catch (Exception e) {
                    _logger.error("Exception", e);
                }
            }
        }).start();
    }

}