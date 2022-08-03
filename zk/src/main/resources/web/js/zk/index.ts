/* eslint @typescript-eslint/no-require-imports: 0,
			 no-undef: 0,
		   @typescript-eslint/no-var-requires: 0,
		   @typescript-eslint/no-unsafe-member-access: 0,
		   @typescript-eslint/no-unsafe-assignment: 0
*/
/* index.ts

	Purpose:

	Description:

	History:
		1:17 PM 2022/1/18, Created by jumperchen

Copyright (C) 2022 Potix Corporation. All Rights Reserved.
*/
export default {};
import './crashmsg';  // side-effect-only import
import './ext/jquery'; // side-effect-only import
export * from './zk';
import './js'; // side-effect-only import
export * from './dom';
export * from './evt';
export * from './anima';
export * from './drag';
export * from './effect';
export * from './math';
export * from './utl';
export * from './keys';
export * from './widget';
export * from './pkg';
export * from './mount';
import './bookmark'; // side-effect-only import
import './historystate'; // side-effect-only import
export * from './au';
export * from './flex';
export * from './dateImpl';

declare global {
	interface Window {
		zk: ZKStatic;
		zFlex: typeof zFlex;
		$: typeof jq;
		jQuery: typeof jq;
	}
}
// export first for following js to use
// let oldZK = window.zk; // setting from Java side
// window.zk = zk;
// zk.copy(window.zk, oldZK);

// require('./dom');
// window.zjq = require('./anima').JQZKEx;
if (!window.jQuery) {
	window.$ = window.jQuery = jq;
}
if (zk.gecko) {
	require('./domgecko');
} else if (zk.safari) {
	require('./domsafari');
} else if (zk.opera) {
	require('./domopera');
}

window.$eval = function (s: string): unknown {
	//1. jq.globalEval() seems have memory leak problem, so use eval()
	//2. we cannot use eval() directly since compressor won't shorten names
	// eslint-disable-next-line no-eval
	return eval(s);
};

// var evt = require('./evt');
// zk.Event = evt.Event;
// window.zWatch = evt.zWatch;

// zk.Draggable = require('./drag').Draggable;
// zk.eff = require('./effect');

// var math = require('./math');
// zk.BigDecimal = math.BigDecimal;
// zk.Long = math.Long;

// window.zUtl = require('./utl').zUtl;
// window.zKeys = require('./keys').zKeys;

// var widget = require('./widget');
// zk.DnD = widget.DnD;
// zk.Widget = widget.Widget;
// zk.$ = widget.$;
// zk.RefWidget = widget.RefWidget;
// zk.Desktop = widget.Desktop;
// zk.Page = widget.Page;
// zk.Body = widget.Body;
// zk.Native = widget.Native;
// zk.Macro = widget.Macro;
// zk.Service = widget.Service;
// zk.Skipper = widget.Skipper;
// zk.NoDOM = widget.NoDOM;
// zk.WrapClass = widget.WrapClass;


// window.zkreg = widget.zkreg;
// window.zkservice = widget.zkservice;
// window.zkopt = widget.zkopt;

// zk.copy(zk, require('./pkg').pkg);
// zk.setLoaded = pkg.setLoaded;
// zk.setScriptLoaded = pkg.setScriptLoaded;
// zk.isLoaded = pkg.isLoaded;
// zk.load = pkg.load;
// zk._load = pkg._load;
// zk.loadScript = pkg.loadScript;
// zk.loadCSS = pkg.loadCSS;
// zk.getVersion = pkg.getVersion;
// zk.setVersion = pkg.setVersion;
// zk.depends = pkg.depends;
// zk.afterLoad = pkg.afterLoad;
// zk.getHost = pkg.getHost;
// zk.setHost = pkg.setHost;

// require('./mount');
//
// require('./bookmark');
//
// require('./historystate');

if (!Promise) {
	require('./ext/promise-polyfill.js');
}

// workaround for FileUpload with fetch() API.
require('./ext/fetch.js');
// var zAu = require('./au');
// window.zAu = zAu.zAu;
// zk.afterAuResponse = zAu.afterAuResponse;
// zk.doAfterAuResponse = zAu.doAfterAuResponse;
// window.onIframeURLChange = zAu.onIframeURLChange;

// window.zFlex = require('./flex').zFlex;

zk.touchEnabled = zk.touchEnabled !== false && (!!zk.mobile || navigator.maxTouchPoints > 0);
zk.tabletUIEnabled = zk.tabletUIEnabled !== false && !!zk.mobile;
if (zk.touchEnabled) {
	require('./ext/inputdevicecapabilities-polyfill');
	require('./zswipe');
	require('./domtouch');
}

if (zk.tabletUIEnabled) {
	document.addEventListener('DOMContentLoaded', function () {
		var jqTabletStylesheet = jq('link[href*="zkmax/css/tablet.css.dsp"]').eq(0);
		if (jqTabletStylesheet)
			jqTabletStylesheet.attr('disabled', false as unknown as string); // ZK-4451: disable tablet css
	});
}

// require('./dateImpl');

require('./ext/jquery.json.js');
require('./ext/jquery.mousewheel.js');
require('./ext/jquery.transit.js');
require('./ext/focus-options-polyfill.js');

// workaround for webpack with ./ext/moment-timezone-with-data.js
zk.mm = require('./ext/moment.js');
require('./ext/moment-timezone-with-data.js');

// register Widgets
zkreg('zk.Page', true);
