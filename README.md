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


### install tomcat & java
```
$ yum list java*jdk-devel
$ yum install java-1.8.0-openjdk-devel.x86_64
$ yum install tomcat tomcat-admin-webapps tomcat-webapps
```

### tomcat settings
```
$ service tomcat status
$ chkconfig --level 3 tomcat on
$ chkconfig --level 4 tomcat on
$ chkconfig --level 5 tomcat on
$ netstat -tulpn
$ netstat -anp | grep :8080
$ netstat -anp | grep java
$ firewall-cmd --permanent --zone=public --add-port=8080/tcp
$ firewall-cmd --reload
    ## iptables 사용
    ## iptables -nL
    ## iptables -I INPUT 1 -p tcp --dport 8080 -j ACCEPT
    ## service iptables save

```

### /usr/share/tomcat/conf/server.xml
- 아래 항목의 내용이 맞는지 확인, tomcat 설치후 기본설정만을 사용함.
```
<Connector port="8080" protocol="HTTP/1.1"
   connectionTimeout="20000"
   redirectPort="8443"
   maxThreads="100"
   URIEncoding="utf-8" />
<Host name="localhost"  appBase="webapps" unpackWARs="true" autoDeploy="true">

<Context path="" docBase="sample" reloadable="true"/>
```


### TODO
- develop,production 구분하여 build 설정
- DB 예시 추가 : 현재는 MYSql 만 작성
    - web/WEB-INF/sql/*.sql
    - [web/WEB-INF/sqlMap/push.xml](https://github.com/sung-gue/PushServer/blob/master/web/WEB-INF/sqlMap/push.xml)
- `spring`의 `task:scheduler` 를 사용하여 `FCM_DB.FCM_STANDBY` 테이블을 체크하여 localhost로 request 하는 방식에 대해 검토 필요.

