<%@page import="org.owasp.encoder.Encode"%>
<%@page contentType="text/html"%>
<%@page pageEncoding="UTF-8"%>
<%@page import="com.tpvs.util.dwnld,java.util.Hashtable,java.io.BufferedInputStream, java.io.File, java.io.FileInputStream" %>


<%
String param_idTerminal = request.getParameter("idTerminal");
String param_fileToReturn = request.getParameter("fileToReturn");
String param_fnctnToReturn = request.getParameter("fnctnToReturn");
String param_dwnldOnlyVars = request.getParameter("dwnldOnlyVars");

if(param_fileToReturn!=null || param_fnctnToReturn!=null)
    com.tpvs.util.LogApp.addTraceToApp(com.tpvs.util.MyProperties.getPropiedad("stLoggerDwnldTPV"), "INFO", param_idTerminal +
            " - Redirección del resultado del proceso a:"
            + (param_fileToReturn!=null?("\nparam_fileToReturn.- " + param_fileToReturn):"")
            + (param_fnctnToReturn!=null?("\nparam_fnctnToReturn.- " + param_fnctnToReturn):"")
            + (param_dwnldOnlyVars!=null?("\nparam_dwnldOnlyVars.- " + param_dwnldOnlyVars):""));

if(param_fileToReturn!=null && param_fileToReturn.length()>0 && !param_fileToReturn.contains(".wml"))
    param_fileToReturn += ".wmlsc";

boolean boOnEnterFrwrd = param_fnctnToReturn != null;
param_idTerminal = param_idTerminal == null?"":param_idTerminal.replaceAll("-", "");
param_fileToReturn = param_fileToReturn == null?"download.wmlsc":param_fileToReturn;
param_fnctnToReturn = param_fnctnToReturn == null?"unzipFile":param_fnctnToReturn;
param_dwnldOnlyVars = (param_dwnldOnlyVars == null || !param_dwnldOnlyVars.equalsIgnoreCase("1"))?"false":"true";
dwnld dwnldProceso = new dwnld(param_idTerminal, Boolean.parseBoolean(param_dwnldOnlyVars));

Hashtable haResult = dwnldProceso.procesaSuccess();

response.setContentType("text/vnd.wap.wml");
%>
<%--
<?xml version="1.0"?>
 <!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN" "http://www.wapforum.org/DTD/wml_1.1.xml">
--%>
<%
if ((Boolean)haResult.get("boResult")) {

%>
<!-- Improper Neutralization of Script-Related HTML Tags in a Web Page (Basic XSS) (CWE ID 80) -->
<!--Improper Handling of Invalid Use of Special Elements (CWE ID 159)-->
<wml>
    <card id="successDL" ontimer="f:<%=Encode.forUriComponent(param_fileToReturn)%>#<%=Encode.forUriComponent(param_fnctnToReturn)%>()">
        <timer value="10"/>
         <setvar name="MX_NOCMSRVSTATUS" value="0"/>
         <setenv name="LASTUPDATEMONTH" value="$(UPDATEMONTH)"/>
         <setenv name="DWNLDOKNOTSUCCESS" value="0"/>
        <p align="center">
            <br/>
            <%=(String)haResult.get("stMsg01")%><br/>
            <%=(String)haResult.get("stMsg02")%><br/>
        </p>
<% if(boOnEnterFrwrd) { %>
        <onevent type="onenterforward">
                <go href="f:<%=Encode.forUriComponent(param_fileToReturn)%>#<%=Encode.forUriComponent(param_fnctnToReturn)%>()" />
        </onevent>
<% } %>
    </card>
</wml>
<%
} else {
%>
<wml>
    <card id="servererror" ontimer="f:<%=Encode.forUriComponent(param_fileToReturn)%>#failed()">
        <timer value="10" />
        <p align="center">
            <br/>
            <%=(String)haResult.get("stMsg01")%><br/>
            <%=(String)haResult.get("stMsg02")%><br/>
        </p>
    </card>
</wml>
<%
}
%>
