/*
 * SList sync operations.
 */

#import "Person.h"
#import "SList.h"
#import "libsbook.h"
#import "tools.h"
#import "defines.h"
#import "SLC.h"

#import "Syncher.h"

@implementation Syncher
- init
{
    [super init];
    justCopied = [[NSMutableArray array] retain];
    return self;
}

- (void)dealloc
{
    [justCopied release];
    [super dealloc];
}

- (NSPanel *)syncSetupPanel
{
    return syncSetupPanel;
}



/* check for termination */
- (void)checkForQuit
{
    /* check for termination */
    NSEvent *event = [NSApp nextEventMatchingMask:NSLeftMouseDownMask|NSLeftMouseUpMask
			    untilDate:[NSDate distantPast]
			    inMode:NSModalPanelRunLoopMode
			    dequeue:YES];
    //NSLog(@"checkForQuit = %@",event);
    if(event){
	[NSApp sendEvent:event];
    }
}

-(void)endSetup:sender
{
}

-(void)endStatus:sender
{
}

/* This is called when the user clicks okay: at the end of the sync */
-(IBAction)okay:sender
{
    [NSApp endSheet:syncStatusPanel returnCode:NO];
    [syncStatusPanel orderOut:self];
    [slc refreshCleanup];
}

- (void)syncSBookToSource:(int)fastFlag {}
- (void)syncSourceToSBook {}


/* Switch to the sheet and start the syncing... */
-(IBAction)sync:sender
{
    /* Remove the setup panel */
    if(forceTag==0){
	[NSApp endSheet:syncSetupPanel returnCode:NO];
	[syncSetupPanel orderOut:self];
    }

    /* Set up the status panel */
    [justCopied		removeAllObjects];
    [abRecordsCopied	setIntValue:0];
    [abRecordsSkipped	setIntValue:0];
    [sbookRecordsCopied setIntValue:0];
    [sbookRecordsSkipped setIntValue:0];
    [ab_to_sbook	setDoubleValue:0];
    [sbook_to_abook	setDoubleValue:0];
    [ab_to_sbook	setMinValue:0];

    [totalABRecords	setIntValue:[self syncSourceCount]];
    [ab_to_sbook	setMaxValue:[totalABRecords doubleValue]];
    [abook_cleaner	setMaxValue:[totalABRecords doubleValue]];

    [totalSBookRecords setIntValue:[doc numPeople]];
    [sbook_to_abook    setMaxValue:[totalSBookRecords doubleValue]];
    [sbook_cleaner     setMaxValue:[totalSBookRecords doubleValue]];

    [cancel2Button setEnabled:YES];
    [okay2Button setEnabled:NO];

    /* Now bring out the status panel */

    [NSApp beginSheet:syncStatusPanel
	   modalForWindow:[slc window]
	   modalDelegate:self
	   didEndSelector:@selector(endStatus:)
	   contextInfo:nil];
    

    userQuit = NO;
    int tag = [[syncActionMatrix selectedCell] tag];
    if(tag==TAG_SYNC_AB_TO_SBOOK || tag==TAG_SYNC_AB_SBOOK || tag==TAG_IMPORT_ABOOK_TO_SBOOK){
	[self syncSourceToSBook];
    }

    /* These numbers may have changed... */
    [totalSBookRecords setIntValue:[doc numPeople]];
    [sbook_to_abook    setMaxValue:[totalSBookRecords doubleValue]];

    if(tag==TAG_SYNC_SBOOK_TO_AB || tag==TAG_SYNC_AB_SBOOK){
	[ab_to_sbook       setToFull];	// catch them up if they aren't
	[sbook_cleaner     setToFull];
    }

    /* Now optionally copy the other way */
    if(tag==TAG_SYNC_SBOOK_TO_AB || tag==TAG_SYNC_AB_SBOOK || tag==TAG_EXPORT_SBOOK_TO_ABOOK){
	[self syncSBookToSource:0];
    }

#if 0
    /* Handle the wacky deletions */
    if(tag==TAG_REMOVE_ABOOK_ENTRIES_IN_SBOOK || tag==TAG_REMOVE_SBOOK_ENTRIES_IN_ABOOK){

	[abook_cleaner setMaxValue:[[ab people] count]];
	[sbook_cleaner setMaxValue:[[ab people] count]];

	NSEnumerator *en = [[ab people] objectEnumerator];
	ABPerson *abp;
	while((abp = [en nextObject]) && !userQuit){
	    NSString *uid       = [abp valueForProperty:kABUIDProperty];
	    Person *pnew = [doc personWithSyncSource:myAddressBookName andUID:uid];
	    if(tag==TAG_REMOVE_ABOOK_ENTRIES_IN_SBOOK){
		if(pnew) [ab removeRecord:abp];
		[abook_cleaner incrementBy:1.0];
	    }
	    if(tag==TAG_REMOVE_SBOOK_ENTRIES_IN_ABOOK){
		if(pnew) [doc removePerson:pnew];
		[sbook_cleaner incrementBy:1.0];
	    }
	    [self checkForQuit];
	}
    }
#endif
    [cancel2Button setEnabled:NO];
    [okay2Button setEnabled:YES];
    [justCopied removeAllObjects];
}

    /* Called if the User Quits in the first panel; NSApp got the event */
-(void)cancel1:sender
{
    //NSLog(@"cancel1");
    [NSApp endSheet:syncSetupPanel returnCode:NO];
    [syncSetupPanel orderOut:self];
}

    /* Called if the User Quits in the second panel; we got the event */
-(void)cancel2:sender
{
    //NSLog(@"cancel2");
    userQuit = YES;
    [NSApp endSheet:syncStatusPanel returnCode:NO];
    [syncStatusPanel orderOut:self];
}

- (void)setSLC:(SLC *)slc_
{
    slc = slc_;
    doc = [slc doc];

}

-(void)runWithSLC:(SLC *)slc_ flag:(int)tag
{
    /* Make sure that our nib is loaded... */
    if(syncSetupPanel==nil){
	[NSBundle loadNibNamed:@"AddressBookSync" owner:self];
	if(!syncSetupPanel)
	    NSRunAlertPanel(@"SBook",@"Could not load nib named AddressBookSync",
			    nil,nil,nil);
    }


    [self setSLC:slc_];
    forceTag = tag;

    if(forceTag){
	[syncActionMatrix selectCellWithTag:forceTag];
	[self sync:nil];
	return;
    }
    [NSApp beginSheet:syncSetupPanel
	   modalForWindow:[slc window]
	   modalDelegate:self
	   didEndSelector:@selector(endSetup:)
	   contextInfo:nil];
}

- (int)syncSourceCount { return 0; }

- (BOOL)personModifiedAfterSync:person
{
    return ([person mtime] > [person syncTime]);
}



@end
