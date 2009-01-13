/* SLC.h:
 * the main document interface.
 */

#import <Cocoa/Cocoa.h>
#import "Person.h"			// brings in slib
#import "SLCProtocol.h"
#import "IconClickingProtocol.h"


#define IMPORT_OMIT_DUPLICATES 0x0001
#define IMPORT_REPLACE_UPDATED 0x0002


@class SBookIconView,SBookText,SListMatrix;
@class ExportFileInfoView,RangePanel,LabelMaker;
@class ExportingTableView;
@class ProgressPanel;
@class History;
@class SList;
@interface SLC : NSDocument <SLCProtocol>
{
    /* objects on the window */
    IBOutlet NSText		*fieldEditor;
    IBOutlet id	statusCell;
    IBOutlet NSTextField	*searchCell;
    IBOutlet NSSearchFieldCell  *searchFieldCell;
    IBOutlet NSSplitView	*splitView;
    IBOutlet id	searchModePopup;
    IBOutlet ExportingTableView	*nameTable;
    IBOutlet SBookIconView	*iconView;
    IBOutlet SBookText *entryText;
    IBOutlet id	entryTextScroller;
    IBOutlet id	exportWell;		/* if present */
    IBOutlet id	lockButton;		/* where we display if we are locked. */
    IBOutlet id	encryptButton;
    IBOutlet id	textStatusCell;	
    IBOutlet ProgressPanel *progressPanel; // My own progress Panel

    IBOutlet ExportFileInfoView *exportFileInfoView;	// accessory view for file export
    IBOutlet NSButton *removeExistingvCardsButton;
    IBOutlet RangePanel	*rangePanel;


    IBOutlet NSButton *openFileAutomatically;

    /* History support */
    IBOutlet NSButtonCell *backButton;
    IBOutlet NSButtonCell *forwardButton;
    History	*history;

    /* For delayed export */
    NSString	*vcardDir;
    BOOL	removeExistingvCards;

    /* Autosave/Autocheck timers */
    NSTimer	*autosaveTimer;
    NSTimer	*autocheckTimer;
    NSString	*fileChangeString;	// keeps track if file has changed

    /* Accessory view for saving */
    NSDictionary	*saveInfo;
    
    NSArray	*duplicates;		// for removing duplicates

    /* other objects */
    NSMutableArray *visibleList;	// people currently displayed in the NSTableView (top)
    Person	*displayedPerson;	// person being displayed in NSTextView (bottom) if just one
    int		numDisplayedPeople;	// number of people in entry text
    int		copyCutCount;		// number copy or cut by last operation

    /* filtering - display just people or companies */
    BOOL	showPeople;
    BOOL	showCompanies;
    int		numFiltered;	

    /* state variables */
    BOOL	textChanged;		/* and needs to be saved */
    BOOL	reverting;		/* true if we are reverting */
    BOOL	deletingName;		/* true if we are deleting a name */
    BOOL	readOnly;		// is the file read-only?
    BOOL	newEntryFlag;		// true if this is a new entry
    
    /* Outlets for Importing */
    IBOutlet NSView *importAccessoryView;
    IBOutlet NSButton *omitDuplicatesSwitch;
    IBOutlet NSButton *replaceUpdatedSwitch;
    IBOutlet NSProgressIndicator *importProgress;

    /* The document itself */
    SList   *doc;

    /* Lockfile */
    NSString *lockFileName;

    /* Slider position */
    NSString *sliderPositionAutosaveName;

    /* Registered icon handles */
    id <IconClickingProtocol> *iconHandlers;

    /* Plug-in Support */
    NSMutableDictionary *classObjects;
}

/* accessor methods */
+ (SLC *)lastActiveSLC;
- (SBookText *)entryText;
- (BOOL)reverting;
- (BOOL)textChanged;
- (BOOL)readOnly;
- (NSString *)entryCountString:(int)n;
- setReverting:(BOOL)flag;
- setTextChanged:(BOOL)flag;
- statusCell;
- textStatusCell;
- (ExportingTableView *)nameTable;
- (NSText *)fieldEditor;
- (SList *)doc;
- (NSWindow *)window;
- (void)setDoc:(SList *)newDoc;
- (SBookIconView *)iconView;
- (void) setIconView:(SBookIconView *)aView;
- (NSString *)fileChangeString;
- (void) setFileChangeString:(NSString *)str;
- (ProgressPanel *)progressPanel;
- (BOOL)newEntryFlag;
- (NSTextField *)searchCell;
- (RangePanel *)rangePanel;
- (id)objectOfClass:(id)aClass;


/* Special */
- (void) removePerson:(Person *)aPerson;	// and undisplay
- (void) removePeople:(NSArray *)anArray; // remove all people in array, for supporting undo
- (void) addPerson:(Person *)aPerson select:(BOOL)selectFlag;	// adds the person and puts them in SList
- (void) addAndDisplayPerson:(Person *)aPerson;	// for importing, etc.

/* Plug-in Support */
- (id)panelForKey:(NSString *)aKey;
- (void)setPanel:(id)aPanel forKey:(NSString *)aKey;

/* Display methods */
- (void) setStatus:(NSString *)str;	// sets the status window
- (void) setTextStatus:(NSString *)str;
- (void) displayPersonList:(BOOL)autoDisplaySingle;			// display the current list
- (void) displayPersonEntryList:(NSArray *)aList;
- (void) displayOnePersonEntry:(Person *)aPerson; // displays a person or a list of people, and sel
- (void) displayOnePersonOrPersonList:obj; // displays a person or a list of people
- (void) setNameToFirstLine:(BOOL)inhibitDisplay; /* read first line of entry and set cell,
						   * scrolling if necessary.
						   */
- (void) lockEntrySetup:(BOOL)forceForMultiple;  	 /* set lock/unlock entry cell */
- (void) sortVisibleList;
- (int) numPeople;



/* Visible / Selected */
- (NSArray *)visibleList;		// all currently visible in matrix; array of People
- (NSArray *)selectedPeopleArray:(BOOL)removeFlag; // all currently selected in matrix
- (void) addPersonToVisibleList:(Person *)aPerson; // add the person if they are not in the visible list
- (void) selectPersonInVisibleList:(Person *)aPerson;
- (void) removePersonFromVisibleList:(Person *)aPerson;
- (NSArray *)addListToVisibleList:(NSArray *)aPersonList; // don't add if already present; returns list of those added
- (void) selectListInVisibleList:(NSArray *)aPersonList; 
- (int)numVisiblePeople;
- (int)numSelectedPeople;
- (int)numLockedSelectedPeople;
- (void)setupToolbar;


/* Button Registration */
- (void)registerForIcon:(unsigned int)iconNumber owner:(id <IconClickingProtocol>)owner;


/* action methods */
- (IBAction)previousEntry:(id)sender;
- (IBAction)nextEntry:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)displayAll:sender;			/* display all entries */
- (IBAction)find:sender;
- (IBAction)takeSearchModeFromSender:sender;

/* Menu support */
- (IBAction)toggleIconDisplay:(id)sender;
- (IBAction)toggleSortEntries:(id)sender;
- (IBAction)toggleEncryptDatabase:(id)sender;
- (IBAction)toggleEncryptEntry:(id)sender;
- (IBAction)toggleLockEntry:sender;
- (IBAction)togglePrivateEntry:sender;
- (IBAction)refreshDocument:(id)sender;
- (void)refreshCleanup;			// after syncing/refreshing
- (IBAction)toggleOpenFileOnLaunch:(id)sender;

// View Menu
- (IBAction)toggleFilterCompanies:(id)sender;
- (IBAction)toggleFilterPeople:(id)sender;
- (IBAction)applyTemplateToAllEntries:(id)sender;
- (IBAction)removeDuplicates:sender;
- (IBAction)removeLeadingSpaceFromEachLine:(id)sender;

// Entry

- (void) putCursorAtEndOfSearchCell;
- (IBAction) resetSplitBar:sender;
- (IBAction)selectEntireSearchCell;
- (void)delegateDidBecomeActive:(NSNotification *)notification;

@end

@interface SLC(setup)
+ (const char **)intro_text;
- (void)displayIfNewVersion;
- (void)setHorizontalScrollerFromDefaults;
- (void)setSplitViewDirectionFromDoc;
- (void)sliderPositionSetup;
- (void)windowControllerDidLoadNib:(NSWindowController *)windowController;
- (void)setupEmptyDocument;
@end

/* Things for dealing with the entry area */
@interface SLC(entry)
- (void)clearDisplayedPerson;
- (IBAction)printEntry:(id)sender;
- (void)delayedHighlightDisplay;	// wait until first responder switches, then do it
- (void)newEntry:(id)sender;
- (void)saveEntry;		// write entryText back out
- (BOOL)displayedPersonIsLocked;
- (BOOL)displayedPersonIsPrivate;
- (void)setDisplayedPerson:(Person *)aPerson;
- (int)numDisplayedPeople;
- (Person *)displayedPerson;
- (void) reparse;
- (void) displayPersonEntry:(Person *)newPerson append:(BOOL)flag; // actually display the text
- (void) addAndDisplayData:(NSData *)aString;
- (void) displayPerson:(id)sender;	// called when browser is clicked
- (void) forcePersonRedisplay;
- (IBAction)makeMyEntry:sender;
@end


/* See SLC_files.m for the stuff having to deal with files */
@interface SLC(files)
- (BOOL)isFileSBookXML:(NSString *)fname;
- (NSString *)windowNibName;
- (BOOL)keepBackupFile;

/* Autosave & autocheck */
- (void) removeTimers;
- (void) scheduleTimers;
- (void) autosave:(NSTimer *)t;
- (void) autocheck:(NSTimer *)t;

- (void)setFileName:(NSString *)fileName;
- (IBAction)import:sender;			// import menu option
- (void)importCurrent:sender;		// import into the current book
- (void)importSBookXMLFilenameArray:(NSArray *)filenames flag:(int)flag;
- (void)notifyImportCount:(int)count;


- (IBAction)exportToiPod:(id)sender;
- (IBAction)exportTovCards:(id)sender;

/* VCard Support */
- (BOOL)importVCard:(NSString *)vCard;
- (BOOL)isFileVCard:(NSString *)filename;

/* copy and paste */
- (void)copyPeopleArray:(NSArray *)people toPasteboard:(NSPasteboard *)pb;
- (void)copySelectedToPasteboard:(NSPasteboard *)pb andRemove:(BOOL)removeFlag;
- (void)pasteWithPasteboard:(NSPasteboard *)pb;

- (void)copy:sender;
- (void)cut:sender;
- (void)paste:sender;
- (void)delete:sender;

@end

extern int debug;

// Local Variables:
// mode:ObjC
// End:
