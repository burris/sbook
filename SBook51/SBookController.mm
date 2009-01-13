/*
 * SBookController.m:
 * 
 * The AppDelegrate

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




#import <assert.h>
#import <Cocoa/Cocoa.h>

#import "SBookController.h"
#import "DefaultSwitchSetter.h"
#import "SLC.h"
#import "defines.h"
#import "tools.h"
#import "Person.h"
#import "SList.h"
#import "Emailer.h"

SBookController *AppDelegate=nil;

int debug=0;


@implementation SBookController

+ (void)initialize
{
    NSMutableDictionary *appDefs= [NSMutableDictionary dictionary];

    [appDefs setObject:[NSMutableArray array] forKey:DEF_OPEN_ON_LAUNCH];
    [appDefs setObject:[NSMutableArray array] forKey:DEF_FILES_IN_SPECIAL_MENU];
    [appDefs setObject:[NSNumber numberWithBool:YES] forKey:DEF_CHECK_ON_LAUNCH];
    [appDefs setObject:[NSNumber numberWithBool:YES] forKey:DEF_SHOW_INTRO_TEXT];
    [appDefs setObject:@"0" forKey:DEF_LAST_FIRST];

    [appDefs setObject:@"1"  forKey:DEF_AUTOCHECK_ENABLE];
    [appDefs setObject:@"1"  forKey:DEF_AUTOSAVE_ENABLE];
    [appDefs setObject:@"10" forKey:DEF_AUTOCHECK_INTERVAL];
    [appDefs setObject:@"60" forKey:DEF_AUTOSAVE_INTERVAL];
    [appDefs setObject:[NSNumber numberWithInt: 0] forKey:DEF_SHOW_HORIZONTAL_SCROLLER];
    [appDefs setObject:@"1" forKey:DEF_REMOVE_COLOR_FROM_PASTED_TEXT];

    [appDefs setObject:@"0" forKey:@"debug"];


    /* View */
    [appDefs setObject:@"5"  forKey:DEF_MAX_ENTRIES_DISPLAYED];
    [appDefs setObject:@"1"  forKey:DEF_HIGHLIGHT_SEARCH_RESULTS];

    //[appDefs setObject:@""   forKey:DEF_SPECIAL_DIALING_PREFIX];
 
    [appDefs setObject:@"1"  forKey:DEF_AUTO_CREATE_ON_BLANK_CLICK];

    /* Launch */
    [appDefs setObject:@"0"  forKey:DEF_OPEN_ON_ACTIVATE];

    [defaults registerDefaults:appDefs];

    debug = [defaults integerForKey:@"debug"];
    if(debug) NSLog(@"debug=%d",debug);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (NSString *)appVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}


- init
{
    NSTextView *text;

    /* Certify that the routines all work properly */
    self = [super init];
    AppDelegate = self;
    [[NSNotificationCenter defaultCenter]
	addObserver:self
	selector:@selector(appDidInit:)
	name:NSApplicationDidFinishLaunchingNotification
	object:NSApp];

    text = [[NSTextView alloc] init];
    [text setString:@"one\ntwo\nthree\nfour"];
    assert([[text getParagraph:0] compare:@"one"]==0);
    assert([[text getParagraph:1] compare:@"two"]==0);
    assert([[text getParagraph:2] compare:@"three"]==0);
    assert([[text getParagraph:3] compare:@"four"]==0);
    
    return self;
}

-(id <SBookDialer>)dialerPanel { return dialerPanel;}
-(id <SBookLocalizedDialer>)localizedDialer {return localizedDialer;}
-(void)setDialerPanel:(id <SBookDialer,NSObject> )aDialer {dialerPanel=[aDialer retain];}
-(void)setLocalizedDialer:(id <SBookLocalizedDialer,NSObject>)aLocalizedDialer
{
    localizedDialer = [aLocalizedDialer retain];
}

-(void)setReportBundleClassInstance:(id <ReportClassInstance,NSObject>) anInstance
{
    reportBundleClassInstance = anInstance;
}

-(id <ReportClassInstance>)reportBundleClassInstance { return reportBundleClassInstance;}




#define	OutletForNib(outlet,nib) - outlet \
{ \
	if(!outlet){\
		[NSBundle loadNibNamed:nib owner:self ];\
		if(!outlet) NSRunAlertPanel(@"SBook",@"Could not load nib named %@",nil,nil,nil,nib);\
	}\
	return outlet;\
}




     OutletForNib(bulkEmailer,@"bulkemailer")
     OutletForNib(infoPanel,@"info")
     OutletForNib(inspector,@"Inspector")
     OutletForNib(mailingLabels,@"mailinglabels")
     OutletForNib(openURLField,@"UrlOpener")
     OutletForNib(importingTabAlertPanel,@"ImportingTabAlertPanel")
     OutletForNib(passphraseEnterPanel,@"PassphraseEnter")

- getNibOutlet:(id *)outlet name:nibName
{
    if(*outlet) return *outlet;
    [NSBundle loadNibNamed:nibName owner:self];
    if(!*outlet) NSRunAlertPanel(@"SBook",@"Could not load nib named %@",nil,nil,nil,nibName);
    return *outlet;
}

- passphraseCreatePanel
{
    return [self getNibOutlet:&passphraseCreatePanel name:@"PassphraseCreate"];
}


- (void)awakeFromNib
{
    if(debug && debug_menu_added==NO){
	[specialMenu
	    addItemWithTitle:@"memory debug"
	    action:@selector(memory_debug:)
	    keyEquivalent:@"z"];

	debug_menu_added = YES;
    }
    [self refreshSpecialMenu];
}

- (void)showInspector:sender
{
    [[[self	inspector] window] orderFront:self];
}

- (void)showLicense:sender
{
    NSString *str = [NSString stringWithFormat:@"open %@",
			      [[NSBundle mainBundle]
				  pathForResource:@"SBook5_License" ofType:@"rtf"]];
    system([str UTF8String]);
}


- (void)openURL:(id)sender
{
    id window = [[self openURLField] window];

    [window makeKeyAndOrderFront:self];
    if([NSApp runModalForWindow:window]){
	id ndc = [NSDocumentController sharedDocumentController];
	NSString *str = [openURLField stringValue];
	NSURL *url = [NSURL URLWithString:str];

	[ndc setShouldCreateUI:YES];
	[NSData dataWithContentsOfURL:url];
	[ndc makeDocumentWithContentsOfURL:url ofType:SBOOK_FILE_EXTENSION];
	[ndc openDocumentWithContentsOfURL:url display:YES];

    }
    [window orderOut:sender];
}

- (void)openURL_Okay:(id)sender
{
    [self newVersionAvailable];
    [NSApp stopModalWithCode:1];
}

- (void)openURL_Cancel:(id)sender
{
    [NSApp stopModalWithCode:0];
}


-(void)removeEmptyWindow		// remove an empty window if we find it
{
    NSEnumerator *en = [[[NSDocumentController sharedDocumentController]
			    documents] objectEnumerator];

    id obj;
    while(obj = [en nextObject]){
	if([obj isMemberOfClass:[SLC class]]){
	    if([obj fileName] == nil && [[obj window] isDocumentEdited] == NO){
		[obj close];
	    }
	}
    }
}


/* 
 * openAutoOpenFiles:
 * called when application starts up or when it is activated ---
 * open any files that are supposed to be opened automatically.
 */

- (void)openAutoOpenFiles
{
    id fm = [NSFileManager defaultManager];
    NSArray *array = [defaults objectForKey:DEF_OPEN_ON_LAUNCH];
    NSEnumerator *en = [array objectEnumerator];
    id obj;
    id dc = [NSDocumentController sharedDocumentController];
    int openedFiles=0;

    /* Open the startup files */
    while(obj = [en nextObject]){
	if([fm fileExistsAtPath:obj]){
	    if(openedFiles==0){
		/* Remove any empty window that we can find */
		[self removeEmptyWindow];
	    }
	    [dc openDocumentWithContentsOfFile:obj display:YES];
	    openedFiles++;
	}
	else{
	    NSRunAlertPanel(@"SBook5",@"File %@ not found",0,0,0,obj);
	}
    }
}


- (void)appDidInit:sender
{
    /* Find out our build date from build.txt */
    build = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle]
				    pathForResource:@"build" ofType:@"txt"]] intValue];


    /* Check for a new version */
    if([[defaults objectForKey:DEF_CHECK_ON_LAUNCH] intValue]){
	NSMutableString *url = [NSMutableString stringWithString:SBOOK_BUILD_URL];

	[url appendString:@"?myversion="];
	[url appendString:[self appVersion]];
	[url replaceString:@" " withString:@"+" global:YES];

	NSLog(@"Checking for a new version at %@",url);
	newVersionURL = [[NSURL URLWithString:url] retain];
	newVersionURLHandle = [newVersionURL URLHandleUsingCache:YES];
	[newVersionURLHandle addClient:self];
	[newVersionURLHandle loadInBackground];
    }

    [self openAutoOpenFiles];

    [NSApp setServicesProvider:self];    /* Register for services */

    /* Finally, scan for plug-ins */
    [self scanDirectoryForPlugins:[[NSBundle mainBundle] builtInPlugInsPath]];
    [self scanDirectoryForPlugins:@"/Library/Application Support/SBook5"];
    [self scanDirectoryForPlugins:[NSString stringWithFormat:@"%s/Library/Application Support/SBook5",getenv("HOME")]];
}

- (BOOL)willOpenFileOnStartup:(NSString *)filename
{
    NSArray *array = [defaults objectForKey:DEF_OPEN_ON_LAUNCH];
    return [array containsObject:filename ? filename : @""];
}

- (void)setOpenFileOnStartup:(NSString *)filename toValue:(BOOL)shouldOpen
{
    if([self willOpenFileOnStartup:filename] == shouldOpen) return; // no change

    NSMutableArray *array= [NSMutableArray arrayWithArray:[defaults objectForKey:DEF_OPEN_ON_LAUNCH]];
    if(shouldOpen){
	[array addObject:filename];
    }
    else{
	[array removeObject:filename];
    }
    [defaults setObject:array forKey:DEF_OPEN_ON_LAUNCH]; // not sure if this is needed
    [defaults synchronize];		// make sure it gets written
    [preferencePanel reloadFromDefaults];		// if it is loaded, we get it
}


- (BOOL)fileInSpecialMenu:(NSString *)filename
{
    NSArray *array = [defaults objectForKey:DEF_FILES_IN_SPECIAL_MENU];
    return [array containsObject:filename ? filename : @""];
}

- (void)setFileInSpecialMenu:(NSString *)filename toValue:(BOOL)shouldShow
{
    if([self fileInSpecialMenu:filename] == shouldShow) return ; // no change

    NSMutableArray *array = [NSMutableArray arrayWithArray:[defaults objectForKey:DEF_FILES_IN_SPECIAL_MENU]];
    if(shouldShow){
	[array addObject:filename];
    }
    else{
	[array removeObject:filename];
    }
    [defaults setObject:array forKey:DEF_FILES_IN_SPECIAL_MENU]; // not sure if this is needed
    [defaults synchronize];		// make sure it gets written
    [self refreshSpecialMenu];
}


- (void)refreshSpecialMenu
{
    NSEnumerator *en = [[specialMenu itemArray] objectEnumerator];
    NSMenuItem *obj;
    NSString *fileName;

    /* Remove all of the old ones */
    while(obj = [en nextObject]){
	if([obj action] == @selector(openSpecialItem:)){
	    [specialMenu removeItem:obj];
	}
    }

    /* Add new ones */
    NSArray *fileNameArray = [defaults objectForKey:DEF_FILES_IN_SPECIAL_MENU];
    en = [fileNameArray objectEnumerator];
    while(fileName = [en nextObject]){
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:fileName
					       action:@selector(openSpecialItem:)
					       keyEquivalent:@""];
	[item setEnabled:YES];
	[item setTag:[fileNameArray indexOfObject:fileName]];
	[specialMenu addItem:item];
    }
}


- (void)openSpecialItem:sender
{
    NSArray *fileNameArray = [defaults objectForKey:DEF_FILES_IN_SPECIAL_MENU];
    NSString *fileName = [fileNameArray objectAtIndex:[sender tag]];
    NSDocumentController *c = [NSDocumentController sharedDocumentController];
    
    id doc = [c documentForFileName:fileName];
    if(doc){
	[[doc window] makeKeyAndOrderFront:nil];
	return;
    }
    
    [c openDocumentWithContentsOfFile:fileName display:YES];
}

- (void)setStatus:(NSString *)str
{
    [[[NSApp mainWindow] delegate] setStatus:str];
}


- (IBAction)bugsAndSuggestions:sender
{
    NSString *subject = [NSString stringWithFormat:@"SBook %@ bug:suggestion",
				  [self appVersion]];

    [Emailer sendMailTo:@"sbook-owner@nitroba.com" cc:0 subject:subject body:nil];
}

- (IBAction)newInThisRelease:sender
{
    [[NSWorkspace sharedWorkspace]
	openFile:[[NSBundle mainBundle] pathForResource:@"changes" ofType:@"html"]];
}

- (IBAction)knownBugsInThisRelease:sender
{
    [[NSWorkspace sharedWorkspace]
	openFile:[[NSBundle mainBundle] pathForResource:@"bugs" ofType:@"html"]];
}

/****************************************************************
 ** Import into a new file
 ****************************************************************/

- (void)import:sender
{
    /* Importing into a new file.
     * Create an empty document and get it to import.
     */
    id ndc = [NSDocumentController sharedDocumentController];
    [ndc newDocument:nil];
    [[ndc currentDocument] importCurrent:sender];
     
}

/****************************************************************
 ** check for new version
 ****************************************************************/

- (NSString *)newVersionAvailable
{
    return newVersionAvailable;
}

- (void)URLHandle:(NSURLHandle *)sender resourceDataDidBecomeAvailable:(NSData *)newBytes
{
}
- (void)URLHandleResourceDidBeginLoading:(NSURLHandle *)sender
{
}

- (void)URLHandleResourceDidFinishLoading:(NSURLHandle *)sender
{
    NSString *str  = [[NSString alloc] initWithData:[newVersionURLHandle availableResourceData]
				       encoding:NSASCIIStringEncoding];
    if([str intValue] > build){
	int loc = [str rangeOfString:@"\n"].location;
	if(loc>1){
	    str = [str substringFromIndex:loc+1];
	    loc = [str rangeOfString:@"\n"].location;
	    if(loc>1){
		str = [str substringToIndex:loc];
	    }
	    newVersionAvailable = [str retain];
	}
    }
}
- (void)URLHandleResourceDidCancelLoading:(NSURLHandle *)sender
{
}
- (void)URLHandle:(NSURLHandle *)sender resourceDidFailLoadingWithReason:(NSString *)reason
{
}

/****************************************************************
 ** SERVICES
 ****************************************************************/

- (void)makeNewEntry:(NSPasteboard *)pboard
	    userData:(NSString *)userData
	       error:(NSString **)error
{
    SLC *slc=nil;
    NSDocumentController *sdc = [NSDocumentController sharedDocumentController];

    [pboard types];			// get the types

    /* Create a new entry
     * Add it to the SList.
     * load it.
     */

    slc = [SLC lastActiveSLC]; // find the most likely SLC
    if(!slc){
	NSArray *documents = [sdc documents];

	if([documents count]>0){
	    slc = [documents objectAtIndex:0];
	}
    }

    /* if no SLC, create a new one */
    if(!slc){
	[sdc newDocument:self];
    
	slc = [[sdc documents] objectAtIndex:0];
    }

    [slc addAndDisplayData:[pboard dataForType:NSStringPboardType]];
}


- (void)printEnvelope:(NSPasteboard *)pboard
	     userData:(NSString *)userData
		error:(NSString **)error
{
    [pboard types];			// get the types

    [reportBundleClassInstance
	printEnvelope:nil address:[pboard stringForType:NSStringPboardType] forWindow:nil];
}

- (void)dialNumber:(NSPasteboard *)pboard
	 userData:(NSString *)userData
	    error:(NSString **)error
{
    [pboard types];			// get the types

    [localizedDialer dial:[pboard stringForType:NSStringPboardType]
	  withLocalRules:YES
	  forWindow:nil];
}

/****************************************************************
 ** Menu stuff
 ****************************************************************/

- (BOOL)validateMenuItem:(id <NSMenuItem>)item
{
    SEL action = [item action];

    //NSLog(@"SBookController: validate %@ %@",item,[item title]);
    if(action == @selector(import:) ||
       action == @selector(bugsAndSuggestions:) || 
       action == @selector(newInThisRelease:) ||
       action == @selector(knownBugsInThisRelease:) ||
       action == @selector(printOneEnvelope:) ||
       action == @selector(showLicense:)){
	return YES;
    }

    /* Special Menu */
    if(action == @selector(openSpecialItem:)){
	return YES;
    }

    

    /* Help menu */
    if(action  == @selector(showHelp:)){
	return NO;
    }

    if([item action] == @selector(showInspector:)){
	if([NSApp mainWindow]) return YES;
	return NO;
    }
    return [super validateMenuItem:item];
}

/****************************************************************
 ** Delegate stuff
 ****************************************************************/

/* Don't create an untitled file if there are autolaunch items */
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    
    NSArray *array = [defaults objectForKey:DEF_OPEN_ON_LAUNCH];

    if([array count]>0){
	return NO;
    }
    return YES;

}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    id mainDelegate =     [[NSApp mainWindow] delegate];

    if([[defaults objectForKey:DEF_OPEN_ON_ACTIVATE] intValue]){
	[self openAutoOpenFiles];
    }
    if([mainDelegate isKindOfClass:[SLC class]]){
	[mainDelegate delegateDidBecomeActive:notification];
    }
}

/* If we get this, and there is no SLC, then create a new one */
- (void)newEntry:(id)sender
{
    [[NSDocumentController sharedDocumentController] newDocument:sender];
}


- (void)dial:(NSString *)number withRules:(bool)useRules forWindow:(NSWindow *)aWindow
{
}

- (void)printEnvelope:(Person *)aPerson address:(NSString *)addr forWindow:(NSWindow *)aWindow
{
    [reportBundleClassInstance
	printEnvelope:aPerson
	address:addr
	forWindow:aWindow];
}

@end


@implementation SBookController(Helpers)

-(int)debug
{
    return debug;
}

-(Class)PersonClass
{
    return [Person class];
}

-(void)find:(const char *)line city:(char **)city state:(char **)state zip:(char **)zip
{
    find_cityStateZip(line,city,state,zip);
}

-(unsigned int)parse_company:(const char *)buf
{
    return parse_company(buf);
}


-(unsigned int)parse_telephone:(const char *)buf arg:(unsigned int *)arg
{
    return parse_telephone(buf,arg);
}

-(unsigned int)identifyLine:(const char *)buf
{
    return identify_line(buf);
}

-(void)extractLabel:(const char *)line toBuf:(char *)buf
{
    extract_label(line,buf);
}

- (id)DefaultSwitchSetterClass
{
    return [DefaultSwitchSetter class];
}


-(SLC *)currentSLCNoSave
{
    id delegate = [[NSApp mainWindow] delegate];
    if([delegate isKindOfClass:[SLC class]]){
	return delegate;
    }
    return nil;
}

-(SLC *)currentSLC
{
    id delegate = [[NSApp mainWindow] delegate];
    if([delegate isKindOfClass:[SLC class]]){
	[delegate saveEntry];
	return delegate;
    }
    return nil;
}


-(Person *)currentPersonNoSave
{
    return [[self currentSLCNoSave] displayedPerson];
}

-(Person *)currentPerson	
{
    Person *per = [[self currentSLC] displayedPerson];
    return per;
}

@end
  
