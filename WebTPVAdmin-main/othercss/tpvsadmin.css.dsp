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
http://forum.zkoss.org/question/53948/how-to-reduce-row-height-in-grid-and-listbox-component-for-zk-504-of-themes-breeze/
The following style overides the default "sapphire" theme styles for grids
	and listboxes.  It tries to make the style similar to the old "classic" theme.
	
	It also "removes" the "highlighting" of grid rows when you move the cursor
	over a row.
	
	Note: this overides the theme for "ALL" grid and lisbox components in all pages where
	header.css is included.
*/

/*
    Override CSS class of header part. 
*/

tr.z-row td.z-row-inner, tr.z-row td.z-cell, tr.z-group td.z-group-inner, tr.z-groupfoot td.z-groupfoot-inner {
    padding: 1px 1px 1px 1px;
}
td.z-listcell {
    border: 1px solid transparent;
}
tr.z-row td.z-row-inner, tr.z-row .z-cell {
    line-height: 12px;
}
div.z-listbox-body .z-listcell {
   padding: 0px;
}
tr.z-row td.z-row-inner, tr.z-row .z-cell, tr.z-row {
    background: none repeat scroll 0% 0% white;
}
tr.z-grid-odd td.z-row-inner, tr.z-grid-odd .z-cell, tr.z-grid-odd {
    background: none repeat scroll 0% 0% rgb(240, 250, 255);
}
