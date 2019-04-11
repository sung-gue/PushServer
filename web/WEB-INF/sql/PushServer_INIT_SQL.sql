/*
 * MySQL database 로 작성된 table, procedure, function
 *
 * Author : breakout.tistory.com (sunggue@gmail.com)
 * History : 2016-06-10, Just Created
 */


-- 데이터베이스 생성
-- DROP DATABASE IF EXISTS FCM_DB;
CREATE DATABASE IF NOT EXISTS FCM_DB;
USE FCM_DB;

-- FCM 메시지 대상 정의
-- https://firebase.google.com/docs/cloud-messaging/http-server-ref
DROP TABLE IF EXISTS FCM_DB.FCM_TARGET_TYPE;
CREATE TABLE FCM_DB.FCM_TARGET_TYPE (
    ID                        BIGINT(20)        NOT NULL      AUTO_INCREMENT                              COMMENT 'ID'
  , TARGET_KEY                VARCHAR(100)      NOT NULL                                                  COMMENT '전송 대상 종류 - 1:단일디바이스(to), 2:주제(to), 3:조건주제(condition), 4:다수디바이스(registration_ids)'
  , INFO                      TEXT              NOT NULL                                                  COMMENT 'TYPE 설명'
  , STATUS                    TINYINT(1)        NOT NULL      DEFAULT 1                                   COMMENT '상태 - 1:사용, 2:중지'
  , REG_TM                    TIMESTAMP         NOT NULL      DEFAULT CURRENT_TIMESTAMP                   COMMENT '등록 시각'
  , PRIMARY KEY (ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='FCM 메시지 대상 정의'
;
-- 전송 대상 종류 삽입 - 1:단일디바이스(to), 2:주제(to), 3:조건주제(condition), 4:다수디바이스(registration_ids)
INSERT INTO FCM_DB.FCM_TARGET_TYPE (ID  ,STATUS ,TARGET_KEY ,INFO) 
  VALUES 
    (1  ,1  ,'to'                     ,'단일 기기 전송일 때 key값이며 값은 클라이언트 fcm 등록 토큰 사용' )
  , (2  ,1  ,'to'                     ,'단일 주제 전송일 때 key값이며 값은 주제이름 사용 ex) 주제이름이 event 일 때 값은 /topics/event' )
  , (3  ,1  ,'condition'              ,'다수 주제의 조건 전송일 때 key값이며 &&, || 연산자 사용 가능 ex) (TopicA 및 TopicB)와 (TopicA 및 TopicC)를 구독한 사용자 ''TopicA'' in topics && (''TopicB'' in topics || ''TopicC'' in topics)' )
  , (4  ,1  ,'registration_ids'       ,'다수 기기 전송일 때 key값이며 값은 클라이언트 fcm 등록 토큰 배열 사용, 2~1000개 ex) ["token" ,"token" ,... ]' )
  , (5  ,2  ,'notification_key'       ,'그룹 전송일 때 key값,  2016-01-06 이후 공식 문서에서 현재는 사용중지 됨' )
;




-- FCM MESSAGE STAND BY TABLE
DROP TABLE IF EXISTS FCM_DB.FCM_STANDBY;
CREATE TABLE FCM_DB.FCM_STANDBY (
    SEQ_NO                    BIGINT(20)        NOT NULL      AUTO_INCREMENT                              COMMENT 'seq no'
  , SEND_KEY                  VARCHAR(100)                    DEFAULT NULL                                COMMENT '전송 키'
  , REQ_SEQ_NO                BIGINT(20)                      DEFAULT NULL                                COMMENT '요청 내역과 대응하는 일련번호'
  , RESERVATION_DT            DATETIME          NOT NULL                                                  COMMENT '예약 노출 시작 일시'
  , CHANNEL                   TINYINT(4)        NOT NULL      DEFAULT 1                                   COMMENT '1: android, 2:ios, 3:web'
  , API_SERVER_KEY            VARCHAR(255)      NOT NULL                                                  COMMENT 'FCM SERVER KEY'
  , TARGET_TYPE               TINYINT(4)        NOT NULL      DEFAULT 1                                   COMMENT '전송 대상 종류 FCM_TARGET_TYPE.ID - 1:단일디바이스(to), 2:주제(to), 3:조건주제(condition), 4:다수디바이스(registration_ids)'
  , SEND_TARGET               TEXT              NOT NULL                                                  COMMENT '전송 대상 - 1:단일디바이스(to:token), 2:주제(to:/topics/topic), 3:조건주제(condition:''topic'' in topics), 4:다수디바이스_최대1000개_구분자공백(registration_ids:["token","token",...])'
  , DATA                      TEXT              NOT NULL                                                  COMMENT '[FCM request param] data : json string'
  , COLLAPSE_KEY              VARCHAR(255)      NOT NULL      DEFAULT '1'                                 COMMENT '[FCM request param] collapse_key : group of message, 축소형메시지 설정하여 같은 키를 사용하는 마지막 메시지만 클라이언트에 전달됨'
  , TIME_TO_LIVE              INT               NOT NULL      DEFAULT 43200                               COMMENT '[FCM request param] time_to_live 2419200sec(0~2419200sec,): collapse_key와 함께 사용, device가 off 되었을 경우 fcm storage에 메시지가 보존되는 시간'
  , DELAY_WHILE_IDLE          TINYINT(1)        NOT NULL      DEFAULT FALSE                               COMMENT '[FCM request param] delay_while_idle (true, false) : false일 경우 device가 idle 상태여도 메시지 전달'
  , PRIORITY                  VARCHAR(10)       NOT NULL      DEFAULT 'high'                              COMMENT '[FCM request param] priority (normal, high) : client가 절전 모드이고 값이 normal이면 메시지 전달을 즉시 하지 않음, high이면 android의 경우 doze(대기) 모드도 해제되며 메시지 즉시 전달 '
  , CONTENT_AVAILABLE         TINYINT(1)        NOT NULL      DEFAULT TRUE                                COMMENT '[FCM request param] content_available (true, false) : iOS에 적용되는 값이며 true일 경우 비활성상태의 앱을 깨운다.'
  , REG_TM                    TIMESTAMP         NOT NULL      DEFAULT CURRENT_TIMESTAMP                   COMMENT '등록 시각'
  , REG_IP                    VARCHAR(100)      NOT NULL                                                  COMMENT '등록 IP'
  , PRIMARY KEY (SEQ_NO)
  , KEY IDX_FCM_STANDBY (SEND_KEY)
  , KEY IDX_FCM_STANDBY_01 (RESERVATION_DT)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='fcm message 대기 테이블'
;




-- FCM MESSAGE SEND FINISH TABLE
DROP TABLE IF EXISTS FCM_DB.FCM_FINISH;
CREATE TABLE FCM_DB.FCM_FINISH (
    SEQ_NO                    BIGINT(20)        NOT NULL      AUTO_INCREMENT                              COMMENT 'seq no'
  , SEND_KEY                  VARCHAR(100)                    DEFAULT NULL                                COMMENT '전송 키'
  , REQ_SEQ_NO                BIGINT(20)                      DEFAULT NULL                                COMMENT '요청 내역과 대응하는 일련번호'
  , RESERVATION_DT            DATETIME          NOT NULL                                                  COMMENT '예약 노출 시작 일시'
  , CHANNEL                   TINYINT(4)        NOT NULL      DEFAULT 1                                   COMMENT '1: android, 2:ios, 3:web'
  , API_SERVER_KEY            VARCHAR(255)      NOT NULL                                                  COMMENT 'FCM SERVER KEY'
  , TARGET_TYPE               TINYINT(4)        NOT NULL      DEFAULT 1                                   COMMENT '전송 대상 종류 FCM_TARGET_TYPE.ID - 1:단일디바이스(to), 2:주제(to), 3:조건주제(condition), 4:다수디바이스(registration_ids)'
  , SEND_TARGET               TEXT              NOT NULL                                                  COMMENT '전송 대상 - 1:단일디바이스(to:token), 2:주제(to:/topics/topic), 3:조건주제(condition:''topic'' in topics), 4:다수디바이스_최대1000개_구분자공백(registration_ids:["token","token",...])'
  , DATA                      TEXT              NOT NULL                                                  COMMENT '[FCM request param] data : json string'
  , COLLAPSE_KEY              VARCHAR(255)      NOT NULL      DEFAULT '1'                                 COMMENT '[FCM request param] collapse_key : group of message, 축소형메시지 설정하여 같은 키를 사용하는 마지막 메시지만 클라이언트에 전달됨'
  , TIME_TO_LIVE              INT               NOT NULL      DEFAULT 43200                               COMMENT '[FCM request param] time_to_live 2419200sec(0~2419200sec,): collapse_key와 함께 사용, device가 off 되었을 경우 fcm storage에 메시지가 보존되는 시간'
  , DELAY_WHILE_IDLE          TINYINT(1)        NOT NULL      DEFAULT FALSE                               COMMENT '[FCM request param] delay_while_idle (true, false) : false일 경우 device가 idle 상태여도 메시지 전달'
  , PRIORITY                  VARCHAR(10)       NOT NULL      DEFAULT 'high'                              COMMENT '[FCM request param] priority (normal, high) : client가 절전 모드이고 값이 normal이면 메시지 전달을 즉시 하지 않음, high이면 android의 경우 doze(대기) 모드도 해제되며 메시지 즉시 전달 '
  , CONTENT_AVAILABLE         TINYINT(1)        NOT NULL      DEFAULT TRUE                                COMMENT '[FCM request param] content_available (true, false) : iOS적용되는 값이며 true일 경우 비활성상태의 앱을 깨운다.'
  , REG_TM                    TIMESTAMP         NOT NULL                                                  COMMENT '등록 시각'
  , REG_IP                    VARCHAR(100)      NOT NULL                                                  COMMENT '등록 IP'
  , RES_TM                    TIMESTAMP         NULL          DEFAULT CURRENT_TIMESTAMP                   COMMENT '응답 시각'
  , RES_IP                    VARCHAR(100)      NOT NULL                                                  COMMENT '응답 IP'
  , RES_CODE                  VARCHAR(10)                     DEFAULT NULL                                COMMENT 'response code : 200, 400, 401, 5xx'
  , RES_MSG                   TEXT                            DEFAULT NULL                                COMMENT 'response message'
  , RES_BODY                  TEXT                            DEFAULT NULL                                COMMENT 'response body'
  , RES_MULTICAST_ID          VARCHAR(255)                    DEFAULT NULL                                COMMENT '[response body] 필수항목, 숫자 - 멀티캐스트 메시지를 식별하는 숫자로 된 고유 ID입니다.'
  , RES_SUCCESS               INT                             DEFAULT NULL                                COMMENT '[response body] 필수항목, 숫자 - 오류 없이 처리된 메시지 수입니다.'
  , RES_FAILURE               INT                             DEFAULT NULL                                COMMENT '[response body] 필수항목, 숫자 - 처리하지 못한 메시지 수입니다.'
  , RES_CANONICAL_IDS         INT                             DEFAULT NULL                                COMMENT '[response body] 필수항목, 숫자 - 정식 등록 토큰이 포함된 결과 수입니다.'
  , RES_RESULTS               TEXT                            DEFAULT NULL                                COMMENT '[response body] 선택사항, 배열 개체 - 처리된 메시지의 상태를 나타내는 개체의 배열입니다. 개체는 요청과 동일한 순서로 표시됩니다. 즉, 요청의 각 등록 ID마다 응답의 동일한 색인에 표시됩니다.'
  , RES_MESSAGE_ID            VARCHAR(255)                    DEFAULT NULL                                COMMENT '[response body] TOPIC : 선택사항, 숫자 - FCM이 성공적으로 요청을 수신한 경우 모든 구독 기기로 전송을 시도하는 주제 메시지 ID입니다.'
  , RES_ERROR                 VARCHAR(255)                    DEFAULT NULL                                COMMENT '[response body] TOPIC : 선택사항, 문자열 - 메시지를 처리할 때 발생한 오류입니다.'
  , PRIMARY KEY (SEQ_NO)
  , KEY IDX_FCM_FINISH (SEND_KEY)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='fcm message 발송완료 테이블'
;




DROP PROCEDURE IF EXISTS FCM_DB.FCM_PREPARE_TX_PRC;
DELIMITER $$
CREATE PROCEDURE FCM_DB.FCM_PREPARE_TX_PRC (
    IN  I_INT_PAGE_COUNT          INT                 -- 전송 설정을 할 수량 (default: 1000)
  , OUT O_STR_SEND_KEY            TEXT                -- 전송 키, 다수일 경우 공백을 구분자로 구성하여 전달
  , OUT O_INT_RES_CODE            INT                 -- 처리 결과 코드
  , OUT O_STR_RES_MSG             TEXT                -- 처리 결과 메시지
) 
    COMMENT 'fcm 메시지를 전송 가능 상태로 변경한다.'
  /***************************************************************
  Description     : fcm 메시지를 전송 가능 상태로 변경한다.
  Response        : O_INT_RES_CODE    O_STR_RES_MSG
                    0                 처리가 성공하였습니다.
                    10001             처리를 실패하였습니다. (S:V_STR_PROC_STEP)
                    10101             
                    10102             
                    10103             
                    99998             SQLEXCEPTION
  Author          : sunggue@gmail.com
  History         : 2016-06-13, Just Created
  ***************************************************************/
MAIN_BLOCK : BEGIN
    
    -- SQLEXCEPTION
    DECLARE V_STR_SQL_STATE             CHAR(5)           DEFAULT '00000';
    DECLARE V_STR_SQL_ERR_NO            CHAR(5)           DEFAULT '00000';
    DECLARE V_STR_SQL_MESSAGE           TEXT              DEFAULT '';
    
    -- STEP
    DECLARE V_STR_PROC_STEP             VARCHAR(20)       DEFAULT '00.00';
    DECLARE V_STR_TYPE                  VARCHAR(100)      DEFAULT '';
    
    -- COMMON 
    DECLARE V_INT_ROW_CNT               INT               DEFAULT 0;
    DECLARE V_INT_NOT_FOUND             INT               DEFAULT FALSE;
    DECLARE V_STR_TEMP                  VARCHAR(255)      DEFAULT '';

    -- LOCAL VALUE
    DECLARE V_STR_SEND_KEY              VARCHAR(255)      DEFAULT '';

    DECLARE CONTINUE HANDLER FOR NOT FOUND 
      BEGIN 
        SET V_INT_NOT_FOUND = TRUE;
      END
    ;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
      BEGIN
          GET DIAGNOSTICS CONDITION 1
          V_STR_SQL_STATE = RETURNED_SQLSTATE, V_STR_SQL_ERR_NO = MYSQL_ERRNO, V_STR_SQL_MESSAGE = MESSAGE_TEXT;
          SET O_INT_RES_CODE = 99998;
          SET O_STR_RES_MSG = CONCAT(V_STR_TYPE, ' 처리를 실패하였습니다. 상황이 지속되면 다음의 내용을 전달 바랍니다. (S:', V_STR_PROC_STEP, ')');
          SET O_STR_RES_MSG = CONCAT(O_STR_RES_MSG, ' ERROR:SQLEXCEPTION ( MYSQL_ERRNO = [', V_STR_SQL_ERR_NO ,'], sql_state = [', V_STR_SQL_STATE, '], msg = [', V_STR_SQL_MESSAGE, ']');
          ROLLBACK;
      END
    ;
    
    -- IBATIS에서 MYSQL PROCEDURE 호출시에 SELECT 구문이 없으면 PROCEDURE를 호출한 부분에서 응답없음이 걸린다....
    SELECT 1;
    
    
    -- init out parameter
    SET O_STR_SEND_KEY = '';
    SET O_INT_RES_CODE = 0;
    SET O_STR_RES_MSG = '';
    
    
    -- parameter check
    IF I_INT_PAGE_COUNT IS NULL OR I_INT_PAGE_COUNT = '' THEN 
      SET I_INT_PAGE_COUNT = 1000;
    END IF;


    START TRANSACTION;


    SET V_STR_PROC_STEP = '01.01';
    SET V_STR_TYPE = '전송 키 설정';

    LOOP_SET_SEND_KEY : LOOP
      -- 10자리의 랜덤 문자열과 microsecond로 이루어진 날짜(20자)로 구성
      SET V_STR_SEND_KEY = CONCAT(
          CHAR(CAST(RAND()*25+65 AS UNSIGNED))
        , CHAR(CAST(RAND()*25+65 AS UNSIGNED))
        , CHAR(CAST(RAND()*25+65 AS UNSIGNED))
        , CHAR(CAST(RAND()*25+65 AS UNSIGNED))
        , CHAR(CAST(RAND()*25+65 AS UNSIGNED))
        , CHAR(CAST(RAND()*25+65 AS UNSIGNED))
        , CHAR(CAST(RAND()*25+65 AS UNSIGNED))
        , CHAR(CAST(RAND()*25+65 AS UNSIGNED))
        , CHAR(CAST(RAND()*25+65 AS UNSIGNED))
        , CHAR(CAST(RAND()*25+65 AS UNSIGNED))
        , DATE_FORMAT(NOW(6),'%Y%m%d%H%i%s%f') -- UNIX_TIMESTAMP()
      );

      UPDATE FCM_DB.FCM_STANDBY
      SET SEND_KEY = V_STR_SEND_KEY
      WHERE SEND_KEY IS NULL
        AND RESERVATION_DT < NOW()
      ORDER BY SEQ_NO ASC
      LIMIT I_INT_PAGE_COUNT
      ;

      SET V_INT_ROW_CNT = ROW_COUNT();

      IF V_INT_ROW_CNT > 0 AND O_STR_SEND_KEY = '' THEN
        SET O_STR_SEND_KEY = V_STR_SEND_KEY;
      ELSEIF V_INT_ROW_CNT > 0 AND V_INT_ROW_CNT <= I_INT_PAGE_COUNT THEN
        SET O_STR_SEND_KEY = CONCAT(O_STR_SEND_KEY, ' ', V_STR_SEND_KEY);
      END IF;

      IF V_INT_ROW_CNT < I_INT_PAGE_COUNT THEN
        LEAVE LOOP_SET_SEND_KEY;
      END IF;

    END LOOP LOOP_SET_SEND_KEY;
    
    
    SET V_STR_PROC_STEP = '02.01';
    SET V_STR_TYPE = '전송 키 설정 완료';
    
    
    IF O_INT_RES_CODE = 0 THEN 
      COMMIT;
      SET O_STR_RES_MSG = CONCAT('정상 처리 되었습니다.');
    ELSEIF O_INT_RES_CODE > 0 THEN 
      ROLLBACK;
      SET O_STR_RES_MSG = CONCAT('메시지 전송 설정에 실패하였습니다.. (S:', V_STR_PROC_STEP, ')');
    END IF;
    
END MAIN_BLOCK $$
DELIMITER ;




DROP PROCEDURE IF EXISTS FCM_DB.FCM_PROCESS_SEND_MSG_TX_PRC;
DELIMITER $$
CREATE PROCEDURE FCM_DB.FCM_PROCESS_SEND_MSG_TX_PRC (
    IN I_INT_SEQ_NO                 BIGINT(20)          -- [필수] FCM_STANDBY.SEQ_NO
  , IN I_STR_RES_IP                 VARCHAR(100)        -- [필수] 응답 IP
  , IN I_STR_RES_CODE               VARCHAR(10)         -- [필수] response code : 200, 400, 401, 5xx
  , IN I_STR_RES_MSG                TEXT                -- [필수] response message
  , IN I_STR_RES_BODY               TEXT                -- [필수] response body
  , IN I_STR_RES_MULTICAST_ID       VARCHAR(255)        -- [옵션] [response body] 필수항목, 숫자 - 멀티캐스트 메시지를 식별하는 숫자로 된 고유 ID입니다.
  , IN I_INT_RES_SUCCESS            INT                 -- [옵션] [response body] 필수항목, 숫자 - 오류 없이 처리된 메시지 수입니다.
  , IN I_INT_RES_FAILURE            INT                 -- [옵션] [response body] 필수항목, 숫자 - 처리하지 못한 메시지 수입니다.
  , IN I_INT_RES_CANONICAL_IDS      INT                 -- [옵션] [response body] 필수항목, 숫자 - 정식 등록 토큰이 포함된 결과 수입니다.
  , IN I_STR_RES_RESULTS            TEXT                -- [옵션] [response body] 선택사항, 배열 개체 - 처리된 메시지의 상태를 나타내는 개체의 배열입니다. 개체는 요청과 동일한 순서로 표시됩니다. 즉, 요청의 각 등록 ID마다 응답의 동일한 색인에 표시됩니다.
  , IN I_STR_RES_MESSAGE_ID         VARCHAR(255)        -- [옵션] [response body] TOPIC : 선택사항, 숫자 - FCM이 성공적으로 요청을 수신한 경우 모든 구독 기기로 전송을 시도하는 주제 메시지 ID입니다.
  , IN I_STR_RES_ERROR              VARCHAR(255)        -- [옵션] [response body] TOPIC : 선택사항, 문자열 - 메시지를 처리할 때 발생한 오류입니다.
  , OUT O_INT_RES_CODE              INT                 -- 처리 결과 코드
  , OUT O_STR_RES_MSG               TEXT                -- 처리 결과 메시지
) 
    COMMENT 'fcm 메시지 발송 처리'
  /***************************************************************
  Description     : fcm 메시지 발송 처리
  Response        : O_INT_RES_CODE    O_STR_RES_MSG
                    0                 처리가 성공하였습니다.
                    10001             필수값을 확인해주세요.
                    10101             
                    10102             
                    10103             
                    99998             SQLEXCEPTION
  Author          : sunggue@gmail.com
  History         : 2016-06-17, Just Created
  ***************************************************************/
MAIN_BLOCK : BEGIN
    
    -- SQLEXCEPTION
    DECLARE V_STR_SQL_STATE             CHAR(5)           DEFAULT '00000';
    DECLARE V_STR_SQL_ERR_NO            CHAR(5)           DEFAULT '00000';
    DECLARE V_STR_SQL_MESSAGE           TEXT              DEFAULT '';
    
    -- STEP
    DECLARE V_STR_PROC_STEP             VARCHAR(20)       DEFAULT '00.00';
    DECLARE V_STR_TYPE                  VARCHAR(100)      DEFAULT '';
    
    -- COMMON 
    DECLARE V_INT_ROW_CNT               INT               DEFAULT 0;
    DECLARE V_INT_NOT_FOUND             INT               DEFAULT FALSE;
    DECLARE V_STR_TEMP                  VARCHAR(255)      DEFAULT '';

    -- LOCAL VALUE
--     DECLARE V_STR_SEND_KEY              VARCHAR(255)      DEFAULT '';

    DECLARE CONTINUE HANDLER FOR NOT FOUND 
      BEGIN 
        SET V_INT_NOT_FOUND = TRUE;
      END
    ;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
      BEGIN
          GET DIAGNOSTICS CONDITION 1
          V_STR_SQL_STATE = RETURNED_SQLSTATE, V_STR_SQL_ERR_NO = MYSQL_ERRNO, V_STR_SQL_MESSAGE = MESSAGE_TEXT;
          SET O_INT_RES_CODE = 99998;
          SET O_STR_RES_MSG = CONCAT(V_STR_TYPE, ' 처리를 실패하였습니다. 상황이 지속되면 다음의 내용을 전달 바랍니다. (S:', V_STR_PROC_STEP, ')');
          SET O_STR_RES_MSG = CONCAT(O_STR_RES_MSG, ' ERROR:SQLEXCEPTION ( MYSQL_ERRNO = [', V_STR_SQL_ERR_NO ,'], sql_state = [', V_STR_SQL_STATE, '], msg = [', V_STR_SQL_MESSAGE, ']');
          ROLLBACK;
      END
    ;
    
    
    -- IBATIS에서 MYSQL PROCEDURE 호출시에 SELECT 구문이 없으면 PROCEDURE를 호출한 부분에서 응답없음이 걸린다....
    SELECT 1;
    
    
    -- init out parameter
    SET O_INT_RES_CODE = 0;
    SET O_STR_RES_MSG = '';
    
    
    -- parameter check
    IF I_STR_RES_CODE = '' OR I_STR_RES_MSG = '' THEN 
      SET O_INT_RES_CODE = 10001;
      SET O_STR_RES_MSG = '필수값을 확인해주세요.';
      LEAVE MAIN_BLOCK;
    END IF;
    
    
    PROCESS_BLOCK : BEGIN

      START TRANSACTION;

      SET V_STR_PROC_STEP = '01.01';
      SET V_STR_TYPE = 'FCM 발송처리';

      INSERT INTO FCM_DB.FCM_FINISH (
          SEQ_NO                    -- 'seq no'
        , SEND_KEY                  -- '전송 키'
        , REQ_SEQ_NO                -- '요청 내역과 대응하는 일련번호'
        , RESERVATION_DT            -- '예약 노출 시작 일시'
        , CHANNEL                   -- '1: android, 2:ios, 3:web'
        , API_SERVER_KEY            -- 'FCM SERVER KEY'
        , TARGET_TYPE               -- '전송 대상 종류 FCM_TARGET_TYPE.ID - 1:단일디바이스(to), 2:주제(to), 3:조건주제(condition), 4:다수디바이스(registration_ids)'
        , SEND_TARGET               -- '전송 대상 - 1:단일디바이스(to:token), 2:주제(to:/topics/topic), 3:조건주제(condition:''topic'' in topics), 4:다수디바이스_최대1000개_구분자공백(registration_ids:["token","token",...])'
        , DATA                      -- '[FCM request param] data : json string'
        , COLLAPSE_KEY              -- '[FCM request param] collapse_key : group of message, 축소형메시지 설정하여 같은 키를 사용하는 마지막 메시지만 클라이언트에 전달됨'
        , TIME_TO_LIVE              -- '[FCM request param] time_to_live 2419200sec(0~2419200sec,): collapse_key와 함께 사용, device가 off 되었을 경우 fcm storage에 메시지가 보존되는 시간'
        , DELAY_WHILE_IDLE          -- '[FCM request param] delay_while_idle (true, false) : false일 경우 device가 idle 상태여도 메시지 전달'
        , PRIORITY                  -- '[FCM request param] priority (normal, high) : client가 절전 모드이고 값이 normal이면 메시지 전달을 즉시 하지 않음, high이면 android의 경우 doze(대기) 모드도 해제되며 메시지 즉시 전달 '
        , CONTENT_AVAILABLE         -- '[FCM request param] content_available (true, false) : iOS적용되는 값이며 true일 경우 비활성상태의 앱을 깨운다.'
        , REG_TM                    -- '등록 시각'
        , REG_IP                    -- '등록 IP'
        , RES_IP                    -- '응답 IP'
        , RES_CODE                  -- 'response code : 200, 400, 401, 5xx'
        , RES_MSG                   -- 'response message'
        , RES_BODY                  -- 'response body'
        , RES_MULTICAST_ID          -- '[response body] 필수항목, 숫자 - 멀티캐스트 메시지를 식별하는 숫자로 된 고유 ID입니다.'                                                                                                     
        , RES_SUCCESS               -- '[response body] 필수항목, 숫자 - 오류 없이 처리된 메시지 수입니다.'                                                                                                                         
        , RES_FAILURE               -- '[response body] 필수항목, 숫자 - 처리하지 못한 메시지 수입니다.'                                                                                                                            
        , RES_CANONICAL_IDS         -- '[response body] 필수항목, 숫자 - 정식 등록 토큰이 포함된 결과 수입니다.'                                                                                                                    
        , RES_RESULTS               -- '[response body] 선택사항, 배열 개체 - 처리된 메시지의 상태를 나타내는 개체의 배열입니다. 개체는 요청과 동일한 순서로 표시됩니다. 즉, 요청의 각 등록 ID마다 응답의 동일한 색인에 표시됩니다.'
        , RES_MESSAGE_ID            -- '[response body] TOPIC : 선택사항, 숫자 - FCM이 성공적으로 요청을 수신한 경우 모든 구독 기기로 전송을 시도하는 주제 메시지 ID입니다.'                                                        
        , RES_ERROR                 -- '[response body] TOPIC : 선택사항, 문자열 - 메시지를 처리할 때 발생한 오류입니다.'                                                                                                           
      ) 
      (
        SELECT  SEQ_NO
              , SEND_KEY
              , REQ_SEQ_NO
              , RESERVATION_DT
              , CHANNEL
              , API_SERVER_KEY
              , TARGET_TYPE
              , SEND_TARGET
              , DATA
              , COLLAPSE_KEY
              , TIME_TO_LIVE
              , DELAY_WHILE_IDLE
              , PRIORITY
              , CONTENT_AVAILABLE
              , REG_TM
              , REG_IP
              , I_STR_RES_IP
              , I_STR_RES_CODE
              , I_STR_RES_MSG
              , I_STR_RES_BODY
              , I_STR_RES_MULTICAST_ID
              , I_INT_RES_SUCCESS
              , I_INT_RES_FAILURE
              , I_INT_RES_CANONICAL_IDS
              , I_STR_RES_RESULTS
              , I_STR_RES_MESSAGE_ID
              , I_STR_RES_ERROR
        FROM FCM_DB.FCM_STANDBY
        WHERE SEQ_NO = I_INT_SEQ_NO
      );
      
      SET V_STR_PROC_STEP = '02.01';
      SET V_STR_TYPE = 'FCM 대기 메시지 삭제';
     
      -- MySQL AUTO_INCREMENT 문제로 데이터를 모두 지우면 문제 발생함.. 
      -- DELETE FROM FCM_DB.FCM_STANDBY WHERE SEQ_NO = I_INT_SEQ_NO
      -- https://dev.mysql.com/doc/refman/5.6/en/innodb-auto-increment-handling.html#innodb-auto-increment-initialization
      -- 오늘 날짜의 데이터만 남겨두고 나머지는 삭제 
      IF  (  SELECT COUNT(*) FROM FCM_DB.FCM_STANDBY 
            WHERE DATE(REG_TM) >= DATE(NOW())
          ) > 0 
      THEN
        DELETE T_S
        FROM  FCM_DB.FCM_STANDBY T_S
              JOIN FCM_DB.FCM_FINISH T_F
                ON T_S.SEQ_NO = T_F.SEQ_NO
        WHERE DATE(T_S.REG_TM) <= DATE_ADD(DATE(NOW()), INTERVAL -1 DAY) 
          AND DATE(T_S.RESERVATION_DT) <= DATE_ADD(DATE(NOW()), INTERVAL -1 DAY)
        ;
      END IF;
      
    END PROCESS_BLOCK;
    
    
    IF O_INT_RES_CODE = 0 THEN 
      COMMIT;
      SET O_STR_RES_MSG = CONCAT('정상 처리 되었습니다.');
    ELSEIF O_INT_RES_CODE > 0 THEN 
      ROLLBACK;
      SET O_STR_RES_MSG = CONCAT('메시지 등록이 실패하였습니다. (S:', V_STR_PROC_STEP, ')');
    END IF;
    
END MAIN_BLOCK $$
DELIMITER ;




DROP PROCEDURE IF EXISTS FCM_DB.FCM_ADD_MSG_TX_PRC;
DELIMITER $$
CREATE PROCEDURE FCM_DB.FCM_ADD_MSG_TX_PRC (
    IN I_STR_REQ_SEQ_NO           BIGINT(20)          -- [옵션] 요청 내역과 대응하는 일련번호
  , IN I_STR_RESERVATION_DT       VARCHAR(20)         -- [옵션] (default:now()) [YYYY-MM-DD-HH-MM-SS] 예약 노출 시작 일시
  , IN I_INT_CHANNEL              TINYINT(4)          -- [필수] 1: android, 2:ios, 3:web
  , IN I_STR_API_SERVER_KEY       VARCHAR(255)        -- [필수] FCM SERVER KEY
  , IN I_STR_TARGET_TYPE          TINYINT(4)          -- [필수] 전송 대상 종류 FCM_TARGET_TYPE.ID - 1:단일디바이스(to), 2:주제(to), 3:조건주제(condition), 4:다수디바이스(registration_ids)
  , IN I_STR_SEND_TARGET          TEXT                -- [필수] 전송 대상 - 1:단일디바이스(to:token), 2:주제(to:/topics/topic), 3:조건주제(condition:''topic'' in topics), 4:다수디바이스_최대1000개_구분자공백(registration_ids:["token","token",...])
  , IN I_STR_DATA                 TEXT                -- [필수] client에 전달할 json string
  , IN I_STR_REG_IP               VARCHAR(100)        -- [필수] 등록 IP
  , IN I_STR_COLLAPSE_KEY         VARCHAR(255)        -- [옵션] (DEFAULT 1) collapse_key : group of message, 축소형메시지 설정하여 같은 키를 사용하는 마지막 메시지만 클라이언트에 전달됨
  , IN I_INT_TIME_TO_LIVE         INT                 -- [옵션] (DEFAULT 43200) 범위 0~2419200 sec : collapse_key와 함께 사용, device가 off 되었을 경우 fcm storage에 메시지가 보존되는 시간
  , IN I_STR_DELAY_WHILE_IDLE     CHAR(1)             -- [옵션] (DEFAULT 2) 1:true, 2:false - false일 경우 device가 idle 상태여도 메시지 전달
  , IN I_STR_PRIORITY             CHAR(1)             -- [옵션] (DEFAULT 2) 1:normal, 2:high - client가 절전 모드이고 값이 normal이면 메시지 전달을 즉시 하지 않음, high이면 android의 경우 doze(대기) 모드도 해제되며 메시지 즉시 전달 
  , IN I_STR_CONTENT_AVAILABLE    CHAR(1)             -- [옵션] (DEFAULT 1) 1:true, 2:false - iOS에 적용되는 값이며 true일 경우 비활성상태의 앱을 깨운다
  , OUT O_INT_RES_CODE            INT                 -- 처리 결과 코드
  , OUT O_STR_RES_MSG             TEXT                -- 처리 결과 메시지
) 
    COMMENT 'fcm 메시지 등록'
  /***************************************************************
  Description     : fcm 메시지 등록
  Response        : O_INT_RES_CODE    O_STR_RES_MSG
                    0                 처리가 성공하였습니다.
                    10001             필수값을 확인해주세요.
                    10101             
                    10102             
                    10103             
                    99998             SQLEXCEPTION
  Author          : sunggue@gmail.com
  History         : 2016-06-17, Just Created
  ***************************************************************/
MAIN_BLOCK : BEGIN
    
    -- SQLEXCEPTION
    DECLARE V_STR_SQL_STATE             CHAR(5)           DEFAULT '00000';
    DECLARE V_STR_SQL_ERR_NO            CHAR(5)           DEFAULT '00000';
    DECLARE V_STR_SQL_MESSAGE           TEXT              DEFAULT '';
    
    -- STEP
    DECLARE V_STR_PROC_STEP             VARCHAR(20)       DEFAULT '00.00';
    DECLARE V_STR_TYPE                  VARCHAR(100)      DEFAULT '';
    
    -- COMMON 
    DECLARE V_INT_ROW_CNT               INT               DEFAULT 0;
    DECLARE V_INT_NOT_FOUND             INT               DEFAULT FALSE;
    DECLARE V_STR_TEMP                  VARCHAR(255)      DEFAULT '';

    -- LOCAL VALUE
--     DECLARE V_STR_SEND_KEY              VARCHAR(255)      DEFAULT '';

    DECLARE CONTINUE HANDLER FOR NOT FOUND 
      BEGIN 
        SET V_INT_NOT_FOUND = TRUE;
      END
    ;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
      BEGIN
          GET DIAGNOSTICS CONDITION 1
          V_STR_SQL_STATE = RETURNED_SQLSTATE, V_STR_SQL_ERR_NO = MYSQL_ERRNO, V_STR_SQL_MESSAGE = MESSAGE_TEXT;
          SET O_INT_RES_CODE = 99998;
          SET O_STR_RES_MSG = CONCAT(V_STR_TYPE, ' 처리를 실패하였습니다. 상황이 지속되면 다음의 내용을 전달 바랍니다. (S:', V_STR_PROC_STEP, ')');
          SET O_STR_RES_MSG = CONCAT(O_STR_RES_MSG, ' ERROR:SQLEXCEPTION ( MYSQL_ERRNO = [', V_STR_SQL_ERR_NO ,'], sql_state = [', V_STR_SQL_STATE, '], msg = [', V_STR_SQL_MESSAGE, ']');
          ROLLBACK;
      END
    ;
    
    
    -- IBATIS에서 MYSQL PROCEDURE 호출시에 SELECT 구문이 없으면 PROCEDURE를 호출한 부분에서 응답없음이 걸린다....
    -- SELECT 1;
    
    
    -- init out parameter
    SET O_INT_RES_CODE = 0;
    SET O_STR_RES_MSG = '';
    
    
    -- parameter check
    IF I_STR_TARGET_TYPE = '' OR I_STR_SEND_TARGET = '' OR I_STR_DATA = '' OR I_STR_REG_IP = '' THEN 
      SET O_INT_RES_CODE = 10001;
      SET O_STR_RES_MSG = '필수값을 확인해주세요.';
      LEAVE MAIN_BLOCK;
    END IF;
    
    
    INSERT_BLOCK : BEGIN
      IF I_STR_COLLAPSE_KEY IS NULL OR I_STR_COLLAPSE_KEY = '' THEN 
        SET I_STR_COLLAPSE_KEY = '1';
      END IF;
      IF I_INT_TIME_TO_LIVE IS NULL OR I_INT_TIME_TO_LIVE = '' THEN 
        SET I_INT_TIME_TO_LIVE = 43200;
      END IF;
      IF I_STR_DELAY_WHILE_IDLE IS NULL OR I_STR_DELAY_WHILE_IDLE = '' THEN 
        SET I_STR_DELAY_WHILE_IDLE = 2;
      END IF;
      IF I_STR_PRIORITY IS NULL OR I_STR_PRIORITY = '' THEN 
        SET I_STR_PRIORITY = 2;
      END IF;
      IF I_STR_CONTENT_AVAILABLE IS NULL OR I_STR_CONTENT_AVAILABLE = '' THEN 
        SET I_STR_CONTENT_AVAILABLE = 1;
      END IF;

      START TRANSACTION;

      CALL FCM_DB.FCM_ADD_MSG_NT_PRC (
          I_STR_REQ_SEQ_NO
        , I_STR_RESERVATION_DT
        , I_INT_CHANNEL
        , I_STR_API_SERVER_KEY
        , I_STR_TARGET_TYPE
        , I_STR_SEND_TARGET
        , I_STR_DATA
        , I_STR_REG_IP
        , I_STR_COLLAPSE_KEY
        , I_INT_TIME_TO_LIVE
        , I_STR_DELAY_WHILE_IDLE
        , I_STR_PRIORITY
        , I_STR_CONTENT_AVAILABLE
        , O_INT_RES_CODE
        , O_STR_RES_MSG
      );

    END INSERT_BLOCK;
    
    
    IF O_INT_RES_CODE = 0 THEN 
      COMMIT;
      SET O_STR_RES_MSG = CONCAT('정상 처리 되었습니다.');
    ELSEIF O_INT_RES_CODE > 0 THEN 
      ROLLBACK;
      SET O_STR_RES_MSG = CONCAT('메시지 등록이 실패하였습니다. (S:', V_STR_PROC_STEP, ')');
    END IF;
    
END MAIN_BLOCK $$
DELIMITER ;




DROP PROCEDURE IF EXISTS FCM_DB.FCM_ADD_MSG_NT_PRC;
DELIMITER $$
CREATE PROCEDURE FCM_DB.FCM_ADD_MSG_NT_PRC (
    IN I_STR_REQ_SEQ_NO           BIGINT(20)          -- [옵션] 요청 내역과 대응하는 일련번호'
  , IN I_STR_RESERVATION_DT       VARCHAR(20)         -- [옵션] (default:now()) [YYYY-MM-DD-HH-MM-SS] 예약 노출 시작 일시
  , IN I_INT_CHANNEL              TINYINT(4)          -- [필수] 1: android, 2:ios, 3:web
  , IN I_STR_API_SERVER_KEY       VARCHAR(255)        -- [필수] FCM SERVER KEY
  , IN I_STR_TARGET_TYPE          TINYINT(4)          -- [필수] '전송 대상 종류 FCM_TARGET_TYPE.ID - 1:단일디바이스(to), 2:주제(to), 3:조건주제(condition), 4:다수디바이스(registration_ids)'
  , IN I_STR_SEND_TARGET          TEXT                -- [필수] '전송 대상 - 1:단일디바이스(to:token), 2:주제(to:/topics/topic), 3:조건주제(condition:''topic'' in topics), 4:다수디바이스_최대1000개_구분자공백(registration_ids:["token","token",...])'
  , IN I_STR_DATA                 TEXT                -- [필수] client에 전달할 json string
  , IN I_STR_REG_IP               VARCHAR(100)        -- [필수] 등록 IP
  , IN I_STR_COLLAPSE_KEY         VARCHAR(255)        -- [옵션] (DEFAULT 1) collapse_key : group of message, 축소형메시지 설정하여 같은 키를 사용하는 마지막 메시지만 클라이언트에 전달됨
  , IN I_INT_TIME_TO_LIVE         INT                 -- [옵션] (DEFAULT 43200) 범위 0~2419200 sec : collapse_key와 함께 사용, device가 off 되었을 경우 fcm storage에 메시지가 보존되는 시간
  , IN I_STR_DELAY_WHILE_IDLE     CHAR(1)             -- [옵션] (DEFAULT 2) 1:true, 2:false - false일 경우 device가 idle 상태여도 메시지 전달
  , IN I_STR_PRIORITY             CHAR(1)             -- [옵션] (DEFAULT 2) 1:normal, 2:high - client가 절전 모드이고 값이 normal이면 메시지 전달을 즉시 하지 않음, high이면 android의 경우 doze(대기) 모드도 해제되며 메시지 즉시 전달 
  , IN I_STR_CONTENT_AVAILABLE    CHAR(1)             -- [옵션] (DEFAULT 1) 1:true, 2:false - iOS에 적용되는 값이며 true일 경우 비활성상태의 앱을 깨운다
  , OUT O_INT_RES_CODE            INT                 -- 처리 결과 코드
  , OUT O_STR_RES_MSG             TEXT                -- 처리 결과 메시지
) 
    COMMENT 'fcm 메시지 등록'
  /***************************************************************
  Description     : fcm 메시지 등록
  Response        : O_INT_RES_CODE    O_STR_RES_MSG
                    0                 처리가 성공하였습니다.
                    10001             필수값을 확인해주세요.
                    10101             
                    10102             
                    10103             
                    99998             SQLEXCEPTION
  Author          : sunggue@gmail.com
  History         : 2016-06-17, Just Created
  ***************************************************************/
MAIN_BLOCK : BEGIN
    
    -- SQLEXCEPTION
    DECLARE V_STR_SQL_STATE             CHAR(5)           DEFAULT '00000';
    DECLARE V_STR_SQL_ERR_NO            CHAR(5)           DEFAULT '00000';
    DECLARE V_STR_SQL_MESSAGE           TEXT              DEFAULT '';
    
    -- STEP
    DECLARE V_STR_PROC_STEP             VARCHAR(20)       DEFAULT '00.00';
    DECLARE V_STR_TYPE                  VARCHAR(100)      DEFAULT '';
    
    -- COMMON 
    DECLARE V_INT_ROW_CNT               INT               DEFAULT 0;
    DECLARE V_INT_NOT_FOUND             INT               DEFAULT FALSE;
    DECLARE V_STR_TEMP                  VARCHAR(255)      DEFAULT '';

    -- LOCAL VALUE
--     DECLARE V_STR_SEND_KEY              VARCHAR(255)      DEFAULT '';

    DECLARE CONTINUE HANDLER FOR NOT FOUND 
      BEGIN 
        SET V_INT_NOT_FOUND = TRUE;
      END
    ;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
      BEGIN
          GET DIAGNOSTICS CONDITION 1
          V_STR_SQL_STATE = RETURNED_SQLSTATE, V_STR_SQL_ERR_NO = MYSQL_ERRNO, V_STR_SQL_MESSAGE = MESSAGE_TEXT;
          SET O_INT_RES_CODE = 99998;
          SET O_STR_RES_MSG = CONCAT(V_STR_TYPE, ' 처리를 실패하였습니다. 상황이 지속되면 다음의 내용을 전달 바랍니다. (S:', V_STR_PROC_STEP, ')');
          SET O_STR_RES_MSG = CONCAT(O_STR_RES_MSG, ' ERROR:SQLEXCEPTION ( MYSQL_ERRNO = [', V_STR_SQL_ERR_NO ,'], sql_state = [', V_STR_SQL_STATE, '], msg = [', V_STR_SQL_MESSAGE, ']');
          -- ROLLBACK;
      END
    ;
    
    
    -- IBATIS에서 MYSQL PROCEDURE 호출시에 SELECT 구문이 없으면 PROCEDURE를 호출한 부분에서 응답없음이 걸린다....
    -- SELECT 1;
    
    
    -- init out parameter
    SET O_INT_RES_CODE = 0;
    SET O_STR_RES_MSG = '';
    
    
    -- parameter check
    IF I_STR_TARGET_TYPE = '' OR I_STR_SEND_TARGET = '' OR I_STR_DATA = '' OR I_STR_REG_IP = '' THEN 
      SET O_INT_RES_CODE = 10001;
      SET O_STR_RES_MSG = '필수값을 확인해주세요.';
      LEAVE MAIN_BLOCK;
    END IF;
    
    
    INSERT_BLOCK : BEGIN
      IF I_STR_COLLAPSE_KEY IS NULL OR I_STR_COLLAPSE_KEY = '' THEN 
        SET I_STR_COLLAPSE_KEY = '1';
      END IF;
      IF I_INT_TIME_TO_LIVE IS NULL OR I_INT_TIME_TO_LIVE = '' THEN 
        SET I_INT_TIME_TO_LIVE = 43200;
      END IF;
      IF I_STR_DELAY_WHILE_IDLE IS NULL OR I_STR_DELAY_WHILE_IDLE = '' THEN 
        SET I_STR_DELAY_WHILE_IDLE = 2;
      END IF;
      IF I_STR_PRIORITY IS NULL OR I_STR_PRIORITY = '' THEN 
        SET I_STR_PRIORITY = 2;
      END IF;
      IF I_STR_CONTENT_AVAILABLE IS NULL OR I_STR_CONTENT_AVAILABLE = '' THEN 
        SET I_STR_CONTENT_AVAILABLE = 1;
      END IF;


      -- START TRANSACTION;


      SET V_STR_PROC_STEP = '01.01';
      SET V_STR_TYPE = 'FCM 등록';

      INSERT INTO FCM_DB.FCM_STANDBY (
            REQ_SEQ_NO
          , RESERVATION_DT
          , CHANNEL
          , API_SERVER_KEY
          , TARGET_TYPE
          , SEND_TARGET
          , DATA
          , COLLAPSE_KEY
          , TIME_TO_LIVE
          , DELAY_WHILE_IDLE
          , PRIORITY
          , CONTENT_AVAILABLE
          , REG_IP
      ) 
      VALUES (
            I_STR_REQ_SEQ_NO
          , IF(STR_TO_DATE(I_STR_RESERVATION_DT, '%Y-%m-%d-%H-%i-%s'), STR_TO_DATE(I_STR_RESERVATION_DT, '%Y-%m-%d-%H-%i-%s'), NOW())
          , I_INT_CHANNEL
          , I_STR_API_SERVER_KEY
          , I_STR_TARGET_TYPE
          , I_STR_SEND_TARGET
          , I_STR_DATA
          , I_STR_COLLAPSE_KEY
          , I_INT_TIME_TO_LIVE
          , IF(I_STR_DELAY_WHILE_IDLE = 1, TRUE, FALSE)
          , IF(I_STR_PRIORITY = 1, 'normal', 'high')
          , IF(I_STR_CONTENT_AVAILABLE = 1, TRUE, FALSE)
          , I_STR_REG_IP
      );
      
      SET V_STR_PROC_STEP = '02.01';
      SET V_STR_TYPE = 'FCM 등록 완료';
    END INSERT_BLOCK;
    
    
    IF O_INT_RES_CODE = 0 THEN 
      SET O_STR_RES_MSG = CONCAT('정상 처리 되었습니다.');
      -- COMMIT;
    ELSEIF O_INT_RES_CODE > 0 THEN 
      SET O_STR_RES_MSG = CONCAT('메시지 등록이 실패하였습니다. (S:', V_STR_PROC_STEP, ')');
      -- ROLLBACK;
    END IF;
    
END MAIN_BLOCK $$
DELIMITER ;




-- 테스트 데이터 입력 20
INSERT INTO FCM_DB.FCM_STANDBY (TARGET_TYPE, API_SERVER_KEY, SEND_TARGET, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
  VALUES 
    (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF01', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF02', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF03', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF04', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF05', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF06', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF07', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF08', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF09', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF10', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF11', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF12', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF13', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF14', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF15', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF16', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF17', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF18', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF19', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , (1, 'SERVER KEY' ,'ASDFM ASDF ASFD ASDF20', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
;
-- 40
INSERT INTO FCM_DB.FCM_STANDBY (TARGET_TYPE, API_SERVER_KEY, SEND_TARGET, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
( 
  SELECT TARGET_TYPE, API_SERVER_KEY, SEND_TARGET, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP FROM FCM_STANDBY
);
-- 80
INSERT INTO FCM_DB.FCM_STANDBY (TARGET_TYPE, API_SERVER_KEY, SEND_TARGET, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
( 
  SELECT TARGET_TYPE, API_SERVER_KEY, SEND_TARGET, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP FROM FCM_STANDBY
);
-- 160
INSERT INTO FCM_DB.FCM_STANDBY (TARGET_TYPE, API_SERVER_KEY, SEND_TARGET, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
( 
  SELECT TARGET_TYPE, API_SERVER_KEY, SEND_TARGET, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP FROM FCM_STANDBY
);
-- 320
INSERT INTO FCM_DB.FCM_STANDBY (TARGET_TYPE, API_SERVER_KEY, SEND_TARGET, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
( 
  SELECT TARGET_TYPE, API_SERVER_KEY, SEND_TARGET, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP FROM FCM_STANDBY
);
-- 640
INSERT INTO FCM_DB.FCM_STANDBY (TARGET_TYPE, API_SERVER_KEY, SEND_TARGET, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
( 
  SELECT TARGET_TYPE, API_SERVER_KEY, SEND_TARGET, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP FROM FCM_STANDBY
);
-- 1280
INSERT INTO FCM_DB.FCM_STANDBY (TARGET_TYPE, API_SERVER_KEY, SEND_TARGET, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
( 
  SELECT TARGET_TYPE, API_SERVER_KEY, SEND_TARGET, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP FROM FCM_STANDBY
);
CALL FCM_DB.FCM_ADD_MSG_TX_PRC(1, 'ebtYhtvJXas:APA91bELSzBN6Lx3dPTG1Ahwgp2EK-Bdt5O5ZMirBoJ8vFDrx5kBG9SSGRfx8lzqbNkJqhOuPrL0pQPIu6SnQMD0QihLluwu-lE2PfXoxAv5nV8Aneqnezo9LkdQ84fzQE4X8RaoJNmx'
, '{"message":"type=browser&msg=안녕하신가1!!&code=http://www.google.com&mem_cd=all"}','127.0.0.2',  null, null, null, null, null, @RC, @RM);






