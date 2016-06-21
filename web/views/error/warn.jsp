<?xml version="1.0" encoding="UTF-8" ?>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>

<!DOCTYPE html>
<html>

<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="X-UA-Compatible" content="IE=edge" />
<meta http-equiv='Cache-Control' content='no-cache' />
<meta http-equiv='Pragma' content='no-cache' />
<meta http-equiv="Expires" content="-1" />
<meta name="Author" content="sourapples" />
<meta name="Other Agent" content="gue" />
<meta name="Location" content="Korea" />
<meta name="Content-language" content="Korean" />

<!-- <link type="image/x-icon" href="/favicon.ico" rel="icon" />
<link type="image/x-icon" href="/favicon.ico" rel="shortcut icon" /> -->

<style type="text/css">
body {
    padding: 80px;
    background-color: red;
}

hr {
    width: 500px;
}
</style>

<script type="text/javascript">
    function setHr() {
        var hr = document.getElementsByTagName('hr');
        for (var i = 0; i < hr.length; i++) {
            hr[i].setAttribute('align', 'left');
        }
    }
    window.onload = setHr;
</script>

<!--    <meta http-equiv="Refresh" content="2; url=/" /> -->
<title>wrong page</title>
</head>

<body style="padding: 80px; background-color: red;">


    <hr />
    <%-- 	<c:if test="${!empty requestScope.error_msg and !empty sessionScope.admin }"> --%>
    <c:if test="${!empty requestScope.error }">
        <h5>Code : ${requestScope.error.code }</h5>
    </c:if>
    <h5>Message : ${requestScope.error.msg }</h5>
    <hr />
    <h5>2초 뒤에 홈으로 자동 이동합니다.</h5>
    <h5>
        <a href="/living" style="color: yellow">이동이 되지 않는다면 클릭하세요.</a>
    </h5>


</body>
</html>