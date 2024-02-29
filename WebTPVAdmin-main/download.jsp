<%@page import="org.owasp.encoder.Encode"%>
<%@page contentType="text/html"%>
<%@page pageEncoding="UTF-8"%>
<%@page import="com.tpvs.util.dwnld,java.util.Hashtable,java.io.BufferedInputStream, java.io.File, java.io.FileInputStream, java.util.Calendar" %>


<%
String param_idTerminal = request.getParameter("idTerminal");
param_idTerminal = param_idTerminal == null?"":param_idTerminal.replaceAll("-", "");
String param_Type = request.getParameter("Type");
String param_Model = request.getParameter("Model");
String param_AppName = request.getParameter("AppName");
String param_AppVersion = request.getParameter("AppVersion");
String param_Password = request.getParameter("Password");
String param_MerchantID = request.getParameter("MerchantID");
String param_fileToReturn = request.getParameter("fileToReturn");
String param_fnctnToReturn = request.getParameter("fnctnToReturn");
String param_dwnldOnlyVars = request.getParameter("dwnldOnlyVars");
String param_folio = request.getParameter("folio");
String param_AXTID = request.getParameter("AXTID");
String param_versionInicializacion = request.getParameter("versionInicializacion");

/*
 * Prueba para regresar respuesta en blanco para terminales hypercom principalmente.
 * Bloque que se colocó sólo como prueba para los problemas de configuración del enlace recién colocado.
if(param_Model!=null && com.tpvs.util.MyProperties.getPropiedad("stLstTermWithOutZipInLicense").contains(param_Model) &&
        (param_Type==null || !param_Type.equalsIgnoreCase("License"))) {
    com.tpvs.util.LogApp.addTraceToApp(com.tpvs.util.MyProperties.getPropiedad("stLoggerDwnldTPV"), "INFO", param_idTerminal +
            " - Retorno sin repuesta.");
    return;
}
*/

if(param_fileToReturn!=null || param_fnctnToReturn!=null || param_dwnldOnlyVars!=null)
    com.tpvs.util.LogApp.addTraceToApp(com.tpvs.util.MyProperties.getPropiedad("stLoggerDwnldTPV"), "INFO", param_idTerminal +
            " - Redirección del resultado del proceso a:"
            + (param_fileToReturn!=null?("\nparam_fileToReturn.- " + param_fileToReturn):"")
            + (param_fnctnToReturn!=null?("\nparam_fnctnToReturn.- " + param_fnctnToReturn):"")
            + (param_dwnldOnlyVars!=null?("\nparam_dwnldOnlyVars.- " + param_dwnldOnlyVars):""));

if(param_AppVersion!=null && param_AppVersion.contains("AXPR") && param_AppVersion.contains("96")) {
            param_fnctnToReturn = null;
            com.tpvs.util.LogApp.addTraceToApp(com.tpvs.util.MyProperties.getPropiedad("stLoggerDwnldTPV"), "INFO", param_idTerminal
                    + " - Parámetros MODIFICADOS (\"PATCH\" a solicitud y autorización de RCG el 20121029):"
                + "\nparam_fnctnToReturn.- " + param_fnctnToReturn);               //SN
        }

if(param_fileToReturn!=null && param_fileToReturn.length()>0 && !param_fileToReturn.contains(".wml"))
    param_fileToReturn += ".wmlsc";

param_fileToReturn = param_fileToReturn == null?"download.wmlsc":param_fileToReturn;
param_fnctnToReturn = param_fnctnToReturn == null?"download":param_fnctnToReturn;
param_dwnldOnlyVars = (param_dwnldOnlyVars == null || !param_dwnldOnlyVars.equalsIgnoreCase("1"))?"false":"true";

String name, value;
for (java.util.Enumeration e = request.getParameterNames(); e.hasMoreElements();) {
    name = (String) e.nextElement();
    value = (String) request.getParameter(name);
    com.tpvs.util.LogApp.addTraceToApp(com.tpvs.util.MyProperties.getPropiedad("stLoggerDwnldTPV"), "DEBUG", name + " = " + value);
}

dwnld dwnldProceso = new dwnld(param_idTerminal, param_Type, param_Model, param_AppName, param_AppVersion, param_Password, param_MerchantID,
        request.getContextPath(), String.valueOf(request.getLocalPort()), request.getRemoteAddr(), param_folio,
        Boolean.parseBoolean(param_dwnldOnlyVars), param_AXTID, param_versionInicializacion);

com.tpvs.util.LogApp.addTraceToApp(com.tpvs.util.MyProperties.getPropiedad("stLoggerDwnldTPV"), "INFO", param_idTerminal 
                    + " - " + Calendar.getInstance().getTime());

Hashtable haResult = dwnldProceso.procesa(request);

com.tpvs.util.LogApp.addTraceToApp(com.tpvs.util.MyProperties.getPropiedad("stLoggerDwnldTPV"), "INFO", param_idTerminal 
                    + " - " + Calendar.getInstance().getTime());

String stCheckSum = (String)haResult.get("stCheckSum")==null?"0":(String)haResult.get("stCheckSum");
String stNewVersion = (String)haResult.get("stNewVersion")==null?"":(String)haResult.get("stNewVersion");
if(param_AXTID!=null && haResult.get("serialNumberByAXTID")!=null) {
    param_idTerminal = haResult.get("serialNumberByAXTID").toString();
}

com.tpvs.util.LogApp.addTraceToApp(com.tpvs.util.MyProperties.getPropiedad("stLoggerDwnldTPV"), "INFO", param_idTerminal 
                    + " - " + Calendar.getInstance().getTime());
%>

<%
if ((Boolean)haResult.get("boResult")) {
    if((Boolean)haResult.get("boFile")) {
        BufferedInputStream buf=null;

        try {
            File myfile = (File)haResult.get("fiFile");

            response.setContentType("text/plain");
            /*Improper Neutralization of CRLF Sequences in HTTP Headers ('HTTP Response Splitting')(CWE ID 113)*/
            //response.addHeader("Content-Disposition","attachment; filename=" + myfile.getName());
            response.addHeader("Content-Disposition","attachment; filename=" + Encode.forHtml(myfile.getName()));
            response.setContentLength((int)myfile.length());

            FileInputStream input = new FileInputStream(myfile);
            buf = new BufferedInputStream(input);
            int readBytes = 0;

            out.clearBuffer();
            while((readBytes = buf.read()) != -1)
                out.write(readBytes);
        } finally {
            if(buf != null)
                buf.close();
        }
        return;
    } else if((Boolean)haResult.get("boResultInHTML")) {
        response.setContentType("text/html; charset=UTF-8");
%>
<%--
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
   "http://www.w3.org/TR/html4/loose.dtd">
--%>
<!-- Improper Neutralization of Script-Related HTML Tags in a Web Page (Basic XSS) (CWE ID 80) -->
<%=Encode.forHtml((String)haResult.get("stMessage"))%>
<%
    } else {
        response.setContentType("text/vnd.wap.wml");
%>
<%--
<?xml version="1.0"?>
 <!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN" "http://www.wapforum.org/DTD/wml_1.1.xml">
--%>
<wml>
    <card id="Updates">
        <!--Improper Handling of Invalid Use of Special Elements (CWE ID 159)-->
        <setvar name="stWEBTerminalDir" value="<%=Encode.forHtmlAttribute(param_idTerminal)%>"/>
        <setvar name="VFICHECKSUM" value="<%=Encode.forHtmlAttribute(stCheckSum)%>"/>
        <setenv name="VFINEWVERSION" value="<%=Encode.forHtmlAttribute(stNewVersion)%>"/>
        <setenv name="DWNLDOKNOTSUCCESS" value="0"/>
        <p align="center">
            <br/>
            ACTUALIZANDO...
        </p>
        <onevent type="onenterforward">
<% if ((Boolean)haResult.get("boOnlyVariables")) { %>
            <go href="f:<%=Encode.forUriComponent(param_fileToReturn)%>#<%=Encode.forUriComponent(param_fnctnToReturn)%>()" />
<% } else { %>
            <go href="f:<%=Encode.forUriComponent(param_fileToReturn)%>#download()" />
<% } %>
        </onevent>
    </card>
</wml>
<%
    }
} else {
    response.setContentType("text/vnd.wap.wml");
%>
<%--
<?xml version="1.0"?>
 <!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN" "http://www.wapforum.org/DTD/wml_1.1.xml">
--%>
<wml>
    <card id="Error" ontimer="f:<%=Encode.forUriComponent(param_fileToReturn)%>#failed()">
        <timer value="10" />
        <setenv name="DWNLDOKNOTSUCCESS" value="0"/>
        <%
        if ((Boolean)haResult.get("boUpdate")) {
        %>
        <setenv name="LASTUPDATEMONTH" value="$(UPDATEMONTH)"/>
        <%
        }
        %>
        <form>
            <p align="center">
                <br/>
                <%=Encode.forHtml((String)haResult.get("stMsg01"))%><br/>
                <%=Encode.forHtml((String)haResult.get("stMsg02"))%><br/>
            </p>
        </form>
    </card>
</wml>
<%
}
%>
