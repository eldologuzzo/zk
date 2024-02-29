/*
To change this license header, choose License Headers in Project Properties.
To change this template file, choose Tools | Templates
and open the template in the editor.
*/
/* 
    Created on : 10-mar-2016, 22:38:31
    Author     : jstzmcbkpr
*/

/*
http://books.zkoss.org/wiki/Small_Talks/2012/March/Customize_Look_and_Feel_of_ZK_Components_Using_CSS3_-_Part_2
*/

/*
    Override CSS class of header part. 
*/

div.z-listbox,
div.z-listbox-header tr.z-listhead, div.z-listbox-header tr.z-auxhead {
    border: 1px solid #000000;
    background: linear-gradient(top, #3F3F3F 0%, #131313 60%, #000000 100%); /* W3C */
}
div.z-listbox-header th.z-listheader, div.z-listbox-header th.z-auxheader {
    border-color: #585858 #1F1F1F;
    border-style: solid solid none;
    border-width: 1px 1px 0 0;
}
.z-listheader-sort .z-listheader-sort-img {
    margin-top: 0;
    height: 0;
    width: 0;
}
.z-listheader-sort-asc .z-listheader-sort-img,
.z-listheader-sort-dsc .z-listheader-sort-img {
    background: none;
    border-style: solid;
    border-width: 4px;
    height: 0;
    width: 0;
}
.z-listheader-sort-asc .z-listheader-sort-img {
    margin-top: -8px;
    border-color: transparent transparent #D0D0D0 transparent;
}
.z-listheader-sort-dsc .z-listheader-sort-img {
    margin-top: -3px;
    border-color: #D0D0D0 transparent transparent transparent;
}
.z-listbox-header-bg {
    background-image: none;
    background-color: #1F1F1F;
}
div.z-listbox-header th.z-listheader-sort-over {
    background: linear-gradient(top,  #4f4f4f 0%,#1c1c1c 60%,#000000 100%); /* W3C */
}

/*
    Override CSS class of body part.
*/

.z-listitem {
    background: #131313;
}
tr.z-listbox-odd {
    background: #0D0D0D;
}
td.z-listcell,
tr.z-listgroup td.z-listgroup-inner {
    border: 1px solid #000000;
    box-shadow: inset 1px 1px 0 #1F1F1F;
}
tr.z-listitem-seld,
tr.z-listbox-odd tr.z-listitem-seld {
    background: #000000;
}
tr.z-listitem-over,
tr.z-listgroup-over,
 
tr.z-listbox-odd tr.z-listitem-over,
tr.z-listbox-odd tr.z-listgroup-over {
    background: #000000;
}
tr.z-listbox-odd div.z-listbox-header th.z-listheader-sort-over {
    background: linear-gradient(top,  #4f4f4f 0%,#1c1c1c 60%,#000000 100%); /* W3C */
}
tr.z-listgroup,
.z-listgroupfoot {
    background: linear-gradient(top,  #45484d 0%,#000000 100%); /* W3C */
}
tr.z-listgroup-seld {
    background-color: #000000;
    background-image: none;
}
tr.z-listgroup-over-seld {
    background-color: #000000;
    background-image: none;
}
.z-listgroup-img {
    background-image: url('../img/arrow-toggle.png');
}
tr.z-listitem-over > td.z-listcell {
    border: 1px solid #000000;
}

/*
    Override css class of footer part.
*/

div.z-listbox-footer {
    border-top: 2px solid #3B3F39;
}
div.z-listbox-footer .z-listfooter {
    background-image: none;
    background-color: #0F0F0F;
}

