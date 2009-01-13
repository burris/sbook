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

#import "DefaultSwitchSetter.h"
#import "PreferencePanel.h"
#import "SBookController.h"
#import "Person.h"
#import "SList.h"
#import "defines.h"

@implementation PreferencePanel

+ (void)initialize
{
}

- (void)installPreference:(NSString *)title view:(NSView *)aView
{
    NSTabViewItem *tvi = [[[NSTabViewItem alloc] init] autorelease];

    [tvi setLabel:title];
    [tvi setView:aView];
    [tv  addTabViewItem:tvi];
}


- (void)add:(NSView *)aView
{
    if(!aView) return;
    [self installPreference:[aView toolTip] view:aView];
}



-(void) awakeFromNib
{
    while([tv numberOfTabViewItems]>0){
	[tv removeTabViewItem:[tv tabViewItemAtIndex:0]];
    }

    [self add:view0];
    [self add:view1];
    [self add:view2];
    [self add:view3];
    [self add:view4];
    [self add:view5];
    [self add:view6];
    [self add:view7];
    [self add:view8];
    [self add:view9];


    [launch_openFileBrowser setDelegate:self];

    setDefault(gen_checkNewVersions,DEF_CHECK_ON_LAUNCH);
    setDefault(gen_insertHelp,DEF_SHOW_INTRO_TEXT);
    setDefault(gen_autosaveInterval,DEF_AUTOSAVE_INTERVAL);
    setDefault(gen_autocheckInterval,DEF_AUTOCHECK_INTERVAL);
    setDefault(gen_enableAutosave,DEF_AUTOSAVE_ENABLE);
    setDefault(gen_enableAutocheck,DEF_AUTOCHECK_ENABLE);
    setDefault(gen_lastnameFirstname,DEF_LAST_FIRST);
    setDefault(get_autoCreateOnBlankClick,DEF_AUTO_CREATE_ON_BLANK_CLICK);
    setDefault(view_highlightSearchResults,DEF_HIGHLIGHT_SEARCH_RESULTS);

    setAutoEnable(gen_enableAutosave,gen_autosaveLabel);
    setAutoEnable(gen_enableAutosave,gen_autosaveInterval);
    setAutoEnable(gen_enableAutocheck,gen_autocheckLabel);
    setAutoEnable(gen_enableAutocheck,gen_autocheckInterval);

    setDefault(gen_maxEntriesDisplay,DEF_MAX_ENTRIES_DISPLAYED);
    setDefault(gen_showHorizontalScroller,DEF_SHOW_HORIZONTAL_SCROLLER);
    setDefault(gen_removeColorFromPastedText,DEF_REMOVE_COLOR_FROM_PASTED_TEXT);
    
    setDefault(launch_openOnActivate,DEF_OPEN_ON_ACTIVATE);

    [self reloadFromDefaults];			// get current values
}

- (void)reloadFromDefaults
{
    [launch_openFileBrowser reloadColumn:0];
}


/****************************************************************
 ** BROWSER DELEGATES
 ****************************************************************/

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:DEF_OPEN_ON_LAUNCH] count];
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column
{
    NSArray *array = [[NSUserDefaults standardUserDefaults]
			 objectForKey:DEF_OPEN_ON_LAUNCH];

    if((unsigned)row < [array count]){
	[cell setLeaf:YES];
	[cell setStringValue:[array objectAtIndex:row]];
	[cell setLoaded:YES];
    }
}





@end
