/*
 * SLC.M
 */


#import "SLC.h"
#import "Person.h"
#import "SList.h"
#import "metaphone.h"
#import "ExportingTableView.h"
#import "SBookController.h"
#import "tools.h"
#import "defines.h"
#import "SBookIconView.h"
#import "SBookText.h"
#import "PassphrasePanel.h"
#import "RangePanel.h"
#import "ProgressPanel.h"
#import "History.h"
#import "DefaultSwitchSetter.h"

#import <unistd.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <fcntl.h>
#import <dirent.h>

#define DEBUG_DRAGGING

static SLC *lastActiveSLC;

@implementation SLC

/****************************************************************
 ** alloc & dealloc
 ****************************************************************/

-(RangePanel *)rangePanel
{
    if(!rangePanel){
	[NSBundle loadNibNamed:@"RangePanel" owner:self];
	if(!rangePanel) NSRunAlertPanel(@"SBook",@"Could not load nib named RangePanel",
				    nil,nil,nil);
    }
    return rangePanel;
}


+ (SLC *)lastActiveSLC
{
    return lastActiveSLC;
}

- init
{
    self = [super init];
    doc  = [[SList alloc] init];		  // create a new document
    history	= [[History alloc] initForSLC:self];

    showPeople = YES;
    showCompanies = YES;
    visibleList = [[NSMutableArray alloc] init];  // create a display List
    classObjects = [[NSMutableDictionary dictionary] retain];
    iconHandlers  = (id *)calloc(sizeof(id),P_BUT_MAX);
    return self;
}

- (void)dealloc
{
    if(lastActiveSLC==self){
	lastActiveSLC=nil;
    }
    if(duplicates){
	[duplicates release];
	duplicates=nil;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[self undoManager] removeAllActionsWithTarget:doc  ];
    [[self undoManager] removeAllActionsWithTarget:self ];
    [doc		release];
    [visibleList	release];
    [self		removeTimers];
    [progressPanel	release];
    [history		release];
    [classObjects	release];
    free(iconHandlers);
    [super		dealloc];
}

- (void)close
{
    [self removeTimers];
    [super close];
}


- (id)objectOfClass:(id)aClass
{
    id obj = [classObjects objectForKey:aClass];
    if(obj) return obj;
    obj = [[[aClass alloc] init] autorelease];
    [classObjects setObject:obj forKey:aClass];
    return obj;
}

- (id)panelForKey:(NSString *)aKey
{
    return [classObjects objectForKey:aKey];
}

- (void)setPanel:(id)aPanel forKey:(NSString *)aKey
{
    [classObjects setObject:aPanel forKey:aKey];
}


/****************************************************************
 ** accessor methods
 ****************************************************************/

- (BOOL)reverting		{ return reverting;	}
- (BOOL)textChanged		{ return textChanged;	}
- (BOOL)readOnly		{ return readOnly;	}
- (SBookText *)entryText	{ return entryText;	}
- (ExportingTableView *)nameTable { return nameTable;	}
- setReverting:(BOOL)flag	{ reverting = flag;	return self; }
- setTextChanged:(BOOL)flag	{ textChanged	= flag;	return self; }
- statusCell			{ return statusCell;	}
- textStatusCell		{ return textStatusCell;	}
- (NSText *)fieldEditor		{ return fieldEditor;	}
- (SList *)doc			{ return doc;		}
- (NSWindow *)window            { return [nameTable window]; }
- (NSArray *)visibleList	{ return visibleList;	}
- (SBookIconView *)iconView	{ return iconView;	}
- (void)setIconView:(SBookIconView *)aView { iconView = aView; }
- (NSString*)fileChangeString { return fileChangeString;}
- (void)setFileChangeString:(NSString *)str{[fileChangeString release];fileChangeString = [str retain];}
- (BOOL)newEntryFlag { return newEntryFlag;}
- (NSTextField *)searchCell { return searchCell;}

- (void)setDoc:(SList *)aDoc
{
    [doc release];
    doc = [aDoc retain];
    [doc	setUndoManager:[self undoManager]];
    [doc	setSLC:self];
    [self	search:nil];
}

- (ProgressPanel *)progressPanel
{
    if(progressPanel==nil){
	[NSBundle loadNibNamed:@"ProgressPanel" owner:self];
	[progressPanel retain];
    }
    NSAssert(progressPanel!=0,@"ProgressPanel nib did not load");
    return progressPanel;
}


/****************************************************************
 ** Toolbar stuff
 ****************************************************************/
static NSString* MyDocToolbarIdentifier = @"My Document Toolbar Identifier";
- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: MyDocToolbarIdentifier] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window]  setToolbar: toolbar];
}



- (void)windowWillClose:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/****************************************************************
 ** DISPLAY ROUTINES
 **
 ** Roughly in order of appearance on the UI.
 ****************************************************************/



-(void)setStatus:(NSString *)str
{
    [[self statusCell] setStringValue:str];
    [[self statusCell] displayIfNeeded];
    [[NSGraphicsContext currentContext] flushGraphics];	// update the screen
}

-(void)setTextStatus:(NSString *)str
{
    [[self textStatusCell] setStringValue:str]; 
    [[NSGraphicsContext currentContext] flushGraphics];
}

- (NSString *)entryCountString:(int)n
{
    return [NSString stringWithFormat:@"%d %s",n,(n==1) ? "entry" : "entries"];
}


-(void)sortVisibleList
{
    [visibleList sortUsingFunction:PersonSortFun context:0];
    [nameTable reloadData];
}


-(int)numPeople
{
    return [doc numPeople];
}

- (void)filterVisibleList
{
    /* Filter the list if necessary */
    numFiltered = 0;
    if(!showCompanies || !showPeople){
	NSEnumerator *en = [visibleList objectEnumerator];
	id obj;
	
	while(obj = [en nextObject]){
	    
	    /* If this is the person being edited, don't take it out */
	    if(obj == displayedPerson) continue;

	    if((showCompanies==NO && [obj isPerson]==NO) ||
	       (showPeople==NO && [obj isPerson])){
		[visibleList removeObject:obj];
		numFiltered++;
	    }
	}
    }
}    

- (void)appendFilteredLanguage
{
    if(numFiltered){
	[self setStatus:[NSString stringWithFormat:@"%@ (%d filtered)",
				  [statusCell stringValue],numFiltered]];
    }
}

- (void)redisplayPersonList
{
    [nameTable reloadData];
}

/* displayPersonList -
 * Called when the personList changes.
 * Redisplays the personList in the NSTableView, sorting if necessary.
 *   autoDisplaySingle - if just one entry is chosen, then
 *                       display it
 */
- (void)displayPersonList:(BOOL)autoDisplaySingle
{
    int row;

    if( [ doc queryFlag:SLIST_SORT_FLAG ]){
	[ self sortVisibleList ];
    }
    else{
	[ nameTable reloadData ];
    }

    [self filterVisibleList];


    /* If only one entry in the list, select it and possibly display it */
    if( [ visibleList count ] ==1){
	[nameTable selectRow:0 byExtendingSelection:NO];
	if(autoDisplaySingle){
	    [self displayPersonEntry:[visibleList objectAtIndex:0] append:NO];
	}
    }

    /* If the list is larger than one, then be sure that the displayedPerson
     * is the one that is selected, otherwise make sure that none are selcted.
     */
    if( [ visibleList count ] > 1) {
	unsigned int i;
	for(i=0;i<[visibleList count];i++) {
	    if([visibleList objectAtIndex:i] == displayedPerson){
		[nameTable selectRow:i byExtendingSelection:NO];
		break;
	    }
	}
    }
    
    row = [nameTable selectedRow];
    if(row>=0){
	[nameTable scrollRowToVisible:row];
    }

}


/* displayAll:
 * display all the elements, by searching for ''
 */
- (void)displayAll:(id)sender
{
    [searchCell setStringValue:@""];
    [self	search:sender];
}



/*
 * Display the person in the scroller.
 * Make sure that they are in the visible list and select them.
 * used for the "undo" system, and for the history system
 */
- (void) displayOnePersonEntry:(Person *)aPerson
{
    [ self addPersonToVisibleList:aPerson ];// add the person to the list
    [ self selectPersonInVisibleList:aPerson ];
    [ self displayPersonEntry:aPerson append:NO ]; // and display the person
}

/* Display them all and select all */
- (void) displayPersonEntryList:(NSArray *)aList
{
    unsigned int i;

    [nameTable deselectAll:nil];	// clear the old selection

    /* First make sure that the names are all in the table */
    for(i=0;i<[aList count];i++){
	id per = [aList objectAtIndex:i];
	[self addPersonToVisibleList:per]; // make sure that the object is in the list
    }

    /* Now make sure that they are selected */
    [nameTable reloadData];		// reload the table
    for(i=0;i<[aList count];i++){
	id per = [aList objectAtIndex:i];
	int row;
	row = [visibleList indexOfObject:per]; // find where it is in the list
	[nameTable selectRow:row byExtendingSelection:i>=0];// and select it
	[self displayPersonEntry:per append:(i>0)]; // and add to the display
	if(i==0) [nameTable scrollRowToVisible:row]; // make this the selected row
    }
}

- (void) displayOnePersonOrPersonList:obj // displays a person or a list of people
{
    //NSLog(@"displayOnePersonOrPersonList:%@",obj);
    if([obj isKindOfClass:[Person class]]){
	[self displayOnePersonEntry:obj];
	return;
    }
    if([obj isKindOfClass:[NSArray class]]){
	[self displayPersonEntryList:obj];
	return;
    }
    NSLog(@"obj=%@",obj);
    NSAssert(0,@"displayOnePersonOrPersonList: unknown obj");
}


/*
 * setNameToFirstLine:
 * Sets the cellName of the displayed entry to be the first line
 * of the text.
 * This is faster than rebuilding the Person object on every keystroke.
 */

- (void)setNameToFirstLine:(BOOL)inhibitDisplay
{
    /* get the name */
    NSString *line1 = [entryText getParagraph:0];

    /* This is a hack. getPargraph should never return nil.
     * However, it was doing so when a text object had less than a line in it.
     */
    if(line1==nil){
	line1 = [entryText string];
    }

    if([line1 isEqualToString:[displayedPerson cellName]]){
	return;				// no changes
    }

    /* change value displayed and in person */
    [displayedPerson	setCellName:line1];

    /* Resort the document if necessary */
    if([doc flags] & SLIST_SORT_FLAG){
	[doc resortPerson:displayedPerson];
    }

    /* Redisplay (will sort personList if necessary) */
    [self displayPersonList:YES];

    if([doc flags] & SLIST_SORT_FLAG){
	[nameTable scrollRowToVisible:[nameTable selectedRow]];
    }
}

- (void)lockEntrySetup:(BOOL)forceForMultiple
{
    BOOL	locked=NO;

    if(displayedPerson==nil){
	[lockButton setEnabled:NO];
	[lockButton setState:NO];
	[entryText  setEditable:NO];
	return;
    }

    if([[self displayedPerson] queryFlag:ENTRY_LOCKED_FLAG]){
	locked = YES;
    }

    /* See if the Locked button should be locked and disabled */
    if(readOnly || forceForMultiple){
	[lockButton setEnabled:NO];
	locked = YES;
    }
    else {
	[lockButton setEnabled:YES];
    }

    [encryptButton setEnabled:!locked];
    [encryptButton setState:[[self displayedPerson] queryFlag:ENTRY_PRIVATE_FLAG]];
    [lockButton    setState:locked];
    [entryText	   setEditable:!locked];
	
}

/*
 * selectedPeopleArray:(BOOL)removeFlag
 * Return an Array of the selected people.
 * if removeFlag is true, also remove them from the list.
 * Note that this must be done as a two-pass operation.
 */

- (NSArray *)selectedPeopleArray:(BOOL)removeFlag
{
    int i;
    NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];

    [self saveEntry];

    for(i=0;i<[nameTable numberOfRows];i++){
	if([nameTable isRowSelected:i]){
	    Person *person = [visibleList objectAtIndex:i];
	    [array addObject:person];
	}
    }

    if(removeFlag){
	NSEnumerator *en= [array objectEnumerator];
	id per;

	[nameTable deselectAll:nil];	// because we are removing them
	while(per = [en nextObject]){
	    [self removePerson:per];
	}
    }

    copyCutCount = [array count];

    if(removeFlag){
	[self displayPersonList:NO];	// redisplay the person list
    }

    return array;
}

- (int)numVisiblePeople
{
    return [visibleList count];
}

- (int)numSelectedPeople
{
    int i;
    int count=0;

    for(i=0;i<[nameTable numberOfRows];i++){
	if([nameTable isRowSelected:i]){
	    count++;
	}
    }
    return count;
}

/* Number of selected people who happen to be locked */
- (int)numLockedSelectedPeople
{
    int i;
    int count=0;

    for(i=0;i<[nameTable numberOfRows];i++){
	if([nameTable isRowSelected:i]){
	    if([[visibleList objectAtIndex:i] queryFlag:ENTRY_LOCKED_FLAG]){
		count++;
	    }
	}
    }
    return count;
}




/****************************************************************
 ** Document Management
 ****************************************************************/

- (void)removePerson:(Person *)aPerson
{
    [self setStatus:[NSString stringWithFormat:@"%@ removed",[aPerson cellName]]];		// 
    [visibleList removeObject:aPerson]; // remove if present
    if(aPerson==displayedPerson){	// if person being removed is the displayed person
	[self clearDisplayedPerson];
    }
    [doc	 removePerson:aPerson];
    [nameTable reloadData];
}

- (void) removePeople:(NSArray *)anArray
{
    if([anArray containsObject:displayedPerson]){
	[self clearDisplayedPerson];
    }

    [visibleList removeObjectsInArray:anArray];
    [doc	removePeople:anArray];

    [[self undoManager] removeAllActionsWithTarget:self ]; // be safe for now
    [[self undoManager] removeAllActionsWithTarget:doc ]; // be safe for now
    [self displayAll:nil];		// why not?
}

/*
 * addPerson:select:
 * adds a person to the current document and displays the person.
 */

- (void)addPerson:(Person *)newPerson select:(BOOL)selectFlag
{
    int row=0;

    /* Add the person to the SList */
    [doc	addPerson:newPerson];

    /* Add the person to the display list.
     */
    [visibleList addObject:newPerson];

    /* Sort the person into the list */
    if([doc queryFlag:SLIST_SORT_FLAG]){
	[self sortVisibleList];
    }

    if(selectFlag){
	/* Select the row of the person who was added */
	row = [visibleList indexOfObject:newPerson];
	[nameTable selectRow:row byExtendingSelection:NO];
    }
}

/*
 * addAndDisplayPerson:
 * Add a person to the document and display the person.
 */

- (void)addAndDisplayPerson:(Person *)newPerson
{
    [self	saveEntry];		// save the old entry
    [self	setDisplayedPerson:nil];	// we're not displaying this person

    [self	addPerson:newPerson select:YES];

    /* Display this person in the text editor */
    [self	displayPersonEntry:newPerson append:NO];
    [self	setNameToFirstLine:0];

    [self	lockEntrySetup:nil];

    /* Redisplay the visibleList. */
    [self	displayPersonList:NO];
    
    /* Make the text the firstResponder. For some reason,
     * this isn't working; we may need to send a fake "tab" event
     * to the window...
     */
    [[entryText window] makeFirstResponder:entryText];

    /* And remove undo information, because this level of undo needs to be forgotten */
    [[self undoManager] removeAllActionsWithTarget:entryText];

    /* Finally, update the history */
    [history save];
}

/*
 * Add peson to visible list ---
 * add the person to the list if they aren't already there.
 */

- (void)addPersonToVisibleList:(Person *)aPerson
{
    if( [ visibleList containsObject:aPerson ] == NO ){
	[ visibleList addObject:aPerson ];
	[ self displayPersonList:NO  ];
    }
}

- (void) selectPersonInVisibleList:(Person *)aPerson
{
    if([visibleList containsObject:aPerson]){
	unsigned ind = [visibleList indexOfObject:aPerson];
	[nameTable selectRow:ind byExtendingSelection:NO];
	[nameTable scrollRowToVisible:ind];
    }
}

- (void)removePersonFromVisibleList:(Person *)aPerson
{
    [visibleList removeObject:aPerson];
    [nameTable reloadData];
}

- (NSArray *) addListToVisibleList:(NSArray *)aPersonList // don't add if already present
{
    NSMutableArray *added = [[[NSMutableArray alloc] init] autorelease];
    NSEnumerator *en = [aPersonList objectEnumerator];
    Person *p;
    while(p = [en nextObject]){
	if([visibleList containsObject:p]==NO){
	    [doc addPerson:p];
	    [added addObject:p];
	    [visibleList addObject:p];
	}
    }
    return added;
}

- (void) selectListInVisibleList:(NSArray *)aPersonList
{
    NSEnumerator *en = [aPersonList objectEnumerator];
    Person *p;
    while(p = [en nextObject]){
	int idx = [visibleList indexOfObject:p];
	[nameTable selectRow:idx byExtendingSelection:NO];
    }
}


/****************************************************************
 *** Registration
 ****************************************************************/
- (void)registerForIcon:(unsigned int)iconNumber owner:(id <IconClickingProtocol>)owner
{
    if(iconNumber>P_BUT_MAX) return;
    iconHandlers[iconNumber] = owner;
}


/*****************************************************************
 *** MOVEMENT
 ****************************************************************/

- (void)previousEntry:sender
{
    int selRow = [nameTable selectedRow];
    const char *shown = ([visibleList count]==[doc numPeople]) ? "" : " (shown) ";

    if(selRow==0) return;
    if(selRow==-1){
	selRow = 0;
    }
    else {
	selRow--;
    }
    [nameTable selectRow:selRow byExtendingSelection:NO];
    [nameTable scrollRowToVisible:selRow];
    [self	displayPerson:nil];

    [self setStatus:
	      [NSString stringWithFormat:@"#%d out of %d%s",
			selRow+1,[visibleList count],shown]];
}

- (void)nextEntry:sender
{
    int selRow = [nameTable selectedRow];
    const char *shown = ([visibleList count]==[doc numPeople]) ? "" : " (shown) ";

    if(selRow+1==(int)[visibleList count]) return ;	/* don't move */
    selRow++;				// go to next row

    [nameTable selectRow:selRow byExtendingSelection:NO];
    [nameTable scrollRowToVisible:selRow];
    [self	displayPerson:nil];

    [self setStatus:
	      [NSString stringWithFormat:@"#%d out of %d%s",
			selRow+1,[visibleList count],shown]];
}


/****************************************************************
 ** SEARCHING
 ****************************************************************/

- (void)takeSearchModeFromSender:(id)sender
{
    int searchMode  = [[searchModePopup itemWithTitle:[sender title]] tag];

    [doc	setSearchMode:searchMode];
    [self	search:nil];		// do another search

    /* Since Search mode has changed, write out the new 
     * search mode to defaults database 
     */
    [defaults setObject:[NSNumber numberWithInt:searchMode] forKey:DEF_SEARCH_MODE];
}


/*
 * search:
 * Primary entry point for all searches
 * actually do the search from what is currently in the search cell.
 */
- (void)search:(id)sender
{
    if([[searchCell stringValue] length]==0){
	/* 0-length search gets all */
	[visibleList setArray:[doc searchFor:@"" mode:0]];
	[self filterVisibleList];
	[self setStatus:[NSString stringWithFormat:@"%@ in file",
				  [self entryCountString:[visibleList count]]]];
	[self appendFilteredLanguage];
    }
    else{
	/* Do a search for a string */
	NSString *searchModeString=@"";
	BOOL sms=FALSE;
	int count = [visibleList count];

	[visibleList release];		// release old search 
	visibleList = (NSMutableArray *)[doc searchFor:[searchCell stringValue] mode:[doc searchMode]];
	[visibleList retain];		// get new results

	if([doc lastSuccessfulSearchMode]==SEARCH_FULL_TEXT &&
	   [doc searchMode]==SEARCH_AUTO){
	    searchModeString = @"\n(full text)";
	    sms = TRUE;
	}

	if(count!=1 || sms){
	    NSMutableString *str = [NSMutableString stringWithFormat:@"%d out of %d%@",
						    [visibleList count],[doc numPeople],
						    searchModeString];

	    [self setStatus:str];
	    [self appendFilteredLanguage];
	}
	else{
	    // don't both to tell the user we are displaying the entry
	    [self setStatus:searchModeString];	
	}
    }
    [self displayPersonList:YES];
    [iconView highlightSearchResults];	// because search string may have changed
}

- (void)find:(id)sender
{
    [searchCell selectText:self];
}



/****************************************************************
 ** TABLE DELEGATES
 ****************************************************************/



- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [visibleList count];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
    int r=1;
    Person *per = [visibleList objectAtIndex:rowIndex];

    if([[aTableView tableColumns] objectAtIndex:0]==aTableColumn){
	return [per cellName];
    }
    switch([doc columnOneMode]){
    case Nothing:return @"";
    case FirstPhone:
	r = [per firstLineWithTag:P_BUT_TELEPHONE];
	break;
    case FirstEmail:
	r = [per firstLineWithTag:P_BUT_EMAIL];
	break;
    case SecondLine:
	r = 1;
	break;
    }
    if(r<0) return @"";
    return [per asciiLine:r];
}

- (BOOL)tableView:(NSTableView *)aTableView
  shouldEditTableColumn:(NSTableColumn *)aTableColumn
	      row:(int)rowIndex
{
    return NO;				// no editing
}

/* If you uncomment this, then arrow keys sometimes don't work.*/
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self displayPerson:nil];	
    [self lockEntrySetup:nil];
}


/* Drag & drop
 * This is called automatically by the tableView to write rows to the pasteboard...
 * Right now we just put an array of people into the pasteboard with copyPeopleArray.
 * We can then use lazy data providing to do the appropriate thing...
 */


- (BOOL)tableView:(NSTableView *)tv
	writeRows:(NSArray*)rows
     toPasteboard:(NSPasteboard*)pboard
{
    NSEnumerator *en = [rows objectEnumerator];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    id obj;

#ifdef DEBUG_DRAGGING
    NSLog(@"SLC::tableView writeRows toPasteboard");
#endif

    /* Create an array of these people */
    [self saveEntry];
    while(obj = [en nextObject]){
	Person *person = [visibleList objectAtIndex:[obj intValue]];
	[array addObject:person];
    }
	
    [self copyPeopleArray:array toPasteboard:pboard]; // in SLC_files.mm
    return YES;
}




/****************************************************************
 ** Window delegates
 ****************************************************************/
- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client
{
    if(client==searchCell){
	[fieldEditor setDelegate:self];
	return fieldEditor;
    }
    return nil;
}
 

/****************************************************************
 ** Menu stuff
 ****************************************************************/

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    SEL action = [item action];


    //NSLog(@"ValidateMenuItem %@",[item title]);

    /* Always allow save (the kit has some bugs) */
    if(action == @selector(save:)){
	return YES;
    }

    /* These export items require that you have more than one entry */
    if(action == @selector(printMailingLabels:) ||
       action == @selector(printAddressBook:)   ||
       action == @selector(exportToiPod:)       ||
       action == @selector(exportTovCards:)){
	return([doc numPeople]>0);
    }

    if(action == @selector(exportToFile:)){
	//puts("got an export:");
	return([doc numPeople]>0);
    }


    /* These only works if the entry is writable and an entry is displayed */
    if(action == @selector(applyTemplate:) ||
       action == @selector(removeLeadingSpaceFromEachLine:) ||
       action == @selector(pushEntryToAppleAddressBook:) ||
       action == @selector(makeMyEntry:) ) {
	if(readOnly) return NO;
	if(displayedPerson==nil) return NO;
	if(action==@selector(makeMyEntry:) &&
	   [displayedPerson queryFlag:ENTRY_ME_FLAG]){
	    return NO;
	}
	return YES;
    }

    if(action == @selector(takeSearchModeFromSender:)){
	[item setState:NSOffState];
	return YES;
    }

    /* These have special logic */

    if(action == @selector(printEntry:)){
	return [self numDisplayedPeople]>0;
    }
    if(action == @selector(toggleSortEntries:)){
	[item setState:[doc queryFlag:SLIST_SORT_FLAG] ? NSOnState : NSOffState];
	return YES;
    }
    if(action == @selector(toggleIconDisplay:)){
	[item setState:[iconView displayIcons] ? NSOnState : NSOffState];
	return YES;
    }
    if(action == @selector(toggleLockEntry:)){
	if(displayedPerson==nil){
	    [item setState:NSOffState];
	    return NO;
	}
	[item setState:[[self displayedPerson] queryFlag:ENTRY_LOCKED_FLAG] ? NSOnState : NSOffState];
	if(!readOnly) return YES;
	return NO;
    }
    if(action == @selector(toggleEncryptEntry:)){
	return NO;			// not implemented yet
    }
    if(action == @selector(print:)){
	return([self numDisplayedPeople]>0);
    }
    if(action == @selector(refreshDocument:)){
	if([self fileName]==nil) return NO;
	return YES;
    }

    /* History */
    if(action == @selector(backEntry:)){
	return [history hasBack];
    }
    if(action == @selector(forwardEntry:)){
	return [history hasForward];
    }

    /* Actions that change the entire document */

    if(action == @selector(applyTemplateToAllEntries:) ||
       action == @selector(globalSearchAndReplace:) ||
       action == @selector(removeDuplicates:)
       ){
	if(readOnly) return NO;
	if([doc numPeople]==0) return NO;
	if(action == @selector(removeDuplicates:) && [doc numPeople]==1) return NO; // need 2!
	return YES;
    }

    /* Edit Menu */
    /* Do not enable cut: or delete: if the entry is locked */
    if(action == @selector(cut:) ||
       action == @selector(delete:)){
	if([self numLockedSelectedPeople]>0){
	    return NO;			// can't cut or delete if some are locked
	}
	if([self numSelectedPeople]==0){
	    return NO;			// need somebody to delete
	}
	return YES;
    }

    /* View menu */
    if(action == @selector(toggleFilterCompanies:)){
	[item setState:showCompanies];
	return YES;
    }
    if(action == @selector(toggleFilterPeople:)){
	[item setState:showPeople];
	return YES;
    }

    if(action == @selector(splitHorizontal:)){
	[item setState:![doc queryFlag:SLIST_SPLIT_VERTICAL_FLAG]];
	return YES;
    }

    if(action == @selector(splitVertical:)){
	[item setState:[doc queryFlag:SLIST_SPLIT_VERTICAL_FLAG]];
	return YES;
    }

    /****************************************************************/
    /* Special Menu */
    if(action == @selector(toggleEncryptDatabase:)){
	[item setState:[doc queryFlag:SLIST_ENCRYPTED_FLAG] ? NSOnState : NSOffState];
	return YES;
    }
    /* This one is tricky because we want to put the filename in the label */
    if(action == @selector(toggleOpenFileOnLaunch:)){
	NSString *fname = [self fileName];
	if(fname==nil){
	    [item setTitle:@"Open File on Launch"];
	    [item setState:0];
	    [item setEnabled:NO];	// can't save an unnamed file
	    return NO;
	}
	[item setEnabled:YES];
	[item setState:[AppDelegate willOpenFileOnStartup:fname]];
	[item setTitle:[NSString stringWithFormat:@"Open File %@ on Launch",fname]];
	return YES;
    }

    if(action == @selector(showFileInSpecialMenu:)){
	[item setState:[AppDelegate fileInSpecialMenu:[self fileName]]];
	[item setEnabled:YES];
	return YES;
    }

    return [super validateMenuItem:item];
}

- (IBAction)applyTemplateToAllEntries:(id)sender
{
    /* Save the current entry */
    [self saveEntry];		// write out the data

    /* Set the sort key */
    [doc makePeoplePerformSelector:@selector(setSortKey:)
	 withObject:(id)[doc defaultSortKey]];

    /* Apply the template to every entry, by simply discarding the RTF
     * and keeping the ASCII (creating the ASCII if it is not had.
     */
    [doc makePeoplePerformSelector:@selector(discardFormatting)
	    withObject:nil];

    /* And resort */
    [self	sortVisibleList];

    /* Force a redisplay of the current person */
    [self	forcePersonRedisplay];
}

- (IBAction)removeDuplicates:(id)sender
{
    NSString *msg=nil;

    if(duplicates){
	[duplicates release];
	duplicates = nil;
    }

    [self setStatus:@"Searching for duplicates..."];
    duplicates = [[doc findDuplicates] retain];
    switch([duplicates count]){
    case 0:
	NSBeginAlertSheet(@"Remove Duplicates",
			  nil,nil,nil,
			  [self window],nil,0,0,0,
			  @"No duplicates found");
	[duplicates release];
	duplicates = nil;
	return;
    case 1:
	msg = @"One duplicate found";
	break;
    default:
	msg = [NSString stringWithFormat:@"%d duplicates were found",[duplicates count]];
	break;
    }
    [self setStatus:@""];		// search is done!
    NSBeginAlertSheet(@"Remove Duplicates",@"Remove",@"Cancel",nil,
		      [self window],self,
		      @selector(removeDuplicatesSheetDidEnd:returnCode:contextInfo:),0,
		      0,msg);
}


- (void)removeDuplicatesSheetDidEnd:(NSWindow *)sheet
			 returnCode:(int)returnCode
			contextInfo:(void *)contextInfo
{

    if(returnCode==NSAlertDefaultReturn){
	[doc removePeople:duplicates];	//  remove the entry
	[self refreshCleanup];		// redisplay the list; also sets the Status
	[self setStatus:[NSString stringWithFormat:@"%d duplicate%s removed",
				  [duplicates count],
				  [duplicates count] ? "" : "s"]];

	[duplicates release];		/* Finally, remove the list */
	duplicates = nil;	
    }
}


- (IBAction)removeLeadingSpaceFromEachLine:(id)sender
{
    int line=0;
    NSRange r;
    NSString *str;
    unsigned int pos;

    do {
	r = [entryText getParagraphRange:line];
	if(r.location==0 && r.length==0) return;
	str = [entryText string];
	for(pos=r.location;pos<r.location+r.length;pos++){
	    unichar ch = [str characterAtIndex:pos];
	    if(ch!=' ' && ch!='\t') break;
	}
	if(pos>r.location){
	    [entryText replaceCharactersInRange:NSMakeRange(r.location,pos-r.location)
		       withString:@""];
	}
	line++;
    } while(1);
	
}

- (IBAction)toggleLockEntry:(id)sender
{
    id per = 0;
    int locked = 0;
    NSUndoManager *undoManager = [self undoManager];		// my undoManager

    if([sender isMemberOfClass:[Person class]]){ // if a person, switch to this person
	[self displayOnePersonEntry:sender ];
    }

    per     = [self displayedPerson];
    locked = [displayedPerson queryFlag:ENTRY_LOCKED_FLAG];
    
    if(!per) return;

    if(!locked){
	[per addFlag:ENTRY_LOCKED_FLAG];
	[undoManager registerUndoWithTarget:self
		     selector:@selector(toggleLockEntry:)
		     object:per];
	[undoManager setActionName:[NSString stringWithFormat:@"Lock entry %@",
					     [per cellName]]];
    }
    else{
	[per removeFlag:ENTRY_LOCKED_FLAG];
	[undoManager registerUndoWithTarget:self
		     selector:@selector(toggleLockEntry:)
		     object:per];
	[undoManager setActionName:[NSString stringWithFormat:@"Unlock entry %@",
					     [per cellName]]];
    }
    [self lockEntrySetup:nil];
}

- (IBAction)togglePrivateEntry:(id)sender
{
    NSUndoManager *undoManager = [self undoManager];		// my undoManager
    int isPrivate=0;
    id  per =0;

    if([sender isMemberOfClass:[Person class]]){ // if a person, switch to this person
	[self displayOnePersonEntry:sender ];
    }

    isPrivate = [displayedPerson queryFlag:ENTRY_PRIVATE_FLAG];
    per     = [self displayedPerson];

    if(!per) return;
   
    if([per queryFlag:ENTRY_LOCKED_FLAG]) return; // don't toggle, entry is locked

    if(!isPrivate){
	[per addFlag:ENTRY_PRIVATE_FLAG];
	[undoManager registerUndoWithTarget:self
		     selector:@selector(togglePrivateEntry:)
		     object:per];
	[undoManager setActionName:[NSString stringWithFormat:@"Make entry %@ private",
					     [per cellName]]];
	     
    }
    else{
	[per removeFlag:ENTRY_PRIVATE_FLAG];
	[undoManager registerUndoWithTarget:self
		     selector:@selector(togglePrivateEntry:)
		     object:per];
	[undoManager setActionName:[NSString stringWithFormat:@"Make entry %@ not private",
					     [per cellName]]];
    }
    [self lockEntrySetup:nil];
}

- (IBAction)toggleIconDisplay:(id)sender
{
    [iconView setDisplayIcons:![iconView displayIcons]];
}

- (IBAction)toggleSortEntries:(id)sender
{
    [doc setFlag:SLIST_SORT_FLAG toValue:![doc queryFlag:SLIST_SORT_FLAG]];
    if([doc queryFlag:SLIST_SORT_FLAG]){
	[self sortVisibleList];
    }
}

- (void)setFileEncryption:(bool)flag
{
    NSUndoManager *undoManager = [self undoManager];

    NSLog(@"setFileEncryption:%d",flag);
    [doc setFlag:SLIST_ENCRYPTED_FLAG toValue:flag];

    [undoManager registerUndoWithTarget:self
		 selector:@selector(toggleEncryptDatabase:)
		 object:self];
    [undoManager setActionName:flag ? @"Encrypt Database"  : @"Unencrypt Database"];
}

- (void)removeEncryptionEnded:(NSWindow *)sheet returnCode:(int)returnCode
		  contextInfo:(void  *)contextInfo
{
    if(returnCode){
	[self setFileEncryption:NO];
    }
}

- (IBAction)toggleEncryptDatabase:(id)sender
{
    if([doc queryFlag:SLIST_ENCRYPTED_FLAG]==NO){
	PassphrasePanel *pan = [AppDelegate passphraseCreatePanel];

	if([pan run]==NO){
	    return;			// don't encrypt
	}
	[doc setEncryptionKey:[pan key]];
	[self setFileEncryption:YES];
	[self saveDocument:sender];	// and save the file
	return;
    }
    else {
	if(NSRunAlertPanel(@"SBook5",@"If you remove encryption from the file, then anybody will be able to read the file's contents without providing a password.\n\nDo you really wish to remove the encryption from the saved file?",@"Remove encryption",@"Cancel",0)){
	    [self setFileEncryption:NO];
	}
    }
}

- (IBAction)toggleEncryptEntry:(id)sender
{
    NSRunAlertPanel(@"Not impelmented",
		    @"Sorry, Encrypt Entry is not implemented",
		    nil,nil,nil);
}

- (IBAction)toggleOpenFileOnLaunch:(id)sender
{
    NSString *fname = [self fileName];
    if(fname){
	[AppDelegate setOpenFileOnStartup:fname toValue:![AppDelegate willOpenFileOnStartup:fname]];
    }
}


- (IBAction)showFileInSpecialMenu:sender
{
    NSString *fname = [self fileName];
    if(fname){
	[AppDelegate setFileInSpecialMenu:fname toValue:![AppDelegate fileInSpecialMenu:fname]];
    }
}

/****************************************************************/

/* Clean up the GUI after changes to the database */
- (void)refreshCleanup
{
    [self displayPersonList:NO];
    [self forcePersonRedisplay];
    [self search:self];		// turns out you need to do a new search
    
    /* Now, see if the one we are looking at was deleted.
     * If so, and it is not modified, make it
     * go away. Otherwise, put it back in...
     */
    if(displayedPerson && [doc personWithGid:[displayedPerson gid]]==nil){
	if(textChanged){
	    [doc addPerson:displayedPerson]; // put the person back
	}
	else {
	    [self setDisplayedPerson:nil]; // you...
	    [entryText setString:@""];	// are...
	    [iconView reparse];		// very...
	    [entryText setEditable:NO]; // gone...
	}
    }
}

- (IBAction)refreshDocument:(id)sender
{
    NSString *fileName = [self fileName];
    if(fileName){
	NSData *refreshData = [NSData dataWithContentsOfFile:fileName];

	if(!refreshData) return;	// source file is no longer there

	[self saveEntry];
	SList_xmlread(refreshData,doc);
        [self setFileChangeString:[NSString fileChangeString:fileName]];
	[self refreshCleanup];
    }
}

/****************************************************************
 ** Text delegates
 ****************************************************************/

/* See if the first line changed; if so, update the cell */
- (void)textDidChange:(NSNotification *)notification
{
    id obj = [notification object];

    //if(debug>4) NSLog(@"textDidChange: obj=%x",obj);

    if(obj==fieldEditor){		// see if it was the field editor
	[self search:nil];		// do a search
	return;
    }

    /* Otherwise, it must have been the main text */
    if([obj respondsToSelector:@selector(incrementChangeCount)]){
	[obj incrementChangeCount];
    }
    [self setTextChanged:TRUE];
}


- (void)windowDidUpdate:(id)sender
{
    [self scheduleTimers];		// gets rid of old timers and reset
    
    /* Set the back and forward buttons! */
    [backButton    setEnabled:[history hasBack]];
    [forwardButton setEnabled:[history hasForward]];
}

- (IBAction)toggleFilterCompanies:(id)sender
{
    showCompanies = !showCompanies;
    [self search:nil];			// otherwise, do a new search

}
- (IBAction)toggleFilterPeople:(id)sender
{
    showPeople = !showPeople;
    [self search:nil];			// otherwise, do a new search.

}


- (void)putCursorAtEndOfSearchCell
{
    id		txt=nil;
    int		len=0;

#ifdef DEBUG_KEy
    NSLog(@"putCursorAtEndOfSearchCell");
#endif
    /* put cursor at end of searchCell */
    if([[self window] makeFirstResponder:searchCell]==NO){
	NSLog(@"putCursorAtEndOfSearchCell failed");
	return;
    }
    [searchCell	selectText:self];
    txt	    = [[self window] fieldEditor:NO forObject:searchCell];
    len     = [[txt textStorage] length];
    [txt	setSelectedRange:NSMakeRange(len,0)];
}


/* View Menu */

- (IBAction) resetSplitBar:sender
{
    [splitView setPosition:NSHeight([splitView frame])/2.0];
}

- (IBAction) splitHorizontal:sender
{
    [doc setFlag:SLIST_SPLIT_VERTICAL_FLAG toValue:FALSE];
    [self setSplitViewDirectionFromDoc];
}

- (IBAction) splitVertical:sender
{
    [doc setFlag:SLIST_SPLIT_VERTICAL_FLAG toValue:TRUE];
    [self setSplitViewDirectionFromDoc];
}

- (void)selectEntireSearchCell
{
#ifdef DEBUG_KEY
    NSLog(@"selectEntireSearchCell");
#endif
    [[self window] makeFirstResponder:searchCell];
    [searchCell selectText:self];
}


/****************************************************************
 ** stamps
 ****************************************************************/

-(IBAction)dateStamp:sender
{
}

-(IBAction)timeStamp:sender
{
}

-(IBAction)dateAndTimeStamp:sender
{
}



/****************************************************************
 ** Activation stuff.
 ****************************************************************/

/* If where we clicked we do not accept first mouse, make the fieldEditor
 * the first responder.
 */
- (void)delegateDidBecomeActive:(NSNotification *)notification
{
    NSEvent *ev = [NSApp currentEvent];

    lastActiveSLC = self;

    /* See if we should move the cursor to the mouse field */
    if([ev type]==NSLeftMouseDown){
	NSView *v = [[[self window] contentView] hitTest:[ev locationInWindow]];
	if(v != entryText){
	    [self selectEntireSearchCell];
	}
    }
}

/* If window just became key and it was not with a click to something
 * that takes first mouse, select the entire cell
 */
- (void)windowDidBecomeKey:(NSNotification *)n
{
    NSEvent *ev = [NSApp currentEvent];

#ifdef DEBUG_KEY
    NSLog(@"didBecomeKey");
#endif

    lastActiveSLC = self;
    /* See if we should move the cursor to the mouse field */
    if([ev type]==NSLeftMouseDown){
	NSView *v = [[[self window] contentView] hitTest:[ev locationInWindow]];
	if(v != entryText){
	    [self selectEntireSearchCell];
	}
    }
}

- (void)memory_debug:sender
{
    NSEnumerator *en;
    Person *per;
    int i;

    if(NSRunAlertPanel(@"memory_debug",@"run refresh check?",@"YES",@"NO",nil)){
	NSData *refreshData = [NSData dataWithContentsOfFile:[self fileName]];
	for(i=0;i<1000;i++){
	    SList_xmlread(refreshData,doc);
	}
    }


    if(NSRunAlertPanel(@"memory_debug",@"Modify and re-parse every entry?",
		       @"YES",@"NO",nil)){
	en = [doc personEnumerator];
	while(per = [en nextObject]){
	    [self displayOnePersonEntry:per];
	    /* Add a space to the end of the entry */
	    [entryText replaceCharactersInRange:NSMakeRange([[entryText string] length],0)
		       withString:@"!"];
	    [[self window] displayIfNeeded];
	}
    }
}

/* The splitview moved; remember the new location */
- (void)splitViewMoved:(NSNotification *)n
{
    if(sliderPositionAutosaveName){
	[defaults setObject:[NSNumber numberWithFloat:[splitView position]]
		  forKey:sliderPositionAutosaveName];
    }
}

@end
