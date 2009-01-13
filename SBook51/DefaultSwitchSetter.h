/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law.
 *
 */

#import <Cocoa/Cocoa.h>
#import "SBookController.h"

@interface DefaultSwitchSetter:NSObject
{
    NSString	*key;			// defaults key
    int		type;
    NSMutableArray	*autoEnableList;	// objects we automatically enable
    NSMutableArray	*autoDisableList;
    int		lastIntValue;		// integer version of last value
    id		control;		/* the control being watched */
    SEL		oldAction;		// from NIB
    id		oldTarget;		// from NIB
}
+ objectWatching:control;
+ (void)setDefaultFor:obj key:(NSString *)key;
- initKey:(NSString *)key control:aControl value:(NSString *)val;
- control;				// watched control
- (void)setAutoEnable:(id)control;		// control is automatically enabled when this is set non-null
- (void)setAutoDisable:control;		// control is automatically disabled when this is set non-null
- (void)setLastIntValue:(int)aValue;
//- setSwitcher:aView;
- (void)changed;
- (IBAction)changed:sender;
@end

/*
 * Macros:
 *
 *	These macros are for setting up a preference panel.
 *	They create instances of the DefaultSwitchSetter class, automatically
 *	set the UI object from the defaults database, and wire up the UI
 *	object so that it points at the instance created so the default
 *	database gets automatically updated.
 *
 *	These are seperate functions now, but they could just as easily
 *	be one function that switches on the class of the id passed in...
 */

static id inline DSSClass() { return [[NSApp delegate] DefaultSwitchSetterClass];}

static void inline setDefault(id obj,id key) {
    if(obj)[DSSClass() setDefaultFor:obj key:key];
}

static void inline setAutoEnable(id watched,id aControl){
    [[DSSClass() objectWatching:watched] setAutoEnable:aControl];
}

static void inline setAutoDisable(id watched,id aControl){
    [[DSSClass() objectWatching:watched] setAutoDisable:aControl];
}

#define defaults ([NSUserDefaults standardUserDefaults])
