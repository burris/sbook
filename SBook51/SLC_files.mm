/*
 * SLC file operations.
 */

#import "SLC.h"
#import "Person.h"
#import "SList.h"
#import "metaphone.h"
#import "SBookController.h"
#import "tools.h"
#import "defines.h"
#import "ExportFileInfoView.h"
#import "SBookIconView.h"
#import "SBookText.h"
#import "PassphrasePanel.h"
#import "RangePanel.h"
#import "ProgressPanel.h"
#import "SWindow.h"
#import "ExportingTableView.h"
#import "DefaultSwitchSetter.h"

#import <unistd.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <fcntl.h>
#import <dirent.h>

NSString *defaultFileFormat = @"SBook XML";

@implementation SLC(files)

/****************************************************************
 ** COCOA DOCUMENT STUFF
 ****************************************************************/



- (BOOL)isFileSBookXML:(NSString *)fname
{
    NSString *firstLine = [NSString stringWithFirstLineOfFile:fname];
    if([firstLine length]<6) return NO;
    
    return [[firstLine substringToIndex:6] isEqualTo:@"<?xml "];

}


- (NSString *)windowNibName
{
    return @"SLC";
}

- (BOOL)keepBackupFile { return YES;}	// backups are important

/* Called to do an autosave */
- (void) autosave:(NSTimer *)t
{
    if([self fileName] && [self isDocumentEdited]){
	[self saveDocument:self];	// save!
    }
}

/* Called to check for a new document. */
- (void) autocheck:(NSTimer *)t
{
    if([fileChangeString isEqualTo:[NSString fileChangeString:[self fileName]]]==NO){
	[self refreshDocument:self];
    }
}

/* Note: do not release the timers; invalidate will do that. */
- (void) removeTimers
{
    /* Make sure current timers are not valid */
    [autocheckTimer invalidate];
    autocheckTimer = 0;

    [autosaveTimer invalidate];
    autosaveTimer = 0;
}

- (void) scheduleTimers
{
    int autocheckInterval = [[defaults objectForKey:DEF_AUTOCHECK_INTERVAL] intValue];
    int autosaveInterval  = [[defaults objectForKey:DEF_AUTOSAVE_INTERVAL] intValue];    

    [self removeTimers];
    
    if(autocheckInterval<1) autocheckInterval = 1;
    if(autosaveInterval<1) autosaveInterval = 1;

    if([[defaults objectForKey:DEF_AUTOCHECK_ENABLE] intValue]){
	autocheckTimer =
	    [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)autocheckInterval
		     target:self
		     selector:@selector(autocheck:)
		     userInfo:nil repeats:YES];
    }

    if([[defaults objectForKey:DEF_AUTOSAVE_ENABLE] intValue]){
	autosaveTimer =
	    [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)autosaveInterval
		     target:self
		     selector:@selector(autosave:)
		     userInfo:nil repeats:YES];
    }
}


/****************************************************************
 ** Normal File Loading And Saving
 ****************************************************************/

- (void)setFileName:(NSString *)fileName
{
    NSArray *wdcArray = [self windowControllers];

    if([wdcArray count]>0){
	NSWindowController *wdc = [wdcArray objectAtIndex:0];

	if([[wdc windowFrameAutosaveName] length]==0){
	    NSRect r;

	    /* remove the old autosave name */
	    NSMutableString *key = [NSMutableString stringWithString:@"NSWindow Frame "];
	    [key appendString:fileName];
	    [defaults removeObjectForKey:key];
	    
	    /* And set that as our autosave location */
	    [wdc setWindowFrameAutosaveName:fileName];

	    /* And now deal with the Cocoa bug - autosave names don't get recorded until the document moves */
	    r = [[wdc window] frame];
	    r.origin.x += 1;
	    [[wdc window] setFrame:r display:YES];

	    r.origin.x -= 1;
	    [[wdc window] setFrame:r display:YES];

	    /* Register the NSSlider Position */
	    [self sliderPositionSetup];
	}
    }
    [super setFileName:fileName];
}



- (NSString *)fileTypeFromLastRunSavePanel
{
    return TYPE_SBOOK_XML;
}


- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    [self  saveEntry];		// save currently displayed entry
    //NSLog(@"dataRepresentationOfType %@",aType);
    return [doc xmlRepresentation];
}


/* Check for a lockfile;
 * Spin if present for 30 seconds. At end of that time, return TRUE.
 */
- (BOOL)getLockFile
{
    int i;

    assert(lockFileName==nil);
    if([self fileName]==nil) return YES; // don't know name for lockfile, pretend we got it
    lockFileName = [NSString stringWithFormat:@"%@.lock",[self fileName]];


    for(i=0;i<300;i++){
	int fd = open([lockFileName UTF8String],O_CREAT | O_TRUNC | O_EXCL | O_WRONLY,0666);
	if(fd>=0){
	    close(fd);
	    [lockFileName retain];
	    return YES;
	}
	[self setStatus:@"Waiting for lockfile..."];
	usleep(100 * 1000);
	if(i>295){
	    [self setStatus:@"Erasing lockfile!"];
	    if(unlink([lockFileName UTF8String])){
		NSRunAlertPanel(@"Erase",
				@"Could not erase lockfile; you must have a permissions problem on the file %@",0,0,0,lockFileName);
		lockFileName = nil;
		return NO;
	    }
	}
    }
    [self setStatus:@"Could not erase lockfile!"];
    lockFileName = nil;
    return NO;
}

- (void)releaseLockFile
{
    unlink([lockFileName UTF8String]);
    [lockFileName release];
    lockFileName = nil;
}


- (BOOL)writeToFile:(NSString *)fullDocumentPath ofType:(NSString *)documentTypeName originalFile:(NSString *)fullOriginalDocumentPath saveOperation:(NSSaveOperationType)saveOperationType
{
    BOOL res;

    if(debug){
	NSLog(@"writeToFile:%@ ofType:%@ originalFile:%@ saveOperation:%d filename:%@",
	      fullDocumentPath,documentTypeName,fullOriginalDocumentPath,saveOperationType,
	      [self fileName]);
    }
    
    if([self getLockFile]==NO){
	return NO;
    }

    res = [super writeToFile:fullDocumentPath ofType:documentTypeName
		 originalFile:fullOriginalDocumentPath
		 saveOperation:saveOperationType];
    if(res){
	[self setFileChangeString:[NSString fileChangeString:fullDocumentPath]];
    }

    [self releaseLockFile];
    return res;
}


- (IBAction)saveDocument:(id)sender;
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [self	setStatus:@"Saving..."];
    [nc		postNotificationName:SBookWillSaveFileNotification object:self];
    [super	saveDocument:sender];	// do the save
    [self	setStatus:@"Saved"];
    [nc		postNotificationName:SBookDidSaveFileNotification object:self];

}

- (IBAction)revertDocumentToSaved:(id)sender
{
    [super revertDocumentToSaved:sender];
    [self displayPersonList:NO];
    [self forcePersonRedisplay];
    [self search:self];		// turns out you need to do a new search
    
}


/****************************************************************
 ** LOADING
 ****************************************************************/

/* This is where the file is read */
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    id newDoc = SList_txtread(data);

    if(newDoc){
	[self		setDoc:newDoc];
	[self		setFileChangeString:[NSString fileChangeString:[self fileName]]];
	[nameTable	setColumnOneMode];
	return YES;
    }
    NSLog(@"Unknown representation '%@'",aType);
    return NO;
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type
{
    //    NSLog(@"readFromFile:ofType:");
    return [super readFromFile:fileName ofType:type];
}

/****************************************************************
 ** SAVE PANEL
 ****************************************************************/

- (BOOL)shouldRunSavePanelWithAccessoryView
{
    return NO;				// use ours
}

- (BOOL)prepareSavePanel:(NSSavePanel *)sp
{
    //[saveFiletypePopup setTitle:defaultFileFormat];
    NSString *fname = [self fileName];


    [openFileAutomatically setState:[AppDelegate willOpenFileOnStartup:fname]];
    [sp setAccessoryView:openFileAutomatically]; 
    [openFileAutomatically retain];	// because it will be released, and we don't want that.

    [sp setCanSelectHiddenExtension:TRUE];
    [sp setRequiredFileType:SBOOK_FILE_EXTENSION]; // default to SBookXML
    return YES;
}


- (void)saveToFile:(NSString *)fileName saveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
    if(fileName){
	[AppDelegate setOpenFileOnStartup:fileName toValue:[openFileAutomatically state]];
    }
    [super saveToFile:fileName saveOperation:saveOperation delegate:delegate
	   didSaveSelector:didSaveSelector contextInfo:contextInfo];
}



/****************************************************************
 ** IMPORT 
 ****************************************************************/

- (void)import:(id)sender
{
    int ret;
    
    /* If we have no entries in this book, just import to the current */
    if([doc numPeople]==0){
	[self importCurrent:sender];
	return;
    }

    /* Otherwise, ask if it is to be a new one or the current one */

    ret = NSRunAlertPanel(@"SBook Import",
			  @"Import into the current file or a new one?",
			  @"New",@"Cancel",@"Current");
    if(ret==0) return;			// cancel
    if(ret==1){
	[AppDelegate import:sender];	// ask the application to import into a new file
    }
    else{
	[self importCurrent:sender];
    }
}

- (void)importCurrent:(id)sender
{
    id pan = [NSOpenPanel openPanel];

    if(!importAccessoryView){
	[NSBundle loadNibNamed:@"ImportAccessoryView" owner:self ];
	[importAccessoryView retain];	// so it doesn't get thrown out when window is closed
    }

    [pan setAccessoryView:importAccessoryView];

    [pan beginSheetForDirectory:nil file:nil types:nil modalForWindow:[self window]
	 modalDelegate:self
	 didEndSelector:@selector(importingOpenPanelDidEnd:returnCode:contextInfo:)
	 contextInfo:nil];
}

/*
 * Import a list of filenames into the current list.
 */
-(void)importSBookXMLFilenameArray:(NSArray *)filenames flag:(int)flag
{
    NSEnumerator *en;
    id	file;
    int	sortFlagHold = 0;
    int count=0;
    NSMutableDictionary *omitDict = nil;
    NSMutableArray *undoArray = [NSMutableArray array];
    BOOL omitFlag = flag & IMPORT_OMIT_DUPLICATES;
    BOOL replaceUpdated = flag & IMPORT_REPLACE_UPDATED;
    
    if(omitFlag){
	omitDict = [NSMutableDictionary dictionary];
    }

    sortFlagHold = [doc queryFlag:SLIST_SORT_FLAG];
    [doc setFlag:SLIST_SORT_FLAG toValue:0];

    [self displayPersonEntry:nil append:NO];
    [importProgress setMinValue:0];
    [importProgress setDoubleValue:0];
    en = [filenames objectEnumerator];
    while(file = [en nextObject]){

	SList *doc2;
	NSEnumerator *en2;
	Person *per;

	/* First read the contents of the requested file */
	doc2 = SList_txtread([NSData dataWithContentsOfFile:file]); // import to a temp SList

	/* Now add and display each one */
	en2 = [doc2 personEnumerator];
	[importProgress setMaxValue:(double)[doc2 numPeople]];
	while(per = [en2 nextObject]){
	    [importProgress incrementBy:1.0];
	    if(omitFlag){
		/* Get the MD5 for this person */
		NSData *md5 = [per asciiMD5];
		if([omitDict objectForKey:md5]){
		    continue;		// skip adding
		}
		[omitDict setObject:per forKey:md5]; // add it
	    }
	    Person *oldPer = [doc personWithGid:[per gid]];
	    if(oldPer){
		/* We have this person already. See if it has modified */
		if([oldPer mtime]==[per mtime]){
		    continue;		// mtimes are the same
		}
		if([[oldPer rtfdMD5] isEqualTo:[per rtfdMD5]]){
		    continue;		// MD5s are the same
		}
		if(replaceUpdated){
		    if([oldPer mtime] < [per mtime]){
			[doc removePerson:oldPer]; // remove the older version
		    }
		    else {
			continue;	// don't add the newer version
		    }
		}
	    }
	    
	    [doc  addPerson:per];
	    [undoArray addObject:per];
	    count++;
	}
    }
    [doc setFlag:SLIST_SORT_FLAG toValue:sortFlagHold];
    [self displayAll:self];
    [self notifyImportCount:count];

    [nameTable deselectAll:self];	// don't select anything.
    if([visibleList count]>0){
	[self setTextChanged:TRUE];
    }

    if(count>0){
	[[self undoManager] registerUndoWithTarget:self
			    selector:@selector(removePeople:)
			    object:undoArray];
	[[self undoManager] setActionName:[NSString stringWithFormat:@"Import %d %s",count,count==1 ? "entry" : "entries"]];
    }
}

/* use for importing */
- (void)importingOpenPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode
	    contextInfo:(void *)contextInfo
{
    int flag = IMPORT_OMIT_DUPLICATES | IMPORT_REPLACE_UPDATED;

    if(!returnCode) return;		// do not import

    [self importSBookXMLFilenameArray:[sheet filenames] flag:flag ];
    
}

- (void)notifyImportCount:(int)count
{
    [self setStatus:[NSString stringWithFormat:@"%@ imported\n%d now in file",
			      [self entryCountString:count],
			      [doc numPeople]]];
}


/****************************************************************
 ** EXPORT
 ****************************************************************/


- (void)exportToFile2:(id)sender
{
    id pan = [NSSavePanel savePanel];

    if(exportFileInfoView==nil){	// our own private copy
	[NSBundle loadNibNamed:@"FileExporter" owner:self ];
    }
    [exportFileInfoView setSavePanel:pan]; // because it may have changed
    [exportFileInfoView setDefaultFormat];
    [exportFileInfoView setSLC:self];
    [exportFileInfoView setExportArray:[[self rangePanel] selected]];

    [pan setAccessoryView:exportFileInfoView];
    [pan beginSheetForDirectory:nil file:nil modalForWindow:[self window]
	 modalDelegate:exportFileInfoView
	 didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
	 contextInfo:nil];
}

- (void)exportToFile:(id)sender
{
    [[self rangePanel] runAsSheet:[self window]
		       title:@"Export To File"
		       slc: self endTarget:self didEndSelector:@selector(exportToFile2:)];
}

- (NSString *)vCardExportToPath:(NSString *)path removeFlag:(BOOL)flag
{
    /* Save vcards for all */
    NSEnumerator *en = [doc personEnumerator];
    Person *person;
    struct stat st;
    ProgressPanel *pan = [self progressPanel];
    int count=0;

    mkdir([path UTF8String],0777);		// create the directory, in case it doesn't exist
    if(stat([path UTF8String],&st)){
	NSRunAlertPanel(@"vCard export",@"Cannot create directory %@: %s",nil,nil,nil,
		      path,strerror(errno));
	return nil;				// give up
    }

    if(flag){
	/* Remove all of the .vcf files from the directory */
	NSMutableArray *delArray = [NSMutableArray array];
	DIR *dir = opendir([path UTF8String]);
	struct dirent *dp;
	NSEnumerator *en;
	id obj;
	if(!dir){
	    NSRunAlertPanel(@"vCard export",@"Cannot open directory %@ for reading",nil,nil,nil,
			    path);
	    return nil;
	}
	while(dp = readdir(dir)){
	    if(dp->d_namlen > 5 &&
	       dp->d_name[dp->d_namlen-4]=='.' &&
	       dp->d_name[dp->d_namlen-3]=='v' &&
	       dp->d_name[dp->d_namlen-2]=='c' &&
	       dp->d_name[dp->d_namlen-1]=='f'){
	       
		NSString *fullPath = [NSString stringWithFormat:@"%@/%s",path,dp->d_name];
		[delArray addObject:fullPath];
	    }
	}
	closedir(dir);

	en = [delArray objectEnumerator];
	while(obj = [en nextObject]){
		
	    if(unlink([obj UTF8String])){
		if(NSRunAlertPanel(@"vCard export",@"Cannot delete file: %@: %s",
				   @"Okay",@"Cancel",nil,
				   obj,strerror(errno))==0){
		    return nil;		// we were canceled
		}
	    }
	}
    }

    [pan setMinValue:0.0];
    [pan setMaxValue:(double)[doc numPeople]];
    [pan setDoubleValue:0.0];
    [pan setIndeterminate:NO];
    [pan setBigMessage:@"Exporting vCards..."];
    [pan setSmallMessage:
	     [NSString stringWithFormat:@"A total of %d vCard%s will be exported. This may take a few moments...",
		       [doc numPeople],
		       [doc numPeople]==1 ? "" : "s"]];

    [pan runWithWindow:[self window]];
    // [pan center];
    // [pan makeKeyAndOrderFront:nil];
    
    while((person = [en nextObject]) && ([pan checkForCancel]==NO)){
	int i;
	for(i=0;i<1000;i++){		// try no more than .1000
	    //NSMutableString *str = [NSMutableString stringWithString:path];
	    //NSMutableString *cn  = [NSMutableString stringWithString:[person cellName]];
	    NSMutableString *str = [[path mutableCopy] autorelease];
	    NSMutableString *cn  = [[[person cellName] mutableCopy] autorelease];
	    NSString *vcard = nil;

	    [cn removeFromString:':'];
	    [cn removeFromString:'/'];
	    [cn replaceString:@" " withString:@"_" global:YES];
	    

	    [str appendString:@"/"];
	    [str appendString:cn];
	    if(i>0){
		[str appendFormat:@".%d",i];
	    }
	    [str appendString:@".vcf"];
	    vcard = [person vCard:NO];
	    if([vcard writeToFile:str atomically:YES]){
		count += 1;
		[pan setDoubleValue:(double)count];
	    }
	    goto done;
	}
	NSRunAlertPanel(@"vCard export:",@"Could not create vCard for %@ in directory %@s: %s",
		      nil,nil,nil,
		      [person cellName],path,strerror(errno));
	[self setTextStatus:@""];		// remove the bar
	[pan  runDone];
	return nil;
	
    done:;
    }
    [pan  runDone];
    return [NSString stringWithFormat:@"Exported %i vCard%s to %@",
		     (int)count,(count==1) ? "" : "s",
		     path];
}



- (IBAction)exportToiPod:(id)sender
{
    /* Find the iPod */
    int count=0; 
    DIR *dir;
    struct dirent *dp;

    if([doc numPeople]>999){
	NSRunAlertPanel(@"iPod Export",
			   @"There are more than 1000 entries in your address book. Release 1.1 of the iPod software will only display the first 1000 exported entries. If you think that this behavior doesn't make any sense, please contact Apple and voice your opinion.",nil,nil,nil);
    }
    dir = opendir("/Volumes/");
    if(!dir){
	NSRunAlertPanel(@"opendir",@"Cannot open directory /Volumes/:%s",nil,nil,nil,strerror(errno));
	return;
    }
    while(dp = readdir(dir)){
	NSString *path1 = [NSString stringWithFormat:@"/Volumes/%s/Contacts/",dp->d_name];
	NSString *path2 = [NSString stringWithFormat:@"/Volumes/%s/iPod_Control/",dp->d_name];

	if([path1 directoryExists] &&
	   [path2 directoryExists]){
	    id res;

	    [self setStatus:[NSString stringWithFormat:@"Exporting to %s",dp->d_name]];
	    res = [self vCardExportToPath:path1 removeFlag:YES];
	    [self setStatus:res];
	    count++;
	}
    }
    closedir(dir);
    if(count==0){
	NSRunAlertPanel(@"iPod Export",@"Could not find an iPod. Please verify connection and that your iPod is running release 1.1 of the iPod software and that 'Enable firewire usage' is selected in iTunes.",
			0,0,0);
    }
}

- (IBAction)exportTovCards:(id)sender
{
    NSOpenPanel *pan = [NSOpenPanel openPanel];

    [pan setCanChooseDirectories:YES];
    [pan setCanChooseFiles:NO];
    [pan setAllowsMultipleSelection:NO];
    [pan setTitle:@"Specify a directory for vCards"];

    if(removeExistingvCardsButton==nil){
	[NSBundle loadNibNamed:@"DirectoryExporter" owner:self];
	[removeExistingvCardsButton retain];
    }
    [pan setAccessoryView:removeExistingvCardsButton];
    [pan beginSheetForDirectory:nil file:nil types:nil modalForWindow:[self window]
	 modalDelegate:self didEndSelector:@selector(exportVcardOpenPanelDidEnd:returnCode:contextInfo:)
	 contextInfo:0];
}

- (void)exportVcardOpenPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode){
	removeExistingvCards = [removeExistingvCardsButton intValue];
	[vcardDir release];
	vcardDir = [[sheet filename] retain];

	[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(delayedvCardExport) userInfo:nil repeats:NO];
    }
}

- (void)delayedvCardExport
{
    [self vCardExportToPath:vcardDir removeFlag:removeExistingvCards];
    [vcardDir release];
    vcardDir = 0;
}


/****************************************************************
 *** PASTEBOARD IMPLEMENTATION
 ****************************************************************/
#ifdef new
- (void)copyPeopleArray:(NSArray *)people toPasteboard:(NSPasteboard *)pb
{
    NSArray *types = [NSArray arrayWithObjects:
				  TYPE_SBOOK_ARRAY, // SBook_array to drag from one SBook to another
			      NSFilenamesPboardType,
			      NSVCardPboardType, // Allows dragging to a program that expects vcards
			      //NSFilesPromisePboardType,
			      //TYPE_SBOOK_ASCII,	// bring it in as SBook ASCII
			      //NSFileContentsPboardType,	
			      //NSStringPboardType,
			      0];
    NSData *peopleData    = [NSArchiver archivedDataWithRootObject:people];

    [pb declareTypes:types owner:self];
    [pb setData:peopleData forType:TYPE_SBOOK_ARRAY];
    NSLog(@"put %@ on the pasteboard",types);
}
#endif

NSString *NXFPT = @"NeXT filename pasteboard type";

/****************************************************************
 *** PASTEBOARD DESIGN
 ****************************************************************/
- (void)copyPeopleArray:(NSArray *)people toPasteboard:(NSPasteboard *)pb
{
    NSArray *types = [NSArray arrayWithObjects:TYPE_SBOOK_ARRAY,
			      NSVCardPboardType, 
			      ABVCardPBoardType,
			      NSFilesPromisePboardType,
			      NSFilenamesPboardType,
			      NXFPT,
			      TYPE_SBOOK_ASCII,
			      //NSStringPboardType,
			      0];
    NSData *peopleData    = [NSArchiver archivedDataWithRootObject:people];

    [pb declareTypes:types owner:self];
    [pb setData:peopleData forType:TYPE_SBOOK_ARRAY];
}



- (void)pasteboard:(NSPasteboard *)pb provideDataForType:(NSString *)type
{
    NSArray *people = [NSUnarchiver
			  unarchiveObjectWithData:[pb dataForType:TYPE_SBOOK_ARRAY]];

    NSLog(@"SLC_files.mm: pasteboard:provideDataForType:%@",type);

    /* If they want either SBOOK ASCII or a string, put the string on the pasteboard */
    if([type isEqualToString:TYPE_SBOOK_ASCII] ||
       [type isEqualToString:NSStringPboardType]){
	NSString *str = [Person SBookAsciiForPeople:people];

	[pb setString:str forType:TYPE_SBOOK_ASCII];
	[pb setString:str forType:NSStringPboardType];
	return;
    }
    /* If they want a vCard... */
    if([type isEqualToString:NSVCardPboardType] ||
       [type isEqualToString:ABVCardPBoardType]){
	NSString *vCard = [Person vCardForPeople:people];
	[pb setString:vCard forType:NSVCardPboardType];
	[pb setString:vCard forType:ABVCardPBoardType];
	return;
    }

    if([type isEqualToString:NSFilenamesPboardType] ||
       [type isEqualToString:NSFilesPromisePboardType] ||
       [type isEqualToString:NXFPT] ){
	SList *list = [SList slistWithPeople:people]; // get the SList...
	char buf[1024];
	int i=0;

	NSString *fname;

	do {
	    if(i==0){
		fname = [NSString stringWithFormat:@"/tmp/%@.%@",
				  [[people objectAtIndex:0] cellName],
				  VCARD_FILE_EXTENSION];
	    }
	    else {
		fname = [NSString stringWithFormat:@"/tmp/%@%d.%@",
				  [[people objectAtIndex:0] cellName],
				  i, VCARD_FILE_EXTENSION];
	    }
	    if(access([fname lossyCString],R_OK)!=0){
		break;
	    }
	} while(++i < 10000);		// should be enough

	strcpy(buf,[fname UTF8String]);
	NSLog(@"tempfile=%s",buf);
	
	NSString *vCards = [Person vCardForPeople:[list allPeople]];
	[vCards writeToFile:fname atomically:YES];
	
	/* Now create an array of the filenames for the reply... */
	
	NSArray *fnamesArray = [NSArray arrayWithObjects:fname,0];
	[pb setPropertyList:fnamesArray forType:NSFilenamesPboardType];
	[pb setPropertyList:fnamesArray forType:NSFilesPromisePboardType];
	[pb setPropertyList:fnamesArray forType:NXFPT];
	return;
    }
    NSLog(@"SLC_files: pasteboard:provideDataForType: Cannot provide type %@",type);
}

/****************************************************************
 *** CUT AND PASTE
 ****************************************************************/

- (void)copySelectedToPasteboard:(NSPasteboard *)pb andRemove:(BOOL)removeFlag
{
    NSArray *array = [self selectedPeopleArray:removeFlag]; 

    [self copyPeopleArray:array toPasteboard:pb];
}



- (void)copy:sender
{
    [self copySelectedToPasteboard:[NSPasteboard generalPasteboard] andRemove:NO];
    [statusCell setStringValue:[NSString stringWithFormat:@"%d copied",[self numSelectedPeople]]];
}

- (IBAction)cut:sender
{
    int remain=0;
    char *plural = "";

    if([self numLockedSelectedPeople]>0){
	NSBeep();			// not allowed to cut locked people
	return;
    }

    [self copySelectedToPasteboard:[NSPasteboard generalPasteboard] andRemove:YES];

    remain = [doc numPeople];
    if(remain==1) plural="s";
    
    [statusCell setStringValue:[NSString stringWithFormat:@"%d cut; %d remain%s",
					 copyCutCount,remain,plural]];
    [[self undoManager] setActionName:copyCutCount==1 ? @"Cut Entry" : @"Cut Entries"];
}

- (IBAction)delete:sender
{
    int remain=0;
    char *plural = "";

    if([self numLockedSelectedPeople]>0){
	NSBeep();			// not allowed to cut locked people
	return;
    }

    [self copySelectedToPasteboard:nil andRemove:YES];

    remain = [doc numPeople];
    if(remain==1) plural="s";
    
    [statusCell setStringValue:[NSString stringWithFormat:@"%d deleted; %d remain%s",
					 copyCutCount,remain,plural]];
    if(copyCutCount>0){
	//[self	updateChangeCount:NSChangeDone];
    }
}

- (void)paste:sender
{
    [self pasteWithPasteboard:[NSPasteboard generalPasteboard]];
    [[self undoManager] setActionName:copyCutCount==1 ? @"Paste Entry" : @"Paste Entries"];
}

- (void)pasteWithPasteboard:(NSPasteboard *)pb
{
    NSData *peopleData=0;

    [pb types];

    /* If there is a list of people on the pasteboard, just paste in the entries
     * into the doc and add them to the display list.
     */

    peopleData = [pb dataForType:TYPE_SBOOK_ARRAY];
    if(peopleData){
	id peopleList = [NSUnarchiver unarchiveObjectWithData:peopleData];
	NSEnumerator *en = [peopleList objectEnumerator];
	Person *person;

	while(person = [en nextObject]){
	    [self addPerson:person select:YES];
	}
	[self displayPersonList:YES];

	[self setStatus:[NSString stringWithFormat:@"%d pasted; %d now in file",
				  [peopleList count],
				  [doc numPeople]]];

	//[self	updateChangeCount:NSChangeDone];
	return;
    }

    /* Oh well. I can't figure out what to do */
    NSBeep();
}

/****************************************************************
 ** VCard Support
 ****************************************************************/

- (BOOL)importVCard:(NSString *)vcard
{
    /* See if this one of our special cards... */
    NSRange r = [vcard rangeOfString:@"X-IMAGE2:"];
    if(r.length > 0){
	/* It is! Process it */
	NSRange eol = [vcard rangeOfString:@"\n"
			      options:0
			      range:NSMakeRange(r.location,[vcard length]-r.location)];
	if(eol.length>0){
	    BOOL added = FALSE;
	    NSString *base64 = [vcard substringWithRange:NSMakeRange(r.location+9,
								      eol.location-r.location-9)];
	    NSData *xmldata = [dataForB64String(base64) uncompress]; // it was compressed
	    /* Need to add that XML data */
	    SList *read = SList_xmlread(xmldata,nil); // see if this works
	    NSEnumerator *en = [read personEnumerator];
	    while(Person *person = [en nextObject] ){
		[self addAndDisplayPerson:person]; // grab the people
		
		added = TRUE;
	    }
	    return added;
	}
    }

    NSMutableArray *fields;
    NSMutableString *entry = [NSMutableString string];
    NSEnumerator *e2;
    NSString *f2;
    NSString *fn;

    NSMutableString *mvcard = [NSMutableString stringWithString:vcard];
    [mvcard replaceString:@"=0A=\n" withString:@"\n" global:YES];
    [mvcard removeFromString:'\r'];	// if it has them, remove them

    [mvcard replaceString:@"LABEL;DOM;WORK;PARCEL;POSTAL;ENCODING=QUOTED-PRINTABLE:"
	    withString:@"" global:YES];

    fields = [NSMutableArray arrayWithArray:[mvcard componentsSeparatedByString:@"\n"]];

    /* Implement the little vcard parser */
    /* First remove the vcard stuff */
    [fields stringWithPrefix:@"BEGIN:vCard" removeFromArray:YES removePrefix:NO];
    [fields stringWithPrefix:@"BEGIN:VCARD" removeFromArray:YES removePrefix:NO];
    [fields stringWithPrefix:@"END:vCard" removeFromArray:YES removePrefix:NO];
    [fields stringWithPrefix:@"END:VCARD" removeFromArray:YES removePrefix:NO];
    [fields stringWithPrefix:@"VERSION:"  removeFromArray:YES removePrefix:NO];
    [fields stringWithPrefix:@"X-GWTYPE:USER" removeFromArray:YES removePrefix:NO];
    [fields stringWithPrefix:@"LABEL;"    removeFromArray:YES removePrefix:NO];

    /* Look for fullname; if we get it, remove the Name field */
    fn = [fields stringWithPrefix:@"FN:" removeFromArray:YES removePrefix:YES];
    if(fn){
	[entry appendStringAndNL:fn];
	[fields stringWithPrefix:@"N:" removeFromArray:YES removePrefix:NO];
    }

    /* Look for title, Organization and then address */
    [entry appendStringAndNL:
	       [fields stringWithPrefix:@"TITLE:" removeFromArray:YES removePrefix:YES]];

    [entry appendString:[fields stringWithPrefix:@"ORG:" removeFromArray:YES removePrefix:YES]];
    [entry stripSuffix:@";"];		// don't want that
    [entry appendString:@"\n"];

    /* Now we need to find all of the labels. Then we build each region */

    f2 = [fields stringWithPrefix:@"ADD:" removeFromArray:YES removePrefix:YES];
    if(f2==0){
	f2 = [fields stringWithPrefix:@"ADR;DOM;WORK;PARCEL;POSTAL:" removeFromArray:YES removePrefix:YES];
    }
    if(f2){
	int i;
	NSMutableString *str = [NSMutableString stringWithString:f2];

	/* Special handling for address... */
	[str replaceString:@";;" withString:@";" global:YES];

	/* Change the last ; into a newline, the second to last into a space,
	 * the third to last into a comma, and the others into newlines
	 */
	for(i=0;i<1024;i++){
	    NSRange r = [str rangeOfString:@";" options:NSBackwardsSearch];
	    if(r.location==NSNotFound) break; // no more of them
	    switch(i){
	    case 0: [str replaceCharactersInRange:r withString:@"\n"];break;
	    case 1: [str replaceCharactersInRange:r withString:@" "];break;
	    case 2: [str replaceCharactersInRange:r withString:@", "];break;
	    default:[str replaceCharactersInRange:r withString:@"\n"];break;
	    }
	}
	[entry appendString:str];
	[entry appendString:@"\n"];
    }
    
    /* Add an Internet email address if present */
    [entry appendStringAndNL:[fields stringWithPrefix:@"EMAIL;INTERNET:" removeFromArray:YES removePrefix:YES]];
    [entry appendStringAndNL:[fields stringWithPrefix:@"EMAIL:" removeFromArray:YES removePrefix:YES]];
    [entry appendStringAndNL:[fields stringWithPrefix:@"EMAIL;WORK;PREF:" removeFromArray:YES removePrefix:YES]];
    
    /* While we have telephone numbers, add them */
    while(f2 = [fields stringWithPrefix:@"TEL;" removeFromArray:YES removePrefix:YES]){
	[entry appendStringAndNL:f2];
    }

    /* now add all of the remaining fields */
    e2 = [fields objectEnumerator];
    while(f2 = [e2 nextObject]){
	[entry appendStringAndNL:f2];
    }

    /* Remove all leading blank lines */
    while([entry length]>0 && [entry characterAtIndex:0]=='\r'){
	[entry deleteCharactersInRange:NSMakeRange(0,1)];
    }

    if([entry length]>0){
	[self addAndDisplayData:[entry dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
	return YES;
    }
    return NO;
}




- (BOOL)isFileVCard:(NSString *)filename
{
    NSString *firstLine = [NSString stringWithFirstLineOfFile:filename];
    return [firstLine isEqualToString:@"BEGIN:VCARD"];
}

@end


