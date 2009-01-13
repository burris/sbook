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
#import "PlugInController.h"

@interface PreferencePanel : NSPanel <PreferencePanelProtocol> 
{
    IBOutlet NSTabView *tv;

    /* launching */
    IBOutlet NSView * view0;
    IBOutlet NSView * view1;
    IBOutlet NSView * view2;
    IBOutlet NSView * view3;
    IBOutlet NSView * view4;
    IBOutlet NSView * view5;
    IBOutlet NSView * view6;
    IBOutlet NSView * view7;
    IBOutlet NSView * view8;
    IBOutlet NSView * view9;
    
    /* General */
    IBOutlet id gen_maxEntriesDisplay;
    IBOutlet id gen_checkNewVersions;
    IBOutlet id gen_insertHelp;
    IBOutlet id gen_enableAutosave;
    IBOutlet id gen_enableAutocheck;
    IBOutlet id gen_autosaveInterval;
    IBOutlet id gen_autosaveLabel;
    IBOutlet id gen_autocheckInterval;
    IBOutlet id gen_autocheckLabel;
    IBOutlet id gen_showHorizontalScroller;
    IBOutlet id gen_removeColorFromPastedText;
    IBOutlet id get_autoCreateOnBlankClick;

    /* View */
    IBOutlet id gen_lastnameFirstname;
    IBOutlet id view_highlightSearchResults;
    
    /* Launch */
    IBOutlet NSBrowser *launch_openFileBrowser;
    IBOutlet NSButton *launch_openOnActivate;

}

- (void)add:(NSView *)aView;
- (void)installPreference:(NSString *)title view:(NSView *)aView;

@end
