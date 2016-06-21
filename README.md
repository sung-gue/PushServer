# PushServer

* web/WEB-INF/properties/jdbc-sample.properties, web/WEB-INF/properties/push-sample.properties 내용을 참고하여 push.properties, jdbc.properties 내용을 작성

* 상용 및 테스트 배포시 체크 사항
    - web/WEB-INF/properties/push.properties
        apiKey, pushUrl, pageCount
    - web/WEB-INF/properties/log4j.properties
        log4j.appender.file.File
    - web/WEB-INF/properties/jdbc.properties
        jdbc.*

