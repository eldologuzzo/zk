/* global MediaStreamConstraints:readonly */
/* util.ts

	Purpose:

	Description:

	History:
		Tue Sep 30 09:02:06     2008, Created by tomyeh

Copyright (C) 2008 Potix Corporation. All Rights Reserved.

This program is distributed under LGPL Version 2.1 in the hope that
it will be useful, but WITHOUT ANY WARRANTY.
*/
import {default as zk} from './zk';
import {type Widget} from './widget';

var _decs = {lt: '<', gt: '>', amp: '&', quot: '"'},
	_encs = {};
for (var v in _decs)
	_encs[_decs[v]] = v;

function _pathname(url): string {
	var j = url.indexOf('//');
	if (j > 0) {
		j = url.indexOf('/', j + 2);
		if (j > 0) return url.substring(j);
	}
	return '';
}

function _frames(ary, w): void {
	//Note: the access of frames is allowed for any window (even if it connects other website)
	ary.push(w);
	for (var fs = w.frames, j = 0, l = fs.length; j < l; ++j)
		_frames(ary, fs[j]);
}
/* Returns the onSize target of the given widget.
 * The following code is dirty since it checks _hflexsz (which is implementation)
 * FUTRE: consider to have zk.Widget.beforeSize to clean up _hflexsz and
 * this method considers only if _hflex is min
 */
function _onSizeTarget(wgt): Widget {
	var r1 = wgt, p1 = r1,
		j1 = -1;
	for (; p1 && p1._hflex == 'min'; p1 = p1.parent) {
		delete p1._hflexsz;
		r1 = p1;
		++j1;
		if (p1.ignoreFlexSize_('w')) //p1 will not affect its parent's flex size
			break;
	}

	var r2 = wgt, p2 = r2,
		j2 = -1;
	for (; p2 && p2._vflex == 'min'; p2 = p2.parent) {
		delete p2._vflexsz;
		r2 = p2;
		++j2;
		if (p2.ignoreFlexSize_('h')) //p2 will not affect its parent's flex size
			break;
	}
	return j1 > 0 || j2 > 0 ? j1 > j2 ? r1 : r2 : wgt;
}

export interface IsCharOptions {
	digit: boolean | number;
	upper: boolean | number;
	lower: boolean | number;
	whitespace: boolean | number;
	[char: string]: boolean | number | undefined;
}

export interface EncodeXmlOptions {
	pre?: boolean;
	multiline?: boolean;
	maxlength?: number;
}

export interface ProgressboxOptions {
	busy: boolean;
}

export interface GoOptions {
	target: string;
	overwrite: boolean;
}
export interface ZUtl {
	cellps0: string;
	i0: string;
	img0: string;

	appendAttr(nm: string, val: unknown, force?: boolean): string;
	convertDataURLtoBlob(dataURL: string): Blob;
	decodeXML(txt: string): string;
	destroyProgressbox(id: string, opts?: Partial<ProgressboxOptions>): void;
	encodeXML(txt: string, opts?: EncodeXmlOptions): string;
	encodeXMLAttribute(txt: string): string;
	fireShown(wgt: Widget, bfsz?: number): void;
	fireSized(wgt: Widget, bfsz?: number): void;
	frames(w: Window): Window[];
	getDevicePixelRatio(): number;
	getUserMedia(constraints: MediaStreamConstraints): Promise<MediaStream>;
	getWeekOfYear(year: number, month: number, date: number, firstDayOfWeek: number,
				  minimalDaysInFirstWeek: number): number;
	go(url: string, opts?: Partial<GoOptions>): void;
	intsToString(ary: number[] | null): string;
	isAncestor(p: Widget, c: Widget & {getParent?()}): boolean;
	isChar(cc: string, opts: Partial<IsCharOptions>): boolean;
	isImageLoading(): boolean;
	loadImage(url: string): void;
	mapToString(map: Record<string, string>, assign?: string, separator?: string): string;
	parseMap(text: string, separator?: string, quote?: string): {[key: string]: string};
	progressbox(id: string, msg: string, mask?: boolean, icon?: string | null, opts?: Partial<ProgressboxOptions>): void;
	stringToInts(text: string | null, defaultValue: number): number[] | null;
	today(fmt: boolean | string | null, tz: string): DateImpl;
	throttle<T, A extends unknown[], R>(func: (this: T, ...args: A) => R, wait: number):
		(this: T, ...args: A) => R;
	debounce<T, A extends unknown[], R>(func: (this: T, ...args: A) => R, wait: number,
										immediate?: boolean): (this: T, ...args: A) => R;
	isEqualObject(a: unknown, b: unknown): boolean;
}
/** @class zUtl
 * @import zk.Widget
 * @import zk.xml.Utl
 * The basic utilities.
 * <p>For more utilities, refer to {@link Utl}.
 */
// window scope
export const zUtl: ZUtl = { //static methods
	//Character
	/**
	 * Returns whether the character is according to its opts.
	 * @param char cc the character
	 * @param Map opts the options.
<table border="1" cellspacing="0" width="100%">
<caption> Allowed Options
</caption>
<tr>
<th> Name
</th><th> Allowed Values
</th><th> Description
</th></tr>
<tr>
<td> digit
</td><td> true, false
</td><td> Specifies the character is digit only.
</td></tr>
<tr>
<td> upper
</td><td> true, false
</td><td> Specifies the character is upper case only.
</td></tr>
<tr>
<td> lower
</td><td> true, false
</td><td> Specifies the character is lower case only.
</td></tr>
<tr>
<td> whitespace
</td><td> true, false
</td><td> Specifies the character is whitespace only.
</td></tr>
<tr>
<td> opts[cc]
</td><td> true, false
</td><td> Specifies the character is allowed only.
</td></tr>
</table>
	 * @return boolean
	 */
	isChar(cc: string, opts: Partial<IsCharOptions>): boolean {
		return !!((opts.digit && cc >= '0' && cc <= '9')
			|| (opts.upper && cc >= 'A' && cc <= 'Z')
			|| (opts.lower && cc >= 'a' && cc <= 'z')
			|| (opts.whitespace && (cc == ' ' || cc == '\t' || cc == '\n' || cc == '\r'))
			|| opts[cc]);
	},

	//HTML/XML
	/** Parses the specifie text into a map.
	 * For example
	 *<pre><code>
zUtl.parseMap("a=b,c=d");
zUtl.parseMap("a='b c',c=de", ',', "'\"");
</code></pre>
	 * @param String text the text to parse
	 * @param String separator the separator. If omitted, <code>','</code>
	 * is assumed
	 * @param String quote the quote to handle. Ignored if omitted.
	 * @return Map the map
	 */
	parseMap(text: string, separator?: string, quote?: string): {[key: string]: string} {
		var map = {};
		if (text) {
			var ps = text.split(separator || ',');
			if (quote) {
				var tmp: string[] = [],
					re = new RegExp(quote, 'g'),
					key = '', t, pair;
				while ((t = ps.shift()) !== undefined) {
					if ((pair = (key += t).match(re)) && pair.length != 1) {
						if (key)
							tmp.push(key);
						key = '';
					} else
						key += separator;
				}
				ps = tmp;
			}
			for (var len = ps.length; len--;) {
				var key = ps[len].trim(),
					index = key.indexOf('=');
				if (index != -1)
					map[key.substring(0, index)] = key.substring(index + 1, key.length).trim();
			}
		}
		return map;
	},
	/** Encodes the string to a valid XML attribute string.
	 * Refer to {@link Utl} for more XML utilities.
	 * @param String txt the text to encode
	 * @return String the encoded text.
	 * @since 8.0.0
	 */
	encodeXMLAttribute: (function () {

		// The following escape map implementation is referred from Underscore.js 1.8.3
		// which is under MIT license
		// List of HTML entities for escaping.
		var escapeMap = {
				'"': '&quot;',
				"'": '&#x27;',
				'`': '&#x60;'
			},
			// Functions for escaping and unescaping strings to/from HTML interpolation.
			escaper = function (match): string {
				return escapeMap[match];
			},
			// Regexes for identifying a key that needs to be escaped
			source = '(?:"|\'|`)',
			testRegexp = RegExp(source),
			replaceRegexp = RegExp(source, 'g');

		function _encodeXML0(string): string {
			return testRegexp.test(string) ? string.replace(replaceRegexp, escaper) : string;
		}

		return function (txt: string): string {
			txt = txt != null ? String(txt) : '';
			return _encodeXML0(txt);
		};
	})(),
	/** Encodes the string to a valid XML string.
	 * Refer to {@link Utl} for more XML utilities.
	 * @param String txt the text to encode
	 * @param Map opts [optional] the options. Allowd value:
	 * <ul>
	 * <li>pre - whether to replace whitespace with &amp;nbsp;</li>
	 * <li>multiline - whether to replace linefeed with &lt;br/&gt;</li>
	 * <li>maxlength - the maximal allowed length of the text</li>
	 * </ul>
	 * @return String the encoded text.
	 */
	encodeXML: (function () {

		// The following escape map implementation is referred from Underscore.js 1.8.3
		// which is under MIT license
		// List of HTML entities for escaping.
		var escapeMap = {
				'&': '&amp;',
				'<': '&lt;',
				'>': '&gt;',
				'"': '&quot;',
				"'": '&#x27;',
				'`': '&#x60;'
			},
			// Functions for escaping and unescaping strings to/from HTML interpolation.
			escaper = function (match): string {
				return escapeMap[match];
			},
			// Regexes for identifying a key that needs to be escaped
			source = '(?:&|<|>|"|\'|`)',
			testRegexp = RegExp(source),
			replaceRegexp = RegExp(source, 'g');

		function _encodeXML0(string): string {
			return testRegexp.test(string) ? string.replace(replaceRegexp, escaper) : string;
		}

		return function (txt: string, opts?: EncodeXmlOptions): string {
			txt = txt != null ? String(txt) : '';

			if (!opts) // speed up the replacement.
				return _encodeXML0(txt);

			var tl = txt.length,
				pre = opts && opts.pre,
				multiline = pre || (opts && opts.multiline),
				maxlength = opts ? opts.maxlength : 0;

			if (!multiline && maxlength && tl > maxlength) {
				var j = maxlength;
				while (j > 0 && txt.charAt(j - 1) == ' ')
					--j;
				opts.maxlength = 0; //no limit
				return zUtl.encodeXML(txt.substring(0, j) + '...', opts);
			}

			var out = '', k = 0, enc;
			if (multiline || pre) {
				for (let j = 0; j < tl; ++j) {
					var cc = txt.charAt(j);
					if (enc = _encs[cc]) {
						out += txt.substring(k, j) + '&' + enc + ';';
						k = j + 1;
					} else if (multiline && cc == '\n') {
						out += txt.substring(k, j) + '<br/>\n';
						k = j + 1;
					} else if (pre && (cc == ' ' || cc == '\t')) {
						out += txt.substring(k, j) + '&nbsp;';
						if (cc == '\t')
							out += '&nbsp;&nbsp;&nbsp;';
						k = j + 1;
					}
				}
			} else {
				// fixed B65-ZK-1836 that opt may be an empty object.
				return _encodeXML0(txt);
			}

			if (!k) return txt;
			if (k < tl)
				out += txt.substring(k);
			return out;
		};
	})(),
	/** Decodes the XML string into a normal string.
	 * For example, &amp;lt; is convert to &lt;
	 * @param String txt the text to decode
	 * @return String the decoded string
	 */
	decodeXML(txt: string): string {
		var out = '';
		if (!txt) return out;

		var k = 0, tl = txt.length;
		for (var j = 0; j < tl; ++j) {
			var cc = txt.charAt(j);
			if (cc == '&') {
				var l = txt.indexOf(';', j + 1);
				if (l >= 0) {
					var dec = txt.charAt(j + 1) == '#' ?
						String.fromCharCode(txt.charAt(j + 2).toLowerCase() == 'x' ?
							parseInt(txt.substring(j + 3, l), 16) :
							parseInt(txt.substring(j + 2, l), 10)) :
						_decs[txt.substring(j + 1, l)];
					if (dec) {
						out += txt.substring(k, j) + dec;
						k = (j = l) + 1;
					}
				}
			}
		}
		return !k ? txt :
			k < tl ? out + txt.substring(k) : out;
	},

	/** A shortcut of <code>' cellpadding="0" cellspacing="0" border="0"'</code>.
	 * @type String
	 */
	cellps0: ' cellpadding="0" cellspacing="0" border="0"',
	/** A shortcut of <code>'&lt;img style="height:0;width:0"/&gt;'</code>.
	 * @type String
	 */
	img0: '<img style="height:0;width:0" aria-hidden="true"/>',
	/** A shortcut of <code>'&lt;i style="height:0;width:0"/&gt;'</code>.
	 * @type String
	 */
	i0: '<i style="height:0;width:0"></i>',
	/** Returns today.
	 * @param boolean full if true, returns the full time,
	 * else only returns year, month, and day.
	 * If omitted, false is assumed
	 * @return Date
	 */
	/** Returns today.
	 * @param String fmt the time format, such as HH:mm:ss.SSS
	 * If a time element such as seconds not specified in the format, it will
	 * be considered as 0. For example, if the format is "HH:mm", then
	 * the returned object will be today, this hour and this minute, but
	 * the second and milliseconds will be zero.
	 * @return zk.DateImpl
	 * @since 5.0.6
	 */
	today(fmt: boolean | string | null, tz: string): DateImpl {
		var d = window.Dates.newInstance().tz(tz), hr = 0, min = 0, sec = 0, msec = 0;
		if (typeof fmt == 'string') {
			var fmt0 = fmt.toLowerCase();
			if (fmt0.indexOf('h') >= 0 || fmt0.indexOf('k') >= 0) hr = d.getHours();
			if (fmt.indexOf('m') >= 0) min = d.getMinutes();
			if (fmt.indexOf('s') >= 0) sec = d.getSeconds();
			if (fmt.indexOf('S') >= 0) msec = d.getMilliseconds();
		} else if (fmt)
			return d;
		return window.Dates.newInstance([d.getFullYear(), d.getMonth(), d.getDate(),
			hr, min, sec, msec], tz);
	},
	/** Returns if one is ancestor of the other.
	 * It assumes the object has either a method called <code>getParent</code>
	 * or a field called <code>parent</code>.
	 * A typical example is used to test the widgets ({@link Widget}).
	 *
	 * <p>Notice that, if you want to test DOM elements, please use
	 * {@link jq#isAncestor} instead.
	 *
	 * @param Object p the parent. This method return true if p is null
	 or p is the same as c
	 * @param Object c the child
	 * @return boolean
	 * @see jq#isAncestor
	 */
	isAncestor(p: Widget, c: Widget & {getParent?()}): boolean {
		if (!p) return true;
		for (; c; c = c.getParent ? c.getParent() : c.parent)
			if (p == c)
				return true;
		return false;
	},

	//progress//
	/** Creates a message box to indicate something is being processed
	 * @param String id the ID of the DOM element being created
	 * @param String msg the message to shown
	 * @param boolean mask whether to show sem-transparent mask to prevent
	 * the user from accessing it.
	 * @param String icon the CSS class used to shown an icon in the box.
	 * Ignored if not specified.
	 * @see #destroyProgressbox
	 */
	progressbox(id: string, msg: string, mask?: boolean, icon?: string | null, opts?: Partial<ProgressboxOptions>): void {
		if (mask && zk.Page.contained.length) {
			for (var c = zk.Page.contained.length, e = zk.Page.contained[--c]; e; e = zk.Page.contained[--c]) {
				if (!e._applyMask)
					e._applyMask = new zk.eff.Mask({
						id: e.uuid + '-mask',
						message: msg,
						anchor: e.$n()
					});
			}
			return;
		}

		if (opts && opts.busy) {
			zk.busy++;
			jq.focusOut(); //Bug 2912533
		}

		var x = jq.innerX(), y = jq.innerY(),
			style = ' style="left:' + x + 'px;top:' + y + 'px"',
			idtxt = id + '-t',
			idmsk = id + '-m',
			html = '<div id="' + id + '" role="alert"';
		if (mask)
			html += '><div id="' + idmsk + '" class="z-modal-mask"' + style + '></div';
		html += '><div id="' + idtxt + '" class="z-loading"' + style
			+ '><div class="z-loading-indicator"><span class="z-loading-icon"></span> '
			+ msg + '</div></div>';
		if (icon)
			html += '<div class="' + icon + '"></div>';
		jq(document.body).append(html + '</div>');

		var $n = jq(id, zk),
			n = $n[0],
			$txt = jq(idtxt, zk),
			txt = $txt[0],
			st = txt.style;
		if (mask) {
			// old IE will get the auto value by default.
			var zIndex: string | number = $txt.css('z-index');
			if (zIndex == 'auto' || typeof zIndex === 'string')
				zIndex = 1;
			n['z_mask'] = new zk.eff.FullMask!({
				mask: jq(idmsk, zk)[0],
				zIndex: zIndex - 1
			});
			jq('html').on('keydown', zk.$void);
		}

		if (mask && $txt.length) { //center
			st.left = jq.px((jq.innerWidth() - txt.offsetWidth) / 2 + x);
			st.top = jq.px((jq.innerHeight() - txt.offsetHeight) / 2 + y);
		} else {
			var pos = zk.progPos;
			if (pos) {
				var left,
					top,
					width = jq.innerWidth(),
					height = jq.innerHeight(),
					wdgap = width - zk(txt).offsetWidth(),
					hghgap = height - zk(txt).offsetHeight();

				if (pos.indexOf('mouse') >= 0) {
					var offset = zk.currentPointer;
					left = offset[0] + 10;
					top = offset[1] + 10;
				} else {
					if (pos.indexOf('left') >= 0) left = x;
					else if (pos.indexOf('right') >= 0)	left = x + wdgap - 1;
					else if (pos.indexOf('center') >= 0) left = x + wdgap / 2;
					else left = 0;

					if (pos.indexOf('top') >= 0) top = y;
					else if (pos.indexOf('bottom') >= 0) top = y + hghgap - 1;
					else if (pos.indexOf('center') >= 0) top = y + hghgap / 2;
					else top = 0;

					left = left < x ? x : left;
					top = top < y ? y : top;
				}
				st.left = jq.px(left);
				st.top = jq.px(top);
			}
		}

		$n.zk.cleanVisibility();
	},
	/** Removes the message box created by {@link #progressbox}.
	 * @param String id the ID of the DOM element of the message box
	 */
	destroyProgressbox(id: string, opts?: Partial<ProgressboxOptions>): void {
		if (opts && opts.busy && --zk.busy < 0)
			zk.busy = 0;
		var $n = jq(id, zk), n;
		if ($n.length) {
			if (n = $n[0]['z_mask']) n.destroy();
			$n.remove();
			jq('html').off('keydown', zk.$void);
		}

		for (var c = zk.Page.contained.length, e = zk.Page.contained[--c]; e; e = zk.Page.contained[--c])
			if (e._applyMask) {
				e._applyMask.destroy();
				e._applyMask = null;
			}
	},

	//HTTP//
	/** Navigates to the specified URL.
	 * @param String url the URL to go to
	 * @param Map opts [optional] the options. Allowed values:
	 * <ul>
	 * <li>target - the name of the target browser window. The same browswer
	 * window is assumed if omitted. You can use any value allowed in
	 * the target attribute of the HTML FORM tag, such as _self, _blank,
	 * _parent and _top.</li>
	 * <li>overwrite - whether load a new page in the current browser window.
	 * If true, the new page replaces the previous page's position in the history list.</li>
	 * </ul>
	 */
	go(url: string, opts?: Partial<GoOptions>): void {
		opts = opts || {};
		if (opts.target) {
			open(url, opts.target);
		} else if (opts.overwrite) {
			location.replace(url ? url : location.href);
		} else {
			if (url) {
				location.href = url;

				var j = url.indexOf('#');
				//bug 3363687, only if '#" exist, has to reload()
				if (j < 0)
					return;

				var	un = j >= 0 ? url.substring(0, j) : url,
					pn = _pathname(location.href);

				j = pn.indexOf('#');
				if (j >= 0) pn = pn.substring(0, j);
				if (pn != un)
					return;
				//fall thru (bug 2882149)
			}
			location.reload();
		}
	},

	/** Returns all descendant frames of the given window.
	 * <p>To retrieve all, invoke <code>zUtl.frames(top)</code>.
	 * Notice: w is included in the returned array.
	 * If you want to exclude it, invoke <code>zUtl.frames(w).$remove(w)</code>.
	 * @param Window w the browser window
	 * @return Array
	 * @since 5.0.4
	 */
	frames(w: Window): Window[] {
		var ary: Window[] = [];
		_frames(ary, w);
		return ary;
	},

	/** Converts an integer array to a string.
	 * @param int[] ary the integer array to convert.
	 * If null, an empty string is returned.
	 * @return String
	 * @see #stringToInts
	 * @deprecated Use {@code [].join()} instead.
	 */
	intsToString(ary: number[] | null): string {
		if (!ary) return '';
		return ary.join();
	},
	/** Converts a string separated by comma to an array of integers.
	 * @see #intsToString
	 * @param String text the string to convert.
	 * If null, null is returned.
	 * @param int defaultValue the default value used if the value
	 * is not specified. For example, zUtl.stringToInts("1,,3", 2) returns [1, 2, 3].
	 * @return int[]
	 */
	stringToInts(text: string | null, defaultValue: number): number[] | null {
		if (text == null)
			return null;

		var list: number[] = [];
		for (var j = 0; ;) {
			var k = text.indexOf(',', j),
				s = (k >= 0 ? text.substring(j, k) : text.substring(j)).trim();
			if (s.length == 0) {
				if (k < 0) break;
				list.push(defaultValue);
			} else
				list.push(zk.parseInt(s));

			if (k < 0) break;
			j = k + 1;
		}
		return list;
	},
	/** Converts a map to a string
	 * @see #intsToString
	 * @param Map map the map to convert
	 * @param String assign the symbol for assignment. If omitted, '=' is assumed.
	 * @param String separator the symbol for separator. If omitted, ',' is assumed.
	 * @return String
	 */
	mapToString(map: Record<string, string>, assign?: string, separator?: string): string {
		assign = assign || '=';
		separator = separator || ' ';
		var out: string[] = [];
		for (var v in map)
			out.push(separator, v, assign, map[v]);
		out[0] = '';
		return out.join('');
	},
	/** Appends an attribute.
	 * Notice that the attribute won't be appended if val is empty or false.
	 * In other words, it is equivalent to<br/>
	 * <code>val ? ' ' + nm + '="' + val + '"': ""</code>.
	 * <p>If you want to generate the attribute no matter what val is, use
	 * {@link #appendAttr(String, Object, boolean)}.
	 * @param String nm the name of the attribute
	 * @param Object val the value of the attribute
	 * @since 5.0.3
	 */
	/** Appends an attribute.
	 * Notice that the attribute won't be appended.
	 * @param String nm the name of the attribute
	 * @param Object val the value of the attribute
	 * @param boolean force whether to append attribute no matter what value it is.
	 * If false (or omitted), it is the same as {@link #appendAttr(String, Object)}.
	 * @since 5.0.3
	 */
	appendAttr(nm: string, val: unknown, force?: boolean): string {
		return val || force ? ' ' + nm + '="' + val + '"' : '';
	},
	/** Fires beforeSize, onFitSize, onSize and afterSize
	 * @param Widget wgt the widget which the zWatch event will be fired against.
	 * @param int bfsz the beforeSize mode:
	 * <ul>
	 * <li>0 (null/undefined/false): beforeSize sent normally.</li>
	 * <li>-1: beforeSize won't be sent.</li>
	 * <li>1: beforeSize will be sent with an additional cleanup option,
	 * which will clean up the cached minimal size (if flex=min).</li>
	 * </ul>
	 * @since 5.0.8
	 */
	fireSized(wgt: Widget, bfsz?: number): void {
		// ignore delayed rerendering case, like Bug ZK-2281
		if (wgt.desktop) {
			if (zUtl.isImageLoading() || zk.clientinfo) {
				setTimeout(() => {
					return this.fireSized(wgt, bfsz);
				}, 20);
				return;
			}
			wgt = _onSizeTarget(wgt);
			if (!(bfsz && bfsz < 0)) { //don't use >= (because bfsz might be undefined)
				zWatch.fireDown('_beforeSizeForRead', wgt);
				zWatch.fireDown('beforeSize', wgt, undefined, bfsz && bfsz > 0);
			}
			zWatch.fireDown('onFitSize', wgt, {reverse: true});
			zWatch.fireDown('onSize', wgt);
			zWatch.fireDown('afterSize', wgt);
		}
	},
	/** Fires beforeSize, onShow, onFitSize, onSize and afterSize
	 * @param Widget wgt the widget which the zWatch event will be fired against.
	 * @param int bfsz the beforeSize mode:
	 * <ul>
	 * <li>0 (null/undefined/false): beforeSize sent normally.</li>
	 * <li>-1: beforeSize won't be sent.</li>
	 * <li>1: beforeSize will be sent with an additional cleanup option,
	 * which will clean up the cached minimal size (if flex=min).</li>
	 * </ul>
	 * @since 5.0.8
	 */
	fireShown(wgt: Widget, bfsz?: number): void {
		zWatch.fireDown('onShow', wgt);
		zUtl.fireSized(wgt, bfsz);
	},
	/**
	 * Loads an image before ZK client engine to calculate the widget's layout.
	 * @param String url the loading image's localation
	 * @since 6.0.0
	 */
	loadImage(url: string): void {
		if (!_imgMap[url]) {
			_imgMap[url] = true;
			_loadImage(url);
		}
	},
	/**
	 * Checks whether all the loading images are finish.
	 * @see #loadImage
	 * @since 6.0.0
	 */
	isImageLoading(): boolean {
		for (var _n in _imgMap)
			return true;
		return false;
	},
	/**
	 * Get week numbers of year for a specific date
	 * @since 8.5.1
	 */
	getWeekOfYear(year: number, month: number, date: number, firstDayOfWeek: number,
				  minimalDaysInFirstWeek: number): number {
		var d = window.Dates.newInstance([year, month, date, 0, 0, 0, 0], 'UTC'),
			day = d.getDay();
		d.setDate(date - minimalDaysInFirstWeek + firstDayOfWeek - (firstDayOfWeek > day ? day : day - 7));
		var yearStart = window.Dates.newInstance([d.getFullYear(), 0, 1], 'UTC');
		return Math.ceil(((d.valueOf() - yearStart.valueOf()) / 86400000 + 1) / 7);
	},
	/**
	 * Converts the dataURL to Blob object.
	 * This function is not supported in IE9 and below.
	 */
	convertDataURLtoBlob(dataURL: string): Blob {
		var byteString = window.atob(dataURL.split(',')[1]),
			mimeString = dataURL.split(',')[0].split(':')[1].split(';')[0],
			len = byteString.length,
			arrayBuffer = new ArrayBuffer(len),
			uint8Array = new Uint8Array(arrayBuffer);

		for (var i = 0; i < len; i++) {
			uint8Array[i] = byteString.charCodeAt(i);
		}

		return new Blob([arrayBuffer], {type: mimeString});
	},
	/**
	 * Returns the ratio of the resolution in physical pixels to the resolution in CSS pixels for the current display device.
	 * For more information, please visit https://developer.mozilla.org/en-US/docs/Web/API/Window/devicePixelRatio
	 * @return double the devicePixelRatio
	 * @since 8.6.0
	 */
	getDevicePixelRatio(): number {
		return window.devicePixelRatio || window.screen['deviceXDPI'] / window.screen['logicalXDPI'];
	},
	/**
	 * Returns the Promise whose fulfillment handler receives a MediaStream object when the requested media has successfully been obtained.
	 * Note: this function may returns a Promise that is rejected, if this browser not support getUserMedia.
	 * For more information, please visit https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia
	 *
	 * @param String constraints a constraints object specifying the types of media to request
	 * @return Promise
	 * @since 8.6.1
	 */
	// eslint-disable-next-line no-undef
	getUserMedia(constraints: MediaStreamConstraints): Promise<MediaStream> {
		var polyfillGUM = function (constraints?, success?, error?): Promise<MediaStream> {
			var getUserMedia = navigator['getUserMedia'] || navigator['webkitGetUserMedia'] ||
				navigator['mozGetUserMedia'] || navigator['msGetUserMedia'] ||
				navigator['oGetUserMedia'];
			if (!getUserMedia)
				return Promise.reject(new Error('Cannot polyfill getUserMedia'));
			return new Promise(function (success, error) {
				getUserMedia.call(navigator, constraints, success, error);
			});
		};

		// eslint-disable-next-line @typescript-eslint/ban-ts-comment
		// @ts-ignore: assign to read only property(mediaDevices) for polyfill
		if (navigator.mediaDevices === undefined) navigator['mediaDevices'] = {};
		if (navigator.mediaDevices.getUserMedia === undefined) navigator.mediaDevices.getUserMedia = polyfillGUM;
		return navigator.mediaDevices.getUserMedia(constraints);
	},
	/**
	 * Creates and returns a new, throttled version of the passed function, that,
	 * when invoked repeatedly, will only actually call the original function at most once per every wait milliseconds.
	 * Useful for rate-limiting events that occur faster than you can keep up with.
	 *
	 * Copied from underscore.js, MIT license.
	 *
	 * @param Function func the passed function
	 * @param int wait wait milliseconds
	 * @return Function a new, throttled version of the passed function
	 * @since 9.6.0
	 */
	throttle<T, A extends unknown[], R>(func: (this: T, ...args: A) => R, wait: number):
				(this: T, ...args: A) => R {
		var timeout: number | null, context, args, result,
			previous = 0,
			later = function (): void {
				previous = Date.now();
				timeout = null;
				result = func.apply(context, args);
				if (!timeout) context = args = null;
			};

		return function () {
			var now = Date.now(),
				remaining = wait - (now - previous);
			// eslint-disable-next-line @typescript-eslint/ban-ts-comment
			// @ts-ignore
			context = this;
			args = arguments;
			if (remaining <= 0 || remaining > wait) {
				if (timeout) {
					clearTimeout(timeout);
					timeout = null;
				}
				previous = now;
				result = func.apply(context, args);
				if (!timeout) context = args = null;
			} else if (!timeout) {
				timeout = window.setTimeout(later, remaining);
			}
			return result;
		};
	},
	/**
	 * Creates and returns a new debounced version of the passed function
	 * which will postpone its execution until after wait milliseconds have elapsed since the last time it was invoked.
	 * Useful for implementing behavior that should only happen after the input has stopped arriving.
	 *
	 * Copied from debounce, MIT license.
	 *
	 * @param Function func the passed function
	 * @param int wait wait milliseconds
	 * @param boolean immediate trigger the function on the leading instead of the trailing edge of the wait interval
	 * @return Function a new debounced version of the passed function
	 * @since 9.6.0
	 */
	debounce<T, A extends unknown[], R>(func: (this: T, ...args: A) => R, wait: number,
									immediate?: boolean): (this: T, ...args: A) => R {
		var timeout, args, context, timestamp, result;
		if (null == wait) wait = 100;

		function later (): void {
			var last = Date.now() - timestamp;

			if (last < wait && last >= 0) {
				timeout = setTimeout(later, wait - last);
			} else {
				timeout = null;
				if (!immediate) {
					result = func.apply(context, args);
					context = args = null;
				}
			}
		}

		var debounced = function (this): any { // eslint-disable-line @typescript-eslint/no-explicit-any
			context = this;
			args = arguments;
			timestamp = Date.now();
			var callNow = immediate && !timeout;
			if (!timeout) timeout = setTimeout(later, wait);
			if (callNow) {
				result = func.apply(context, args);
				context = args = null;
			}
			return result;
		};

		return debounced;
	},
	/**
	 * Check if the two objects has the same value
	 * ref: undersore isEqual
	 * @param a first object
	 * @param b second object
	 * @return boolean the two object is the same or not
	 * @since 10.0.0
	 */
	isEqualObject(a: unknown, b: unknown): boolean {
		// Identical objects are equal. `0 === -0`, but they aren't identical.
		// See the [Harmony `egal` proposal](http://wiki.ecmascript.org/doku.php?id=harmony:egal).
		if (a === b) return a !== 0 || 1 / (a as number) === 1 / (b as number);
		// `null` or `undefined` only equal to itself (strict comparison).
		if (a == null || b == null) return false;
		// `NaN`s are equivalent, but non-reflexive.
		if (a !== a) return b !== b;
		// Exhaust primitive checks
		let type = typeof a;
		if (type !== 'function' && type !== 'object' && typeof b != 'object') return false;

		const keys = Object.keys(a as Record<string, unknown>);
		if (Object.keys(b as Record<string, unknown>).length !== keys.length) {
			return false;
		}
		for (const key of keys) {
			if (!Object.prototype.propertyIsEnumerable.call(b, key) ||
				!zUtl.isEqualObject((a as Record<string, unknown>)[key], (b as Record<string, unknown>)[key])) {
				return false;
			}
		}
		return true;
	}
};

var _imgMap = {};
function _loadImage(url): void {
	var img = new Image(),
		f = function (): void {
			delete _imgMap[url];
		};
	img.onerror = img.onload = f;
	img.src = url;
}
