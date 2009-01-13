#import <sys/types.h>
#import <regex.h>
#import <DefaultSwitchSetter.h>


#import "EnvelopePanel.h"
#import "ZoomScrollView.h"
#import "EView.h"
#import "LabelElement.h"
#import "LabelView.h"
#import "Person.h"

#define DEF_STATIONERY			@"DefaultStationeryName___NotForCustomerUser"
#define STATIONERY_STORE		@"StationeryStore"
#define DEF_INCLUDE_RETURN_ADDRESS	@"IncludeReturnAddressOnLabel"
#define DEF_INCLUDE_DESTINATION_ADDRESS @"IncludeDestinationAddressOnLabel"
#define DEF_ENVELOPE_LASTNAME_FIRSTNAME @"EnvelopeLastnameFirstname"

#import "tools.h"

#define DEBUG_LOG


@implementation EnvelopePanel
EnvelopePanel *sharedEnvelopePanel = nil;

+ (void)initialize
{
    NSMutableDictionary *appDefs = [NSMutableDictionary dictionary];
    [appDefs setObject:[NSDictionary dictionary] forKey:STATIONERY_STORE];
    [appDefs setObject:@"1" forKey:DEF_INCLUDE_RETURN_ADDRESS];
    [appDefs setObject:@"1" forKey:DEF_INCLUDE_DESTINATION_ADDRESS];
    [appDefs setObject:@"0" forKey:DEF_ENVELOPE_LASTNAME_FIRSTNAME];
    [defaults registerDefaults:appDefs];
}

+ (EnvelopePanel *)sharedEnvelopePanel
{
    return sharedEnvelopePanel;
}

/* EnvelopePanel.nib automatically loaded by the bundleController */
- (void)awakeFromNib
{

    defaultStationery = [[retAddrText rtfdData] retain];

    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(prepareToPopup)
					  name:NSPopUpButtonWillPopUpNotification
					  object:stationeryPopup];

    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(textDidChange:)
					  name:NSControlTextDidChangeNotification
					  object:newStationeryNameField];

    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(createLabels:)
					  name:NSTextDidChangeNotification
					  object:addrText];

    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(createLabels:)
					  name:NSTextDidChangeNotification
					  object:retAddrText];


    spacerCell = [[stationeryPopup itemAtIndex:0] retain];
    deleteCell = [[stationeryPopup itemAtIndex:1] retain];
    newCell    = [[stationeryPopup itemAtIndex:2] retain];
    [newStationeryNamePanel retain];

    [envelopeZoomScrollView setScaleFactor:0.40];
    [envelopeZoomScrollView setBackgroundColor:[NSColor darkGrayColor]];
    [envelopeZoomScrollView setDrawsBackground:YES];
    [labelsZoomScrollView setScaleFactor:0.40];

    setDefault(tabView,DEF_ENVELOPE_PANEL_TAG_VIEW);
    setDefault(includeReturnAddressButton,DEF_INCLUDE_RETURN_ADDRESS);
    setDefault(includeDestinationAddressButton,DEF_INCLUDE_DESTINATION_ADDRESS);

    [printLastnameFirstname setState:[[defaults objectForKey:DEF_ENVELOPE_LASTNAME_FIRSTNAME] intValue]];

    sharedEnvelopePanel = [self retain];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [spacerCell release];
    [deleteCell release];
    [newCell    release];
    [defaultStationery release];
    [newStationeryNamePanel release];
    [super dealloc];
}



/* createLabels:
 * Recreate the labels for the label view
 *
 */

- (IBAction)createLabels:sender
{
    LabelElement *e;

    [labelView clearElementList];

    if([includeReturnAddressButton intValue]){
	e = [[LabelElement alloc] initPerson:nil labelView:labelView];
	[e addLine:[retAddrText string] tag:P_BUT_ADDRESS];
	[labelView	addReportElement:[e autorelease]];
    }
	
    if([includeDestinationAddressButton intValue]){
	e = [[LabelElement alloc] initPerson:nil labelView:labelView];
	[e addLine:[addrText string] tag:P_BUT_ADDRESS];
	[labelView	addReportElement:[e autorelease]];
    }

    [labelView	changedLayoutInformation:nil]; // layout
}




- (void)setPerson:(Person *)aPerson
{
    person = aPerson;
    if(person!=nil){
	[printLastnameFirstname setEnabled:YES];
    }
    else {
	[printLastnameFirstname setEnabled:NO];
	[printLastnameFirstname setState:0];
    }
	
}

- (IBAction)setAddress:(NSString *)str
{
    [addrText	setString:str];
    if([printLastnameFirstname state]){
	[self changeLastnameFirstname:nil]; // swap it if we are swapping.
    }

    [eview	textDidChange:nil];
}

- (void)setStationeryPopupTitle
{
#ifdef DEBUG_LOG
    NSLog(@"setStationeryPopupTitle '%@'  %@",[self defStationery],stationeryPopup);
#endif
    [stationeryPopup removeAllItems];
    [stationeryPopup addItemWithTitle:[self defStationery]];
    [stationeryPopup setTitle:[self defStationery]];
}


/****************************************************************
 ** Running
 ****************************************************************/

- (void)runWithWindow:(NSWindow *)win
{
    NSData *retAddrData = [[self stationeryStore] objectForKey:[self defStationery]];

    runningAsSheet = YES;
    parentWindow = win;

    /* Set up the stationery */

    if(retAddrData){
	[retAddrText setRtfdData:retAddrData];
    }
    else{
	[retAddrText setString:@"Enter return address here"];
    }

    /* Set the title to be the current stationery */
    [self	setStationeryPopupTitle];

    /* Set up the eview */
    [eview	displayPaperSize];
    [eview	setNumPages:1];

    /* Set up the label view */
    [labelView	prepareForReport];
    [self	createLabels:self];

    [self	setSendSelectorAfterOrderOut:YES];

    [self	runAsSheet:win modalDelegate:self
		didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


/* Called when the sheet actually ends. Print the eView or the labelview */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
	id selected = [tabView selectedTabViewItem];
	
	[self	saveStationery];
	if(selected == envelopeTab){
	    [eview printWithWindow:parentWindow];
	}
	if(selected == labelTab){
	    [labelView print:nil];
	}
    }
}


/****************************************************************
 *** Stationery accessors
 ****************************************************************/

- (void)setStationeryStore:(NSDictionary *)dict
{
    [defaults setObject:dict forKey:STATIONERY_STORE];
}

- (NSMutableDictionary *)stationeryStore
{
    /* If no object, insert the default template */
    if([self stationeryCount]==0){
	NSMutableDictionary *st =
	    [NSMutableDictionary
		dictionaryWithDictionary:[defaults objectForKey:STATIONERY_STORE]];

	[st setObject:defaultStationery forKey:@"Default"];
	[st setObject:@"Default" forKey:DEF_STATIONERY];
	[self setStationeryStore:st];
#ifdef DEBUG_LOG
	NSLog(@"**created defaulat stationery store");
#endif
    }
    return [NSMutableDictionary
	       dictionaryWithDictionary:[defaults objectForKey:STATIONERY_STORE]];
}


- (NSString *)defStationery
{
    NSMutableDictionary *st =[self stationeryStore]; 
    NSString *str = [st objectForKey:DEF_STATIONERY];
    NSEnumerator *en;
    id key;

    /* If this key does not exist, delete it */
    if(str && [st objectForKey:str]==nil){
	str = nil;
    }

    if(str) return str;

    /* No default. Return the first key that maps to an NSData */
    en = [st keyEnumerator];
    while(key = [en nextObject]){
	if([key isKindOfClass:[NSString class]] &&
	   [[st objectForKey:key] isKindOfClass:[NSData class]]){
	    return key;
	}
    }
    return nil;
}

- (int)stationeryCount
{
    NSMutableDictionary *st =[defaults objectForKey:STATIONERY_STORE];
    NSEnumerator *en = [st keyEnumerator];
    NSString *key;
    int count=0;

    while(key = [en nextObject]){
	if([key isKindOfClass:[NSString class]] &&
	   [key length] > 0 &&
	   [[st objectForKey:key] isKindOfClass:[NSData class]]){
	    count++;
	}
    }
    return count;
}

- (void)setDefaultStationery:(NSString *)val
{
    NSMutableDictionary *st = [self stationeryStore];

#ifdef DEBUG_LOG
    NSLog(@"setDefaultStationery:%@",val);
#endif
    [st setObject:val forKey:DEF_STATIONERY];
    [self setStationeryStore:st];
}


- (void)saveStationeryToName:(NSString *)str
{
    NSMutableDictionary *st = [self stationeryStore];

    if([str length]==0) return;		// don't save 0 length

#ifdef DEBUG_LOG
    NSLog(@"saveStationery: saving stationery %@",str);
#endif

    [st		setObject:[retAddrText rtfdData] forKey:str];
    [self	setStationeryStore:st];
}

- (void)saveStationery
{
    [self saveStationeryToName:[self defStationery]];
}

- (void)loadStationery
{
    NSData *data = [[self stationeryStore] objectForKey:[self defStationery]];
    if(data){
	[retAddrText setRtfdData:data];
    }
}


/****************************************************************
 ** Stationery setup and stuff
 ****************************************************************/

/* Called when the user presses the stationery button --
 * make all of the different stationery values appear.
 */
-(void)prepareToPopup
{
    NSMutableDictionary *st = [self stationeryStore];
    NSEnumerator *en=nil;
    NSString *key=nil;
    NSMutableArray *array = [NSMutableArray array];
	
    [stationeryPopup removeAllItems];

    /* Create a list of the keys that actually point to NSDatas... */
    en = [st keyEnumerator];
    while(key = [en nextObject]){
	id obj = [st objectForKey:key];
#ifdef DEBUG_LOG
	NSLog(@"key=%@ obj=%@",key,obj);
#endif
	if(key && [key isKindOfClass:[NSString class]] && obj && [obj isKindOfClass:[NSData class]]
	   && [key length] >0){
#ifdef DEBUG_LOG
	    NSLog(@"adding %@ to array",key);
#endif
	    [array addObject:key];
	}
    }
    
    /* Now sort it */
    en = [[array sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    while(key = [en nextObject]){
	[stationeryPopup addItemWithTitle:key];
	[[stationeryPopup lastItem] setTarget:self];
	[[stationeryPopup lastItem] setAction:@selector(chooseStationery:)];
	if([key isEqualTo:[self defStationery]]){
	    [[stationeryPopup lastItem] setState:1];
#ifdef DEBUG_LOG
	    NSLog(@"set selected to %@",key);
#endif
	}
    }

    /* Now add the the spacer */
    [stationeryPopup addItemWithTitle:[spacerCell title]];
    [[stationeryPopup lastItem] setEnabled:NO];

    /* Add delete */
    if([self defStationery] && [self stationeryCount]>1){
	[stationeryPopup addItemWithTitle:[NSString stringWithFormat:[deleteCell title],
						    [self defStationery]]];
	[[stationeryPopup lastItem] setAction:@selector(delete:)];
	[[stationeryPopup lastItem] setTarget:self];
	[[stationeryPopup lastItem] setEnabled:YES];
    }

    /* Add "save" */
    //TK

    /* Add new cell */
    [stationeryPopup addItemWithTitle:[newCell title]];
    [[stationeryPopup lastItem] setAction:@selector(newStationery:)];
    [[stationeryPopup lastItem] setTarget:self];
    [[stationeryPopup lastItem] setEnabled:YES];

    /* And set the popup */
    [stationeryPopup setTitle:[self defStationery]];
}

- (IBAction)delete:(id)sender
{
    /* Remove the current default. Set the new default to be the first of the array.
     * Load the default
     */

    if([self stationeryCount]>1){
	NSMutableDictionary *st = [self stationeryStore];
	NSUndoManager *undoManager = [self undoManager];

	/* Remember how to undo this! */
	[undoManager registerUndoWithTarget:self
		     selector:@selector(setStationeryStore:)
		     object:[self stationeryStore]];
	[undoManager setActionName:@"Delete Stationery"];

	[st removeObjectForKey:[self defStationery]];
	[st removeObjectForKey:DEF_STATIONERY];	// remove the default
	[self setStationeryStore:st];	// remove dictionary without the value or the default
	[self setDefaultStationery:[self defStationery]]; // find a new default
	[self loadStationery];
	[self setStationeryPopupTitle];
    }
}

- (IBAction)chooseStationery:(id)sender
{
#ifdef DEBUG_LOG
    NSLog(@"choose stationery %@",[sender title]);
#endif
    [self	saveStationery];	// save the old stationery
    [self	setDefaultStationery:[sender title]];
    [self	loadStationery];
    [self	createLabels:nil];
}


- (BOOL)validateMenuItem:(id <NSMenuItem>)item
{
    if([[item title] length]==0){
	return NO;
    }

    if([item action] == @selector(newStationery:)){
	return YES;
    }
    if([item action] == @selector(delete:)){
	return [self stationeryCount]>1;
    }
    if([item action] == @selector(chooseStationery:)){
	return YES;			// good idea
    }
    return [super validateMenuItem:item];
}

/****************************************************************
 ** Stationery actions.
 ****************************************************************/

- (IBAction)cancelNewStationery:(id)sender
{
    [NSApp stopModal];
    [newStationeryNamePanel orderOut:nil];
    [stationeryPopup setTitle:[self defStationery]]; // put back the old title
}

- (IBAction)okNewStationery:(id)sender
{
    NSString *new = [newStationeryNameField stringValue];

    [NSApp stopModal];
    [newStationeryNamePanel orderOut:nil];

#ifdef DEBUG_LOG
    NSLog(@"newName=%@",new);
#endif

    [retAddrText setString:[NSString stringWithFormat:@"Enter return address for '%@'",new]];
    [self	saveStationeryToName:new];	// save stationery here
    [self	setDefaultStationery:new];

#ifdef DEBUG_LOG
    NSLog(@"defaultStationery now %@",[self defStationery]);
#endif

    [self	setStationeryPopupTitle];	// fix the popup
    [self	createLabels:nil];
}

- (IBAction)newStationery:(id)sender
{
    [newStationeryStatusField setStringValue:@""];
    [newStationeryNameField setStringValue:@""];

    [NSApp runModalForWindow:newStationeryNamePanel];
}


- (void)textDidChange:(NSNotification *)notification
{
    [newStationeryOkayButton setEnabled:[[newStationeryNameField stringValue] length]>0 ? YES : NO];
}

/****************************************************************/


- (IBAction)changedUnits:(id)sender
{
    [eview	changedUnits:sender];
    [labelView	changedUnits:sender];
}

- (IBAction)changeLastnameFirstname:sender
{
    /* Save the new value */
    [defaults setObject:([printLastnameFirstname state] ? @"1" : @"0")
	      forKey:DEF_ENVELOPE_LASTNAME_FIRSTNAME];

    if(person){
	/* Grab the first line and then reimage it from the
	 * Person with the new switch setting
	 */
	NSMutableString *str = [[addrText string] mutableCopy];
	NSRange nl;
	NSString *newName;
	
	nl = [str rangeOfString:@"\n"]; // find the end of the first line
	newName = [person cellName:[printLastnameFirstname state]];
	if(nl.location>0){
	    [str replaceCharactersInRange:NSMakeRange(0,nl.location)
		 withString:newName];
	}
	else {
	    [str insertString:newName atIndex:0];
	}
	
	[addrText setString:str];
    }

    
    [eview redisplay:sender];		// and redisplay
}


@end
