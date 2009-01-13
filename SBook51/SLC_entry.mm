/*
 * SLC_entry.m:
 * 
 * All of the SLC logic for dealing with the entry
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
#import "History.h"
#import "ExportingTableView.h"

#import <unistd.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <fcntl.h>
#import <dirent.h>

@implementation SLC(entry)
- (Person *)displayedPerson 		{ return displayedPerson;}
- (int)numDisplayedPeople       { return numDisplayedPeople;}

- (void)setDisplayedPerson:(Person *)aPerson
{
    [displayedPerson release];		// give up my copy
    displayedPerson = [aPerson retain];
}

- (BOOL)displayedPersonIsPrivate
{
    return [displayedPerson queryFlag:ENTRY_PRIVATE_FLAG];
}
    
- (BOOL)displayedPersonIsLocked
{
    return [displayedPerson queryFlag:ENTRY_LOCKED_FLAG];
}

- (void)forcePersonRedisplay
{
    if(displayedPerson){
	Person  *person = displayedPerson;

	[self setDisplayedPerson:nil];
	[self displayPersonEntry:person append:NO];
    }
}

- (void)delayedHighlightDisplay
{
    [NSTimer scheduledTimerWithTimeInterval:0
	     target:iconView
	     selector:@selector(highlightSearchResults)
	     userInfo:nil
	     repeats:NO];
}

/* - (void)displayPersonEntry:(Person *)person append:(BOOL)append
 * display a the text for a specific Person entry in the text browser.
 * if append if FALSE, it replaces and marks this entry editable.
 * Otherwise, it appends and marks the entry not-editable.
 * 
 */
- (void)displayPersonEntry:(Person *)person append:(BOOL)append
{
    Person *delPerson = nil;
    static NSTextView *myText = nil;

    if(myText==nil){
	myText		= [[NSTextView alloc] init]; // for finding the first line
    }
	

    /* If we are not appending and the currently displayed person is in fact
     * the one that we are already displaying just return.
     */
    if(append==NO && displayedPerson==person){
	return;
    }

    /* Save what was edited before */
    [self saveEntry];	

    /* If we are displaying a new person and the current person is blank,
     * remember to delete the current person
     */
    if([displayedPerson blankEntry]){
	delPerson = displayedPerson;	// remember to delete this person if they are blank
    }

    

    /* Erase the entry if we are not appending */
    if(append==NO){
	[entryText setString:@""];
	numDisplayedPeople = 0;
    }

    /* Remember the undo information */
#ifdef SLC_ENTRY_UNDO
    [[self undoManager] registerUndoWithTarget:self
			selector:@selector(displayOnePersonEntry:)
			object:displayedPerson];
    [[self undoManager] setActionName:[NSString stringWithFormat:@"Display '%@'",[person cellName]]];
#endif

    /* Now display the rtfddata at the end of the text object */
    [self setDisplayedPerson:person];

    if(append==NO){
	NSString *str = [NSString stringWithFormat:@"%@\n%@",
				  titleString(@"Created ",[person ctime],[person cusername]),  
				  titleString(@"Last edited ",[person mtime],[person musername])];

	[self setTextStatus:str];
    }
    else {
	[entryText appendString:@"\n______________________\n"];
	[self	setTextStatus:@""];
    }

    /*****************
     ***  This is where the text gets loaded in!!!
     ***
     ****************/
    
    [entryText appendRTFD:[displayedPerson rtfdData]];
    numDisplayedPeople++;

    [displayedPerson	updateAccessTime];
    [self	reparse];
    textChanged	= NO;

    /* IF we are appending, make sure this cannot be edited
     * and then return.
     */
    if(append==YES){
	[entryText setEditable:FALSE];
	return;
    }

    [self lockEntrySetup:NO];		// set the lock button and editability

    /* See if we should delete the old peson */
    if(delPerson && delPerson!=displayedPerson){
	[visibleList removeObject:delPerson]; // remove if present
	[self	removePerson:delPerson];
	[self   setStatus:@"Removing blank entry"];
	[self   displayPersonList:NO];
    }
}

- (void)clearDisplayedPerson
{
	displayedPerson = nil;
	numDisplayedPeople = 0;
	[entryText setString:@""];
	[iconView reparse];
	[self	lockEntrySetup:NO];
	[entryText setEditable:NO];
}

/*
 * newEntry:
 *
 * 1. Create a new Person object and populate with the template.
 * 2. Add the Person to the SList.
 * 3. Add the Person to the display list.
 * 4. Redisplay the visibleList. Find the person and select them.
 * 5. Display the person in the entryText with the first line selected.
 */

- (void)newEntry:(id)sender
{
    NSString *fmt=0;
    NSString *str = nil;
    Person *newPerson = nil;
    NSWindow *window = [self window];

    /* If our window is not the key window, make it such */
    if(window != [NSApp keyWindow]){
	[window	makeKeyAndOrderFront:nil];
    }

    [self saveEntry];		// save the old entry
    [self setDisplayedPerson:nil];	// no longer this person

    /* Put the template into the entryText, then save it out */
    fmt = [[NSString alloc] initWithData:[doc RTFTemplate] encoding:NSUTF8StringEncoding];
    str = [NSString stringWithFormat:fmt,[doc numPeople]+1];
    [entryText	setRtfData:[str dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    [fmt release];

    /* Create the new person with the text that is there*/
    newPerson = [[Person alloc] initForRTFDData:[entryText rtfdData] sortKey:[doc defaultSortKey]];

    [self addAndDisplayPerson:newPerson];

    [entryText  selectFirstLine];

    /* Finish up display */
    [self setStatus:[NSString stringWithFormat:@"%@\n(out of %d)",
			      [self entryCountString:[visibleList count]],
			      [doc numPeople]
    ]];

    [iconView	reparse];
    [self	displayIfNewVersion];	// as good a place as any to do it
    numDisplayedPeople = 1;		// by definition
    newEntryFlag = TRUE;
}


/* saveEntry:
 *
 * write back modified address from NSText object back to in-memory database
 */
- (void)saveEntry
{
    if(debug>4) NSLog(@"saveEntry textChanged=%d",textChanged);
    if(!textChanged) return;		/* no need to update */

    /* Make sure that this person is in the document
     * Then save the Rich Text
     */
    [doc addPerson:displayedPerson];
    [displayedPerson setRTFDData:[entryText rtfdData] andUpdateMtime:YES];

    textChanged	= NO;	/* because we have copied it */
}

- (void)addAndDisplayData:(NSData *)data
{
    Person *person = [[[Person alloc] init] autorelease];

    [person setAsciiData:data
	    releaseRtfdData:YES andUpdateMtime:YES];
    [self addAndDisplayPerson:person];
}


/* displayPerson:
 * called when the nameMatrix is clicked on to display the selected
 * names in the matrix.
 *
 * 1 - find the list of selected people
 * 2 - make a list of those people. Display them.
 * Also called to do this manually.  sender should be nil when called manually.
 */
-(void)displayPerson:(id)sender
{
    int selCount=0;
    unsigned int i;    

    /* find the selected people */
    NSMutableArray	*selList = [[[NSMutableArray alloc] init] autorelease];

    for(i=0;i<[visibleList count];i++){
	if([nameTable isRowSelected:i]){
	    [selList addObject:[visibleList objectAtIndex:i]];
	}
    }

    selCount = [selList count];

    /* If there is just one selected cell, and that is the person
     * currently displayed, then just return.
     */
    if(selCount==1 && ([selList objectAtIndex:0] == displayedPerson)){
	return;	
    }

    /* If we have been asked to display too many cells, just
     * note how many cells have been selected.
     */
    if(selCount > [[[NSUserDefaults standardUserDefaults]
		       objectForKey:DEF_MAX_ENTRIES_DISPLAYED] intValue] &&
       selCount > 1){
	NSString *selText = [NSString	stringWithFormat:@"%u entries selected",
					selCount];

	[entryText setString:selText];
	[self setStatus:selText];
	[self setTextStatus:@"Multiple entries selected"];
	
	[entryText setEditable:NO];
	//[self	   putCursorAtEndOfSearchCell];

	[self	setDisplayedPerson:nil];
	textChanged	= NO;
	numDisplayedPeople = 0;

	[iconView reparse];		// remove the icons
	return;
    }

    /* Okay, just display the entries */
    for(i=0;i<(unsigned int)selCount;i++){
	Person *who = [selList objectAtIndex:i];

	[self	displayPersonEntry:who append:i>0];
    }

    if(selCount>1){
	[self	setStatus:[NSString stringWithFormat:@"%d selected", selCount]];
	[self	lockEntrySetup:YES];	// force it locked
    }


    /* Add the people to the history */
    [history save];
	
    /* Scroll to the first line, but reposition the cursor
     * on the search cell...
     */
    [entryText 	setSelectedRange:NSMakeRange(0,0)];
    [entryText  scrollRangeToVisible:NSMakeRange(0,0)];
	
    newEntryFlag = NO;			// by definition, I think

}

- (void)reparse
{
    [iconView	reparse]; 		// forward the message
}


/* Menu options */

/* Apply the template by discarding the formatting and redisplaying */
- (IBAction)applyTemplate:(id)sender
{
    [self saveEntry];		
    [displayedPerson discardFormatting];
    [self forcePersonRedisplay];
}

- (IBAction)printEntry:(id)sender
{
    [entryText print:sender];
}

- (IBAction)makeMyEntry:(id)sender
{
    [doc makeMe:displayedPerson];
}


@end 
