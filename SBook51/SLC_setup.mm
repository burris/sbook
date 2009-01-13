/*
 * SLC_setup.m:
 *
 * Set up the SLC Stuff.
 */

#import "SLC.h"
#import "Person.h"
#import "SList.h"
#import "metaphone.h"
#import "SBookController.h"
#import "tools.h"
#import "defines.h"
#import "SBookIconView.h"
#import "SBookText.h"
#import "PassphrasePanel.h"
#import "ProgressPanel.h"
#import "ExportingTableView.h"
#import "DefaultSwitchSetter.h"

#import <unistd.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <fcntl.h>
#import <dirent.h>

extern int debug;

static const char *SBOOK_INTRO[] = {
"1. Welcome to SBook!\n"
"SBook is a free-format, AI-based contact management system.\n\nInformation in SBook is "
"arranged in entries, such as the entry that you are now looking at.\n\nYou can search for "
"an entry by typing a few letters into the search field at the top of this window. Select an "
"entry by clicking its name in the SBook list, displayed above. You can use Command-N to create a new entry.\n",

"2. Working with SBook entries\n\n"
"SBook automatically recognizes names, companies, addresses, phone numbers, email addresses, URLs and other information that is stored in your address book. It displays small icons "
"in the left hand margin to tell you what it has found. You can click these icons to make "
"SBook perform special functions.\n\n"
"Try it below:\n\n"
"77 Massachusetts Ave\n"
"Cambridge, MA 02138\n"
"main number:\n"
"617-253-1000\n"
"info@mit.edu\n"
"http://www.mit.edu\n",

"3. Doing more with SBook\n\n"
"SBook is designed to work the way you expect. Entries can be copied-and-pasted or dragged "
"from the SBook list to other SBook windows or even other applications. "
"Shift-click on icons to copy their contents to the clipboard; you can also drag them.\n"
"\n\n"
"Check out the SBook Preferences and 'Get Info...' panels for additional settings and controls.\n\n"
"Have fun and send your suggestions to:\nsbook-suggestions@nitroba.com\n",

0};

@implementation SLC(setup)

/****************************************************************
 ** INITIALIZATION
 ****************************************************************/

+ (const char **)intro_text
{
    return SBOOK_INTRO;
}




- (void)displayIfNewVersion
{
    NSString *nva = [AppDelegate newVersionAvailable];

    if(nva){
	NSMutableString *str = [NSMutableString stringWithString:@"SBook5 "];
	[str appendString:nva];
	[str appendString:@" is now available"];
	[self setStatus:str];

	[str appendString:@"\nThis is version "];
	[str appendString:[AppDelegate appVersion]];
	[self	setTextStatus:str];
    }
    else {
	[self	setTextStatus:@""];
    }
}

- (void)setHorizontalScrollerFromDefaults
{
    if(!entryText) return;
    if([[defaults objectForKey:DEF_SHOW_HORIZONTAL_SCROLLER] intValue]){
	[entryTextScroller setHasHorizontalScroller:YES];
	[entryText setHorizontallyResizable:YES];
    }
    else {
	[entryTextScroller setHasHorizontalScroller:NO];
    }
}

- (void)setSplitViewDirectionFromDoc
{
    BOOL isVertical = [splitView isVertical] != 0;
    BOOL shouldBeVertical = [doc queryFlag:SLIST_SPLIT_VERTICAL_FLAG] != 0;

    if(isVertical != shouldBeVertical){
	[splitView setVertical: [doc queryFlag:SLIST_SPLIT_VERTICAL_FLAG]];
	[splitView setNeedsDisplay:YES];
    }
}

- (void)sliderPositionSetup
{
    NSMutableDictionary *appDefs= [NSMutableDictionary dictionary];

    [sliderPositionAutosaveName release];
    sliderPositionAutosaveName =
	[NSString stringWithFormat:DEF_SPLITVIEW_LOCATION,[self fileName]];
    [sliderPositionAutosaveName retain];

    [appDefs setObject:@"0" forKey:sliderPositionAutosaveName];
    [defaults registerDefaults:appDefs];
}



/* Don't use awakeFromNib; it will cause problems when sheets are loaded */
- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    /* Set up the entry area */
    [entryText	setEditable:NO];	
    [entryText  setRichText:YES];
    [entryText  setImportsGraphics:YES];
    [entryText  setDelegate:self];

    [forwardButton setTarget:history];
    [forwardButton setAction:@selector(forward:)];

    [backButton setTarget:history];
    [backButton setAction:@selector(back:)];

    [self setSplitViewDirectionFromDoc];
    [self setHorizontalScrollerFromDefaults];
    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(setHorizontalScrollerFromDefaults)
					  name:DEF_SHOW_HORIZONTAL_SCROLLER
					  object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(scheduleTimers)
					  name:DEF_AUTOCHECK_ENABLE
					  object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(scheduleTimers)
					  name:DEF_AUTOSAVE_ENABLE
					  object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(windowWillClose:)
					  name:NSWindowWillCloseNotification
					  object:[self window]];

    /* Tell us if there if the splitview moves */
    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(splitViewMoved:)
					  name:NSSplitViewDidResizeSubviewsNotification
					  object:splitView];

    

    /* redisplay the person list if this preference changes */
    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(redisplayPersonList)
					  name:DEF_LAST_FIRST
					  object:nil];

    /* remove views */
    [fieldEditor	retain];	// I now have the copy of it
    [fieldEditor	setRichText:NO];
    [fieldEditor	removeFromSuperview];
    
    [lockButton		setTarget:nil];

    [nameTable setVerticalMotionCanBeginDrag:NO];

    [encryptButton setTarget:nil];
    [encryptButton setAction:@selector(togglePrivateEntry:)];

    [self displayPersonList:NO];

    /* Hack! If there is just one person, display it in the entryTable
     * this shoudl be done by displayPersonList, but for some reason, it isn't.
     */
    if([visibleList count]==1){
	[self		displayPersonEntry:displayedPerson append:NO];
	[entryText	setRtfdData:[displayedPerson rtfdData]];
	[self		reparse];
    }

    if([doc numPeople]){
	[self	setStatus:[self entryCountString:[doc numPeople]]];
    }
    else{
	[self	setupEmptyDocument];
    }

    /* Set up autosave/autoecheck */
    [self scheduleTimers];

    /* Check for a new version */
    [self displayIfNewVersion];


    /* Set up the toolbar */
    //[self setTextStatus:@""];
    //[self setupToolbar];

    if([self fileName]){		// if we were loaded from a file
	id    obj;
	// Store frame in the defaults, since each user can have their own
	// favorite position
	[windowController setWindowFrameAutosaveName:[self fileName]]; 
	[windowController setShouldCascadeWindows:NO]; // because it will autosave

	// And grab the position for the slider
	[self sliderPositionSetup];
	obj =[defaults objectForKey:sliderPositionAutosaveName]; 
	if(obj && [obj respondsToSelector:@selector(floatValue)]){
	    float v = [obj floatValue];
	    if(v>0){
		[splitView setPosition:v];
	    }
	}
    }
    [searchModePopup selectItemWithTag:[doc searchMode]];
    searchFieldCell = [searchCell cell];
    {
	NSMenu *menu = [[NSMenu alloc] init];
	NSMenuItem *item = [[NSMenuItem alloc] init];

	[item setTitle:@"Simson"];
	[item setTag:NSSearchFieldRecentsTitleMenuItemTag];
	[menu addItem:item];

	
	//[searchFieldCell setSearchMenuTemplate:menu];
	[searchFieldCell setMaximumRecents:10];
	[searchFieldCell setRecentSearches:[NSArray arrayWithObjects:@"one",@"two",@"three",0]];
    }
}


/****************************************************************
 ** SPECIAL
 ****************************************************************/
- (void)setupEmptyDocument
{
    int i;
    int last;

    if([[defaults objectForKey:DEF_SHOW_INTRO_TEXT] intValue]){
	for(i=0;SBOOK_INTRO[i];i++){
	    last = i;
	}
	
	for(i=last;i>=0;i--){
	    Person *per  = [[[Person alloc] init] autorelease];
	    [per setAsciiData:[NSData dataWithUTF8String:SBOOK_INTRO[i]]
		 releaseRtfdData:YES andUpdateMtime:YES];
	    [per setFlag:ENTRY_PRIVATE_FLAG toValue:YES]; // prevent sync
	    [self addAndDisplayPerson:per];
	}
	[self updateChangeCount:NSChangeCleared]; // don't say that the book has cleared.
    }
	
    [self setStatus:@"Welcome to SBook!"];
}

 

@end

