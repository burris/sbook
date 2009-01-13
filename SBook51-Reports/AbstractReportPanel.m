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

#import "AbstractReportPanel.h"
#import "AbstractReportView.h"
#import "AbstractReportElement.h"
#import "Person.h"
#import "SList.h"
#import "SLC.h"
#import "SBookController.h"
//#import "tools.h"
#import "FontWell.h"
//#import "defines.h"

//#define DEBUG_CONSTRUCTION

@implementation AbstractReportPanel

- (void)awakeFromNib
{
    firstTimeThrough = YES;
    [super awakeFromNib];
}

- (ZoomScrollView *)zoomScrollView
{
    return zoomScrollView;
}


- (void)dealloc
{
    [currentEntryLabel release];
    [personList		release];
    [super dealloc];
}



/* Behavior Methods */
- (AbstractReportElement *)newElementForPerson:(Person *)aPerson
{
    NSAssert(0,@"AbstractReportPanel: newElementForPerson must be overriden");
    return nil;
}

- (BOOL)showEntryLabels
{
    NSAssert(0,@"AbstractReportPanel: showEntryLabels must be overriden");
    return NO;
}


/* Accessor methods */

- (NSProgressIndicator *)selectionProgress	{ return selectionProgress;}

- (BOOL)showType:(int)i
{
    if([showEntireEntrySwitch intValue]) return YES;		// show everything
    switch(i & P_BUT_MASK){
    case P_BUT_PERSON:
    case P_BUT_COMPANY:
	return showNamesSwitch ? [showNamesSwitch intValue] : YES;
    case P_BUT_ADDRESS:
	return showAddressesSwitch ? [showAddressesSwitch intValue] : YES;
    case P_BUT_TELEPHONE:
	return showPhonesSwitch ? [showPhonesSwitch intValue] : YES;
    case P_BUT_EMAIL:
	return showEmailsSwitch ? [showEmailsSwitch intValue] : YES;
    case P_BUT_LINK:
	return showURLsSwitch ? [showURLsSwitch intValue] : YES;
    }
    if(i & P_FOUND_LABEL){
	return [self showEntryLabels];
    }
    return NO;
}

- (SLC *)slc { return slc;}
- (void)setSLC:(SLC *)aSLC { slc = aSLC;}
- (int)dpf   { return [[slc doc] flags]; }

- (IBAction)reportFinished:sender
{
    [slc	lockEntrySetup:NO];	// make sure it is editable
    [preview	clearElementList];
    [personList	removeAllObjects];
}



- (IBAction)print:sender
{
    [preview 	print:self];
    [self 	proceed:self];
}

/****************************************************************
 ** Report-making methods
 ****************************************************************/

- (BOOL)shouldStartNewEntry:(int)tag lastTag:(int)lastTag
{
    if(tag & P_FOUND_LABEL){	// labels start a new type
#ifdef DEBUG_CONSTRUCTION
	NSLog(@"  startnew 1");
#endif	
	return YES;
    }
    // addresses start a new unless last was a label
    if((tag & P_FOUND_ASTART) && ((lastTag & P_FOUND_LABEL)==0)){
#ifdef DEBUG_CONSTRUCTION
	NSLog(@"  startnew 2");
#endif	
	return YES;
    }
    return NO;				// by default, start entry at a new address
}

/* This is called for each person.
 * It starts by creating an entry label and setting the name on the label.
 * It then looks at each line of the Person and adds them if the tag matches.
 * After each line it checks to see if the entry should be finished.
 * If so, and the entry has more than one line, it gets added to the
 * display list. If there are lines left, it creates a new entry.
 */
- (void)processPerson:(Person *)person
{
    int	line;
    int	lines = [person numAsciiLines];
    AbstractReportElement *newElement = nil;
    int	addedLines=0;
    int lastTag = 0;

#ifdef DEBUG_CONSTRUCTION    
    puts("");
    //NSLog(@"processPerson %@",person);
#endif

    /* Are we just printing names? */
    if(justNames){
	newElement = [self newElementForPerson:person];
	[preview addReportElement:newElement];
	return;
    }

    currentEntryLabel	= 0;
    for(line=1;line<lines;line++){
	unsigned int  tag = [person sbookTagForLine:line]
	    & (P_BUT_MASK|P_FOUND_ASTART|P_FOUND_AEND|P_FOUND_LABEL);
	NSString *theLine = [person asciiLine:line];

#ifdef DEBUG_CONSTRUCTION
	NSLog(@"%d: tag=%d  '%@'",line,tag,theLine);
#endif

	/* Omit last line if it is blank */
	if(line==lines-1 && [theLine length]==0) break;

	/* Do we start a new entry for this tag? */
	if([self shouldStartNewEntry:tag lastTag:lastTag]){
	    if(newElement){
		[preview addReportElement:newElement]; // yes, add the old element
		newElement = nil;
#ifdef DEBUG_CONSTRUCTION
		NSLog(@" ** ADDED %@ **",newElement);
#endif	    
	    }
	}

	/* See if we got a new label. 	 */
	if(tag & P_FOUND_LABEL){
	    [currentEntryLabel release];
	    currentEntryLabel = [theLine retain];
	}
	    
	if([self showType:tag]){

	    /* This line goes on the entry element.
	     * Create a new one if no element exists
	     */
	    if(newElement==nil){
		newElement = [self newElementForPerson:person];
#ifdef DEBUG_CONSTRUCTION
		NSLog(@"Created new element %@",newElement);
#endif		
	    }
	    [newElement addLine:theLine tag:tag];
	    addedLines++;
	}
	lastTag = tag;
    }
    if(newElement && addedLines>0){
#ifdef DEBUG_CONSTRUCTION
	    NSLog(@" ** ADDED2 %@ **",newElement);
#endif	    
	[preview addReportElement:newElement];
	newElement = nil;
    }
    [currentEntryLabel release];
    currentEntryLabel = nil;
}


/****************************************************************
 ** Actions.
 ****************************************************************/




/*
 * changedSelectionCriterial:
 * Enables/disables switches depending on what is picked.
 * Then processes all people.
 */
 
- (IBAction)changedSelectionCriteria:sender
{
    BOOL	show[P_BUT_MAX];
    BOOL	without[P_BUT_MAX];
    NSEnumerator *en=nil;
    Person	*per=nil;

    memset(&show,0,sizeof(show));
    memset(&without,0,sizeof(without));

#ifdef DEBUG_CONSTRUCTION
    NSLog(@"changedSelectionCriteria");
#endif

    if([showEntireEntrySwitch intValue]){
	/* We are showing entire entry. select and disable all other checks */
	[showNamesSwitch setIntValue:1];
	[showNamesSwitch setEnabled:NO];

	[showAddressesSwitch setIntValue:1];
	[showAddressesSwitch setEnabled:NO];

	[showPhonesSwitch setIntValue:1];
	[showPhonesSwitch setEnabled:NO];

	[showEmailsSwitch setIntValue:1];
	[showEmailsSwitch setEnabled:NO];

	[showURLsSwitch setIntValue:1];
	[showURLsSwitch setEnabled:NO];

	[includeWoAddress setIntValue:1];
	[includeWoPhone setIntValue:1];
	[includeWoEmail setIntValue:1];
	[includeWoURL setIntValue:1];

	memset(show,YES,sizeof(show));
	memset(without,YES,sizeof(without));
    }
    else {
	/* Not showing entire entry, so let user which is wanted */
	[showNamesSwitch setEnabled:YES];
	[showAddressesSwitch setEnabled:YES];
	[showPhonesSwitch setEnabled:YES];
	[showEmailsSwitch setEnabled:YES];
	[showURLsSwitch setEnabled:YES];

	/* Now read the values of the switch into the array */
	show[P_BUT_NAME]	  = [showNamesSwitch intValue];
	show[P_BUT_ADDRESS]   = [showAddressesSwitch intValue];
	show[P_BUT_TELEPHONE] = [showPhonesSwitch intValue];
	show[P_BUT_LINK]	  = [showURLsSwitch  intValue];
	show[P_BUT_EMAIL]     = [showEmailsSwitch intValue];

	without[P_BUT_ADDRESS] = [includeWoAddress intValue];
	without[P_BUT_TELEPHONE]= [includeWoPhone   intValue];
	without[P_BUT_EMAIL]   = [includeWoEmail   intValue];
	without[P_BUT_LINK]	   = [includeWoURL     intValue];
    }

    [includeWoAddress setEnabled:[showAddressesSwitch isEnabled] && [showAddressesSwitch intValue]];
    [includeWoPhone   setEnabled:[showPhonesSwitch isEnabled] && [showPhonesSwitch intValue]];
    [includeWoEmail   setEnabled:[showEmailsSwitch isEnabled] && [showEmailsSwitch intValue]];
    [includeWoURL     setEnabled:[showURLsSwitch isEnabled] && [showURLsSwitch intValue]];

    justNames = NO;			// are we just printing names?
    if(show[P_BUT_NAME] &&
       !show[P_BUT_ADDRESS] &&
       !show[P_BUT_TELEPHONE] &&
       !show[P_BUT_EMAIL] &&
       !show[P_BUT_LINK]){
	justNames = YES;		// yes
    }

    [preview		clearElementList]; // clear the element list
    [selectionProgress	setMinValue:0];
    [selectionProgress  setMaxValue:[personList count]];
    [selectionProgress	setDoubleValue:0];

    /* Do the selection */
    en = [personList objectEnumerator];
    while(per = [en nextObject]){
	[self processPerson:per];
	[selectionProgress incrementBy:1.0];
    }
    [selectionProgress  setDoubleValue:[personList count]];

    /* And layout everything again */
    [preview	        changedLayoutInformation:nil]; 
}


/****************************************************************
 * generateReportForPeople:
 * Primary entry point for creating a new report.
 */


- (void)prepareForReport
{
    [preview	prepareForReport];
}

- (void)generateReportForPeople:(NSArray *)peopleArray
{
#ifdef DEBUG_CONSTRUCTION
    NSLog(@"generateReportForPeople");
#endif
    if(personList==nil){
	personList	   = [[NSMutableArray alloc] init];
    }

    [self prepareForReport];
    [personList addObjectsFromArray:peopleArray];

    /* And finally, find the elements that matter */
    [self	changedSelectionCriteria:nil];
		
    /* Bring up the panel */
    [self	runAsSheet:[slc window]
		modalDelegate:self
		didEndSelector:@selector(reportFinished:)
		contextInfo:nil ];

}


- (BOOL)displayLastnameFirst
{
    return [displayLastnameFirstnameSwitch intValue];
}

@end
  
