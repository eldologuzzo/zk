<%--
tab.dsp

{{IS_NOTE
	Purpose:
		
	Description:
		
	History:
		Tue Jul 12 10:58:42     2005, Created by tomyeh@potix.com
}}IS_NOTE

Copyright (C) 2005 Potix Corporation. All Rights Reserved.

{{IS_RIGHT
	This program is distributed under GPL Version 2.0 in the hope that
	it will be useful, but WITHOUT ANY WARRANTY.
}}IS_RIGHT
--%><%@ taglib uri="/WEB-INF/tld/web/core.dsp.tld" prefix="c" %>
<c:set var="self" value="${requestScope.arg.self}"/>
<c:set var="suffix" value="-sel.gif" if="${self.selected}"/>
<c:set var="suffix" value="-uns.gif" unless="${self.selected}"/>
<td id="${self.uuid}" zk_type="Tab"${self.outerAttrs} zk_sel="${self.selected}" zk_box="${self.tabbox.uuid}" zk_panel="${self.linkedPanel.uuid}">
<table border="0" cellpadding="0" cellspacing="0" width="100%">
<tr>
	<td width="5" height="5" style="background-image:url(${c:encodeURL(c:cat('~./zul/img/tab/3d-tl',suffix))})"></td>
	<td colspan="3" height="5" style="background-image:url(${c:encodeURL(c:cat('~./zul/img/tab/3d-tm',suffix))})"></td>
	<td width="5" height="5" style="background-image:url(${c:encodeURL(c:cat('~./zul/img/tab/3d-tr',suffix))})"></td>
</tr>
<tr height="22">
	<td width="5" style="background-image:url(${c:encodeURL(c:cat('~./zul/img/tab/3d-ml',suffix))})"></td>
	<td width="3" style="background-image:url(${c:encodeURL(c:cat('~./zul/img/tab/3d-mm',suffix))})"></td>
	<td align="center" style="background-image:url(${c:encodeURL(c:cat('~./zul/img/tab/3d-mm',suffix))})" id="${self.uuid}!real"${self.innerAttrs}><a href="javascript:;" id="${self.uuid}!a">${self.imgTag}<c:out value="${self.label}"/></a></td>
	<td width="3" style="background-image:url(${c:encodeURL(c:cat('~./zul/img/tab/3d-mm',suffix))})"></td>
	<td width="5" style="background-image:url(${c:encodeURL(c:cat('~./zul/img/tab/3d-mr',suffix))})"></td>
</tr>
<tr>
	<td width="5" height="3" style="background-image:url(${c:encodeURL(c:cat('~./zul/img/tab/3d-bl',suffix))})"></td>
	<td colspan="3" height="3" style="background-image:url(${c:encodeURL(c:cat('~./zul/img/tab/3d-bm',suffix))})"></td>
	<td width="5" height="3" style="background-image:url(${c:encodeURL(c:cat('~./zul/img/tab/3d-br',suffix))})"></td>
</tr>
</table>
</td>
