
package com.breakout.server.push;

import java.util.List;
import java.util.Map;

import org.apache.commons.lang.builder.ToStringBuilder;
import org.springframework.orm.ibatis.SqlMapClientTemplate;

/**
 * push dao
 * 
 * @author gue
 * @since 2016. 6. 16.
 * @copyright Copyright.2016.gue.All rights reserved.
 * @version 1.0
 * @history
 *          <ol>
 *          <li>변경자/날짜 : 변경사항</li>
 *          </ol>
 */
public class PushDAO {

    private SqlMapClientTemplate _sqlMapClientTemplate;

    public void setSqlMapClientTemplate(SqlMapClientTemplate sqlMapClientTemplate) throws Exception {
        this._sqlMapClientTemplate = sqlMapClientTemplate;
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> testPrc(Map<String, Object> requestMap) throws Exception {
        return _sqlMapClientTemplate.queryForList("push.testPrc", requestMap);
    }

    public Map<String, Object> testPrc2(Map<String, Object> requestMap) throws Exception {
        _sqlMapClientTemplate.queryForObject("push.testPrc", requestMap);
        return requestMap;
    }

    public Map<String, Object> readStandByMessage(Map<String, Object> requestMap) throws Exception {
        _sqlMapClientTemplate.queryForObject("push.readStandByMessage", requestMap);
        return requestMap;
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> readPrepareMessage(Map<String, Object> requestMap) throws Exception {
        List<Map<String, Object>> resultMap = _sqlMapClientTemplate.queryForList("push.readPrepareMessage", requestMap);
        return resultMap;
    }

    public Map<String, Object> processSendMessage(Map<String, Object> requestMap) throws Exception {
        _sqlMapClientTemplate.queryForObject("push.processSendMessage", requestMap);
        return requestMap;
    }

    /*
    public List<PnsMsgVO> readPnsSendMsgList() throws Exception {
        return (List<PnsMsgVO>) _sqlMapClientTemplate.queryForList("readPnsSendMsgList");
    }
    
    public List<PnsObjectVO> readPnsSendObjectList(PnsObjectCondVO pnsObjectCondVO) throws Exception {
        return (List<PnsObjectVO>) _sqlMapClientTemplate.queryForList("readPnsSendObjectList", pnsObjectCondVO);
    }
    
    public Map<String, Object> insertAdExecLog(Map<String, Object> map) throws Exception {
        _sqlMapClientTemplate.queryForObject("insertAdExeclog", map);
        return map;
    }
    
    public Map<String, Object> deleteRegKey(Map<String, Object> map) throws Exception {
        _sqlMapClientTemplate.queryForObject("deleteRegKey", map);
        return map;
    }
    public int readPnsSeq() throws Exception {
        return ((Integer) _sqlMapClientTemplate.queryForObject("readPnsSeq")).intValue();
    }
    */

    public String toString() {
        return new ToStringBuilder(this).toString();
    }
}