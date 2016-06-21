/*
 * MySQL database 로 작성된 table, procedure, function
 *
 * Author : breakout.tistory.com (sunggue@gmail.com)
 * History : 2016-06-10, Just Created
 */


-- 사용을 원하는 데이터 베이스 이름
USE tongdb;

-- GCM MESSAGE STAND BY TABLE
DROP TABLE IF EXISTS GCM_STANDBY;
CREATE TABLE GCM_STANDBY (
    SEQ_NO                    BIGINT(20)        NOT NULL      AUTO_INCREMENT                              COMMENT 'seq no'
  , REGISTRATION_IDS          TEXT                            DEFAULT NULL                                COMMENT '[GCM request param] to (구분자 공백) : registration token, notification key, or topic'
  , DATA                      TEXT              NOT NULL                                                  COMMENT '[GCM request param] data : json string'
  , COLLAPSE_KEY              VARCHAR(255)      NOT NULL      DEFAULT '1'                                 COMMENT '[GCM request param] collapse_key : group of message'
  , TIME_TO_LIVE              INT               NOT NULL      DEFAULT 43200                               COMMENT '[GCM request param] time_to_live 2419200sec(0~2419200sec,): collapse_key와 함께 사용, device가 off 되었을 경우 gcm storage에 메시지가 보존되는 시간'
  , DELAY_WHILE_IDLE          TINYINT(1)        NOT NULL      DEFAULT FALSE                               COMMENT '[GCM request param] delay_while_idle (true, false) : false일 경우 device가 idle 상태여도 메시지 전달'
  , PRIORITY                  VARCHAR(10)       NOT NULL      DEFAULT 'high'                              COMMENT '[GCM request param] priority (normal, high) : client가 절전 모드이고 값이 normal이면 메시지 전달을 즉시 하지 않음, high이면 android의 경우 doze(대기) 모드도 해제되며 메시지 즉시 전달 '
  , CONTENT_AVAILABLE         TINYINT(1)        NOT NULL      DEFAULT TRUE                                COMMENT '[GCM request param] content_available (true, false) : iOS에 적용되는 값이며 true일 경우 비활성상태의 앱을 깨운다.'
  , REG_TM                    TIMESTAMP         NOT NULL      DEFAULT CURRENT_TIMESTAMP                   COMMENT '등록 시각'
  , REG_IP                    VARCHAR(100)      NOT NULL                                                  COMMENT '등록 IP'
  , SEND_KEY                  VARCHAR(100)                    DEFAULT NULL                                COMMENT '전송 키'
  , PRIMARY KEY (SEQ_NO)
  , KEY IDX_GCM_STANDBY (SEND_KEY)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='gcm message 대기 테이블'
;




-- GCM MESSAGE SEND FINISH TABLE
DROP TABLE IF EXISTS GCM_FINISH;
CREATE TABLE GCM_FINISH (
    SEQ_NO                    BIGINT(20)        NOT NULL      AUTO_INCREMENT                              COMMENT 'seq no'
  , REGISTRATION_IDS          TEXT                            DEFAULT NULL                                COMMENT '[GCM request param] to (구분자 공백) : registration token, notification key, or topic'
  , DATA                      TEXT              NOT NULL                                                  COMMENT '[GCM request param] data : json string'
  , COLLAPSE_KEY              VARCHAR(255)      NOT NULL      DEFAULT '1'                                 COMMENT '[GCM request param] collapse_key : group of message'
  , TIME_TO_LIVE              INT               NOT NULL      DEFAULT 43200                               COMMENT '[GCM request param] time_to_live 2419200sec(0~2419200sec,): collapse_key와 함께 사용, device가 off 되었을 경우 gcm storage에 메시지가 보존되는 시간'
  , DELAY_WHILE_IDLE          TINYINT(1)        NOT NULL      DEFAULT FALSE                               COMMENT '[GCM request param] delay_while_idle (true, false) : false일 경우 device가 idle 상태여도 메시지 전달'
  , PRIORITY                  VARCHAR(10)       NOT NULL      DEFAULT 'high'                              COMMENT '[GCM request param] priority (normal, high) : client가 절전 모드이고 값이 normal이면 메시지 전달을 즉시 하지 않음, high이면 android의 경우 doze(대기) 모드도 해제되며 메시지 즉시 전달 '
  , CONTENT_AVAILABLE         TINYINT(1)        NOT NULL      DEFAULT TRUE                                COMMENT '[GCM request param] content_available (true, false) : iOS적용되는 값이며 true일 경우 비활성상태의 앱을 깨운다.'
  , REG_TM                    TIMESTAMP         NOT NULL                                                  COMMENT '등록 시각'
  , REG_IP                    VARCHAR(100)      NOT NULL                                                  COMMENT '등록 IP'
  , SEND_KEY                  VARCHAR(100)                    DEFAULT NULL                                COMMENT '전송 키'
  , RES_TM                    TIMESTAMP         NULL          DEFAULT CURRENT_TIMESTAMP                   COMMENT '응답 시각'
  , RES_IP                    VARCHAR(100)      NOT NULL                                                  COMMENT '응답 IP'
  , RES_CODE                  VARCHAR(10)                     DEFAULT NULL                                COMMENT 'response code : 200, 400, 401, 5xx'
  , RES_MSG                   TEXT                            DEFAULT NULL                                COMMENT 'response message'
  , RES_BODY                  TEXT                            DEFAULT NULL                                COMMENT 'response body'
  , RES_MULTICAST_ID          VARCHAR(255)                    DEFAULT NULL                                COMMENT '[response body] Unique ID (number) identifying the multicast message'
  , RES_SUCCESS               INT                             DEFAULT NULL                                COMMENT '[response body] Number of messages that were processed without an error'
  , RES_FAILURE               INT                             DEFAULT NULL                                COMMENT '[response body] Number of messages that could not be processed'
  , RES_CANONICAL_IDS         TEXT                            DEFAULT NULL                                COMMENT '[response body] Number of results that contain a canonical registration token. See the registration overview for more discussion of this topic'
  , RES_RESULTS               TEXT                            DEFAULT NULL                                COMMENT '[response body] Array of objects representing the status of the messages processed. The objects are listed in the same order as the request (i.e., for each registration ID in the request, its result is listed in the same index in the response)'
  , RES_MESSAGE_ID            VARCHAR(255)                    DEFAULT NULL                                COMMENT '[response body] TOPIC : The topic message ID when GCM has successfully received the request and will attempt to deliver to all subscribed devices.'
  , RES_ERROR                 VARCHAR(255)                    DEFAULT NULL                                COMMENT '[response body] TOPIC : error that occurred when processing the message.'
  , PRIMARY KEY (SEQ_NO)
  , KEY IDX_GCM_STANDBY (SEND_KEY)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='gcm message 발송완료 테이블'
;




DROP PROCEDURE IF EXISTS GCM_PREPARE_TX_PRC;
DELIMITER $$
CREATE PROCEDURE GCM_PREPARE_TX_PRC (
    IN  I_INT_PAGE_COUNT          INT                 -- 전송 설정을 할 수량 (default: 1000)
  , OUT O_STR_SEND_KEY            TEXT                -- 전송 키, 다수일 경우 공백을 구분자로 구성하여 전달
  , OUT O_INT_RES_CODE            INT                 -- 처리 결과 코드
  , OUT O_STR_RES_MSG             TEXT                -- 처리 결과 메시지
) 
    COMMENT 'gcm 메시지를 전송 가능 상태로 변경한다.'
  /***************************************************************
  Description     : gcm 메시지를 전송 가능 상태로 변경한다.
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

      UPDATE GCM_STANDBY
      SET SEND_KEY = V_STR_SEND_KEY
      WHERE SEND_KEY IS NULL
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




DROP PROCEDURE IF EXISTS GCM_PROCESS_SEND_MSG_TX_PRC;
DELIMITER $$
CREATE PROCEDURE GCM_PROCESS_SEND_MSG_TX_PRC (
    IN I_INT_SEQ_NO                 BIGINT(20)          -- [필수] GCM_STANDBY.SEQ_NO
  , IN I_STR_RES_IP                 VARCHAR(100)        -- [필수] 응답 IP
  , IN I_STR_RES_CODE               VARCHAR(10)         -- [필수] response code : 200, 400, 401, 5xx
  , IN I_STR_RES_MSG                TEXT                -- [필수] response message
  , IN I_STR_RES_BODY               TEXT                -- [필수] response body
  , IN I_STR_RES_MULTICAST_ID       VARCHAR(255)        -- [옵션] [response body] Unique ID (number) identifying the multicast message
  , IN I_INT_RES_SUCCESS            INT                 -- [옵션] [response body] Number of messages that were processed without an error
  , IN I_INT_RES_FAILURE            INT                 -- [옵션] [response body] Number of messages that could not be processed
  , IN I_STR_RES_CANONICAL_IDS      TEXT                -- [옵션] [response body] Number of results that contain a canonical registration token. See the registration overview for more discussion of this topic
  , IN I_STR_RES_RESULTS            TEXT                -- [옵션] [response body] Array of objects representing the status of the messages processed. The objects are listed in the same order as the request (i.e., for each registration ID in the request, its result is listed in the same index in the response)
  , IN I_STR_RES_MESSAGE_ID         VARCHAR(255)        -- [옵션] [response body] TOPIC : The topic message ID when GCM has successfully received the request and will attempt to deliver to all subscribed devices.
  , IN I_STR_RES_ERROR              VARCHAR(255)        -- [옵션] [response body] TOPIC : error that occurred when processing the message.
  , OUT O_INT_RES_CODE              INT                 -- 처리 결과 코드
  , OUT O_STR_RES_MSG               TEXT                -- 처리 결과 메시지
) 
    COMMENT 'gcm 메시지 발송 처리'
  /***************************************************************
  Description     : gcm 메시지 발송 처리
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
      SET V_STR_TYPE = 'GCM 발송처리';

      INSERT INTO GCM_FINISH (
          SEQ_NO                    -- 'seq no'
        , REGISTRATION_IDS          -- '[GCM request param] to (구분자 공백) : registration token, notification key, or topic'
        , DATA                      -- '[GCM request param] data : json string'
        , COLLAPSE_KEY              -- '[GCM request param] collapse_key : group of message'
        , TIME_TO_LIVE              -- '[GCM request param] time_to_live 2419200sec(0~2419200sec,): collapse_key와 함께 사용, device가 off 되었을 경우 gcm storage에 메시지가 보존되는 시간'
        , DELAY_WHILE_IDLE          -- '[GCM request param] delay_while_idle (true, false) : false일 경우 device가 idle 상태여도 메시지 전달'
        , PRIORITY                  -- '[GCM request param] priority (normal, high) : client가 절전 모드이고 값이 normal이면 메시지 전달을 즉시 하지 않음, high이면 android의 경우 doze(대기) 모드도 해제되며 메시지 즉시 전달 '
        , CONTENT_AVAILABLE         -- '[GCM request param] content_available (true, false) : iOS적용되는 값이며 true일 경우 비활성상태의 앱을 깨운다.'
        , REG_TM                    -- '등록 시각'
        , REG_IP                    -- '등록 IP'
        , SEND_KEY                  -- '전송 키'
        , RES_IP                    -- '응답 IP'
        , RES_CODE                  -- 'response code : 200, 400, 401, 5xx'
        , RES_MSG                   -- 'response message'
        , RES_BODY                  -- 'response body'
        , RES_MULTICAST_ID          -- '[response body] Unique ID (number) identifying the multicast message'
        , RES_SUCCESS               -- '[response body] Number of messages that were processed without an error'
        , RES_FAILURE               -- '[response body] Number of messages that could not be processed'
        , RES_CANONICAL_IDS         -- '[response body] Number of results that contain a canonical registration token. See the registration overview for more discussion of this topic'
        , RES_RESULTS               -- '[response body] Array of objects representing the status of the messages processed. The objects are listed in the same order as the request (i.e., for each registration ID in the request, its result is listed in the same index in the response)'
        , RES_MESSAGE_ID            -- '[response body] TOPIC : The topic message ID when GCM has successfully received the request and will attempt to deliver to all subscribed devices.'
        , RES_ERROR                 -- '[response body] TOPIC : error that occurred when processing the message'
      ) 
      (
        SELECT  SEQ_NO
              , REGISTRATION_IDS
              , DATA
              , COLLAPSE_KEY
              , TIME_TO_LIVE
              , DELAY_WHILE_IDLE
              , PRIORITY
              , CONTENT_AVAILABLE
              , REG_TM
              , REG_IP
              , SEND_KEY
              , I_STR_RES_IP
              , I_STR_RES_CODE
              , I_STR_RES_MSG
              , I_STR_RES_BODY
              , I_STR_RES_MULTICAST_ID
              , I_INT_RES_SUCCESS
              , I_INT_RES_FAILURE
              , I_STR_RES_CANONICAL_IDS
              , I_STR_RES_RESULTS
              , I_STR_RES_MESSAGE_ID
              , I_STR_RES_ERROR
        FROM GCM_STANDBY
        WHERE SEQ_NO = I_INT_SEQ_NO
      );
      
      SET V_STR_PROC_STEP = '02.01';
      SET V_STR_TYPE = 'GCM 대기 메시지 삭제';
      DELETE FROM GCM_STANDBY WHERE SEQ_NO = I_INT_SEQ_NO
      ;
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




DROP PROCEDURE IF EXISTS GCM_ADD_MSG_TX_PRC;
DELIMITER $$
CREATE PROCEDURE GCM_ADD_MSG_TX_PRC (
    IN I_STR_REGISTRATION_IDS     TEXT                -- [필수] to (구분자 공백) : registration token, notification key, or topic
  , IN I_STR_DATA                 TEXT                -- [필수] client에 전달할 json string
  , IN I_STR_REG_IP               VARCHAR(100)        -- [필수] 등록 IP
  , IN I_STR_COLLAPSE_KEY         VARCHAR(255)        -- [옵션] (DEFAULT 1) group of message
  , IN I_INT_TIME_TO_LIVE         INT                 -- [옵션] (DEFAULT 43200) 범위 0~2419200 sec : collapse_key와 함께 사용, device가 off 되었을 경우 gcm storage에 메시지가 보존되는 시간
  , IN I_STR_DELAY_WHILE_IDLE     CHAR(1)             -- [옵션] (DEFAULT 2) 1:true, 2:false - false일 경우 device가 idle 상태여도 메시지 전달
  , IN I_STR_PRIORITY             CHAR(1)             -- [옵션] (DEFAULT 2) 1:normal, 2:high - client가 절전 모드이고 값이 normal이면 메시지 전달을 즉시 하지 않음, high이면 android의 경우 doze(대기) 모드도 해제되며 메시지 즉시 전달 
  , IN I_STR_CONTENT_AVAILABLE    CHAR(1)             -- [옵션] (DEFAULT 1) 1:true, 2:false - iOS에 적용되는 값이며 true일 경우 비활성상태의 앱을 깨운다
  , OUT O_INT_RES_CODE            INT                 -- 처리 결과 코드
  , OUT O_STR_RES_MSG             TEXT                -- 처리 결과 메시지
) 
    COMMENT 'gcm 메시지 등록'
  /***************************************************************
  Description     : gcm 메시지 등록
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
    IF I_STR_REGISTRATION_IDS = '' OR I_STR_DATA = '' OR I_STR_REG_IP = '' THEN 
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

      CALL GCM_ADD_MSG_NT_PRC (
          I_STR_REGISTRATION_IDS
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




DROP PROCEDURE IF EXISTS GCM_ADD_MSG_NT_PRC;
DELIMITER $$
CREATE PROCEDURE GCM_ADD_MSG_NT_PRC (
    IN I_STR_REGISTRATION_IDS     TEXT                -- [필수] to (구분자 공백) : registration token, notification key, or topic
  , IN I_STR_DATA                 TEXT                -- [필수] client에 전달할 json string
  , IN I_STR_REG_IP               VARCHAR(100)        -- [필수] 등록 IP
  , IN I_STR_COLLAPSE_KEY         VARCHAR(255)        -- [옵션] (DEFAULT 1) group of message
  , IN I_INT_TIME_TO_LIVE         INT                 -- [옵션] (DEFAULT 43200) 범위 0~2419200 sec : collapse_key와 함께 사용, device가 off 되었을 경우 gcm storage에 메시지가 보존되는 시간
  , IN I_STR_DELAY_WHILE_IDLE     CHAR(1)             -- [옵션] (DEFAULT 2) 1:true, 2:false - false일 경우 device가 idle 상태여도 메시지 전달
  , IN I_STR_PRIORITY             CHAR(1)             -- [옵션] (DEFAULT 2) 1:normal, 2:high - client가 절전 모드이고 값이 normal이면 메시지 전달을 즉시 하지 않음, high이면 android의 경우 doze(대기) 모드도 해제되며 메시지 즉시 전달 
  , IN I_STR_CONTENT_AVAILABLE    CHAR(1)             -- [옵션] (DEFAULT 1) 1:true, 2:false - iOS에 적용되는 값이며 true일 경우 비활성상태의 앱을 깨운다
  , OUT O_INT_RES_CODE            INT                 -- 처리 결과 코드
  , OUT O_STR_RES_MSG             TEXT                -- 처리 결과 메시지
) 
    COMMENT 'gcm 메시지 등록'
  /***************************************************************
  Description     : gcm 메시지 등록
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
    IF I_STR_REGISTRATION_IDS = '' OR I_STR_DATA = '' OR I_STR_REG_IP = '' THEN 
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
      SET V_STR_TYPE = 'GCM 등록';

      INSERT INTO GCM_STANDBY (
            REGISTRATION_IDS
          , DATA
          , COLLAPSE_KEY
          , TIME_TO_LIVE
          , DELAY_WHILE_IDLE
          , PRIORITY
          , CONTENT_AVAILABLE
          , REG_IP
      ) 
      VALUES (
            I_STR_REGISTRATION_IDS
          , I_STR_DATA
          , I_STR_COLLAPSE_KEY
          , I_INT_TIME_TO_LIVE
          , IF(I_STR_DELAY_WHILE_IDLE = 1, TRUE, FALSE)
          , IF(I_STR_PRIORITY = 1, 'normal', 'high')
          , IF(I_STR_CONTENT_AVAILABLE = 1, TRUE, FALSE)
          , I_STR_REG_IP
      );
      
      SET V_STR_PROC_STEP = '02.01';
      SET V_STR_TYPE = 'GCM 등록 완료';
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
INSERT INTO GCM_STANDBY (REGISTRATION_IDS, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
  VALUES 
    ('ASDFM ASDF ASFD ASDF01', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF02', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF03', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF04', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF05', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF06', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF07', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF08', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF09', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF10', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF11', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF12', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF13', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF14', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF15', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF16', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF17', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF18', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF19', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
  , ('ASDFM ASDF ASFD ASDF20', '{"msg":"asdf=asdf&fdgh=oi8"}', '1', 43200, FALSE, 'high', TRUE, '127.0.0.1')
;
-- 40
INSERT INTO GCM_STANDBY (REGISTRATION_IDS, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
( 
  SELECT REGISTRATION_IDS, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP FROM GCM_STANDBY
);
-- 80
INSERT INTO GCM_STANDBY (REGISTRATION_IDS, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
( 
  SELECT REGISTRATION_IDS, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP FROM GCM_STANDBY
);
-- 160
INSERT INTO GCM_STANDBY (REGISTRATION_IDS, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
( 
  SELECT REGISTRATION_IDS, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP FROM GCM_STANDBY
);
-- 320
INSERT INTO GCM_STANDBY (REGISTRATION_IDS, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
( 
  SELECT REGISTRATION_IDS, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP FROM GCM_STANDBY
);
-- 640
INSERT INTO GCM_STANDBY (REGISTRATION_IDS, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
( 
  SELECT REGISTRATION_IDS, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP FROM GCM_STANDBY
);
-- 1280
INSERT INTO GCM_STANDBY (REGISTRATION_IDS, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP) 
( 
  SELECT REGISTRATION_IDS, DATA, COLLAPSE_KEY, TIME_TO_LIVE, DELAY_WHILE_IDLE, PRIORITY, CONTENT_AVAILABLE, REG_IP FROM GCM_STANDBY
);
CALL GCM_ADD_MSG_TX_PRC('ebtYhtvJXas:APA91bELSzBN6Lx3dPTG1Ahwgp2EK-Bdt5O5ZMirBoJ8vFDrx5kBG9SSGRfx8lzqbNkJqhOuPrL0pQPIu6SnQMD0QihLluwu-lE2PfXoxAv5nV8Aneqnezo9LkdQ84fzQE4X8RaoJNmx'
, '{"message":"type=browser&msg=안녕하신가1!!&code=http://www.google.com&mem_cd=all"}','127.0.0.2',  null, null, null, null, null, @01, @02);
CALL GCM_ADD_MSG_TX_PRC('ebtYhtvJXas:APA91bELSzBN6Lx3dPTG1Ahwgp2EK-Bdt5O5ZMirBoJ8vFDrx5kBG9SSGRfx8lzqbNkJqhOuPrL0pQPIu6SnQMD0QihLluwu-lE2PfXoxAv5nV8Aneqnezo9LkdQ84fzQE4X8RaoJNmx'
, '{"message":"type=browser&msg=안녕하신가2!!&code=http://www.google.com&mem_cd=all"}','127.0.0.2',  null, null, null, null, null, @01, @02);
CALL GCM_ADD_MSG_TX_PRC('ebtYhtvJXas:APA91bELSzBN6Lx3dPTG1Ahwgp2EK-Bdt5O5ZMirBoJ8vFDrx5kBG9SSGRfx8lzqbNkJqhOuPrL0pQPIu6SnQMD0QihLluwu-lE2PfXoxAv5nV8Aneqnezo9LkdQ84fzQE4X8RaoJNmx'
, '{"message":"type=browser&msg=안녕하신가!3!&code=http://www.google.com&mem_cd=all"}','127.0.0.2',  null, null, null, null, null, @01, @02);
CALL GCM_ADD_MSG_TX_PRC('ebtYhtvJXas:APA91bELSzBN6Lx3dPTG1Ahwgp2EK-Bdt5O5ZMirBoJ8vFDrx5kBG9SSGRfx8lzqbNkJqhOuPrL0pQPIu6SnQMD0QihLluwu-lE2PfXoxAv5nV8Aneqnezo9LkdQ84fzQE4X8RaoJNmx'
, '{"message":"type=browser&msg=안녕하신가4!!&code=http://www.google.com&mem_cd=all"}','127.0.0.2',  null, null, null, null, null, @01, @02);
CALL GCM_ADD_MSG_TX_PRC('ebtYhtvJXas:APA91bELSzBN6Lx3dPTG1Ahwgp2EK-Bdt5O5ZMirBoJ8vFDrx5kBG9SSGRfx8lzqbNkJqhOuPrL0pQPIu6SnQMD0QihLluwu-lE2PfXoxAv5nV8Aneqnezo9LkdQ84fzQE4X8RaoJNmx'
, '{"message":"type=news&msg=안녕하신가5!!&code=1234&mem_cd=all"}','127.0.0.2',  null, null, null, null, null, @01, @02);
SELECT @o1, @o2;






