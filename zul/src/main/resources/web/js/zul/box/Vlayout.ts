/* Vlayout.js

	Purpose:

	Description:

	History:
		Fri Aug  6 12:37:19 TST 2010, Created by jumperchen

Copyright (C) 2010 Potix Corporation. All Rights Reserved.

This program is distributed under GPL Version 3.0 in the hope that
it will be useful, but WITHOUT ANY WARRANTY.
*/
/**
 * A vertical layout.
 * <p>Default {@link #getZclass}: z-vlayout.
 * @since 5.0.4
 */
export class Vlayout extends zul.box.Layout {
    protected override isVertical_(): boolean {
		return true;
	}

    protected override getFlexDirection_(): string {
		return 'column';
	}
}
zul.box.Vlayout = zk.regClass(Vlayout);