# PushServer (FCM)


### 구성
- `Spring 3.0.5`
- `ibatis`
- `Gson`


### Mysql Database 설정
- [PushServer_INIT_SQL.sql](https://github.com/sung-gue/PushServer/blob/master/web/WEB-INF/sql/PushServer_INIT_SQL.sql)를 사용하여 Database, Table, Procedure를 생성


### 서버 설정
- DB : [web/WEB-INF/properties/jdbc-sample.properties](https://github.com/sung-gue/PushServer/blob/master/web/WEB-INF/properties/jdbc-sample.properties)
```
jdbc.driver=com.mysql.jdbc.Driver
jdbc.url=jdbc:mysql://localhost:3306/dbname
jdbc.username=username
jdbc.password=password
```

- FCM api key : [web/WEB-INF/properties/push-sample.properties](https://github.com/sung-gue/PushServer/blob/master/web/WEB-INF/properties/push-sample.properties)
```
push.apiKey=gcm_api_server_key
```

### 상용 및 테스트 배포시 체크 사항
- web/WEB-INF/properties/push.properties
    - apiKey=
    - pushUrl=
    - pageCount=
- web/WEB-INF/properties/log4j.properties
    - log4j.appender.file.File=
- web/WEB-INF/properties/jdbc.properties
    - jdbc.driver=
    - jdbc.url=
    - jdbc.username=
    - jdbc.password=


### TODO
- develop,production 구분하여 build 설정
- DB 예시 추가 : 현재는 MYSql 만 작성
    - web/WEB-INF/sql/*.sql
    - [web/WEB-INF/sqlMap/push.xml](https://github.com/sung-gue/PushServer/blob/master/web/WEB-INF/sqlMap/push.xml)
- `spring`의 `task:scheduler` 를 사용하여 `FCM_DB.FCM_STANDBY` 테이블을 체크하여 localhost로 request 하는 방식에 대해 검토 필요.

