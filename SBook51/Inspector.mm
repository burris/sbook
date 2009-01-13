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

/*
 * Inspector.m:
 *
 * runs the inspector.
 * Specially written so we usually don't display or update the Template
 * unless asked to do so.
 */


#import "Inspector.h"
#import "Person.h"
#import "SLC.h"
#import "SList.h"
#import "SBookController.h"
#import "defines.h"
#import "tools.h"
#import "ExportingTableView.h"

/****************************************************************
  FUNCTIONS
 ****************************************************************/

int	sortForTitle(NSString *title)
{
    switch([title characterAtIndex:0]){
    case 'F':return 1;			// First Name
    case 'S':				// could be Second or Smart
	switch([title characterAtIndex:1]){
	case 'm':return ENTRY_SMART_SORT_TAG;
	default:return 2;		// second
	}
    case 'T':return 3;			// third
    case 'L':return -1;			// last
    case '2':return -2;			// 2nd to last
    }
    return 0;			/* default */
}

NSString *titleForSort(int key)
{
    switch(key){
    case 1:	return @"First word";
    case 2:	return @"Second word";
    case 3:	return @"Third word";
    case -1:	return @"Last word";
    case -2:    return @"2nd to last word";
    default:
    case ENTRY_SMART_SORT_TAG:
	return @"Smart sort";
    }
    return nil;
}


@implementation Inspector

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)awakeFromNib
{
    [tabview selectTabViewItemAtIndex:0];
    fileSwitches = [[NSArray alloc] initWithObjects:
					file_statusCell,
				    file_dontParseItalicSwitch,
			    file_dontParseBoldSwitch,
			    file_dontParseAfterBlankSwitch,
			    file_dontParseSwitch,
			    file_dialFileExactSwitch,
			    file_dialBoldExactSwitch,
			    file_autosortSwitch,
			    file_openOnStartupSwitch,0];

    [[NSNotificationCenter defaultCenter]
	addObserver:self selector:@selector(template_textDidChange:)
	name:NSTextDidChangeNotification object:template_Text];

    [[NSNotificationCenter defaultCenter]
	addObserver:self selector:@selector(template_textDidChange:)
	name:NSTextDidEndEditingNotification object:template_Text];


    myEntryText = [[entry_myEntryCell stringValue] retain];
    [entry_myEntryCell setStringValue:@""];

}

- (NSWindow *)window { return window; }

/****************************************************************
                     FILE
 ****************************************************************/

- (NSString *)fileName
{
    return [slc fileName];
}

- (void)updateFilePane
{
    SList	*slist	= [slc	 doc];
    BOOL 	enabled	= slc && ![slc readOnly];
    BOOL	enableDontParse	= enabled && ![file_dontParseSwitch intValue];

    if(slc==0){
	[fileSwitches makeObjectsPerformSelector:@selector(setEnabled:)
		      withObject:nil];
	[fileSwitches makeObjectsPerformSelector:@selector(setIntValue:)
		      withObject:nil];
	[fileSwitches makeObjectsPerformSelector:@selector(setStringValue:)
		      withObject:@""];
	[gen_splitDirection setEnabled:NO];
    }
    else {
	NSString *fmt = @"Records in File: %d\nRecords Displayed: %d\nRecords Selected: %d";
	NSString *fileName = [self fileName];

	[file_statusCell setStringValue:
			     [NSString stringWithFormat:fmt,
				       [slist numPeople],
				       [slc numVisiblePeople],
				       [slc numSelectedPeople] ]];

	[file_dontParseSwitch		setIntValue:[slist queryFlag:SLIST_DONT_PARSE_ANYTHING]];

	[file_dontParseBoldSwitch	setIntValue:[slist queryFlag:SLIST_DONT_PARSE_BOLD]];
	[file_dontParseItalicSwitch	setIntValue:[slist queryFlag:SLIST_DONT_PARSE_ITALIC]];
	[file_dontParseAfterBlankSwitch setIntValue:[slist queryFlag:SLIST_DONT_PARSE_AFTER_BLANK]];

	[file_dialFileExactSwitch	setIntValue:[slist queryFlag:SLIST_DIAL_EXACT_FLAG]];
	[file_dialBoldExactSwitch	setIntValue:[slist queryFlag:SLIST_DIAL_BOLD_EXACT_FLAG]];
	[file_autosortSwitch		setIntValue:[slist queryFlag:SLIST_SORT_FLAG]];

	/* enable or disable the don't parse */
	[file_dontParseItalicSwitch	setEnabled:enableDontParse];
	[file_dontParseBoldSwitch	setEnabled:enableDontParse];
	[file_dontParseAfterBlankSwitch setEnabled:enableDontParse];
	[file_dontParseSwitch		setEnabled:enabled];
	[file_dialFileExactSwitch	setEnabled:enabled];
	[file_dialBoldExactSwitch	setEnabled:enabled];
	[file_autosortSwitch		setEnabled:enabled];
	[gen_splitDirection		setEnabled:enabled];
	[gen_splitDirection		selectItemWithTag:[slist queryFlag:SLIST_SPLIT_VERTICAL_FLAG] ? 1 : 0];

	if(fileName){
	    [file_openOnStartupSwitch	setEnabled:YES];
	    [file_openOnStartupSwitch	setIntValue:[AppDelegate
						      willOpenFileOnStartup:fileName]];
	}
	else{
	    [file_openOnStartupSwitch   setEnabled:NO];
	}
    }
}

/*
 * file_changedAttrib
 * Called when any of the file attributes are changed.
 * Reads all of the current settings from the window and puts them in the file.
 */

- (void)file_changedAttrib:sender
{
    SList	*slist	= [slc	doc];
    NSString *fileName = [self fileName];

    int		initialAutosortFlag = [[slc doc] queryFlag:SLIST_SORT_FLAG];
    
    [slist setFlag:SLIST_DONT_PARSE_BOLD toValue:[file_dontParseBoldSwitch intValue]];
    
    [slist setFlag:SLIST_DONT_PARSE_ANYTHING	toValue:[file_dontParseSwitch intValue]];
    [slist setFlag:SLIST_DONT_PARSE_ITALIC	toValue:[file_dontParseItalicSwitch intValue]];
    [slist setFlag:SLIST_DONT_PARSE_AFTER_BLANK	toValue:[file_dontParseAfterBlankSwitch intValue]];
    [slist setFlag:SLIST_DIAL_EXACT_FLAG	toValue:[file_dialFileExactSwitch intValue]];
    [slist setFlag:SLIST_DIAL_BOLD_EXACT_FLAG	toValue:[file_dialBoldExactSwitch intValue]];
    [slist setFlag:SLIST_SORT_FLAG		toValue:[file_autosortSwitch	intValue]];
    
    if(fileName){
	[AppDelegate setOpenFileOnStartup:fileName
		     toValue:[file_openOnStartupSwitch intValue]];
    }
    
    /* If autosort flag is now set, and it wasn't before, resort */
    if([slist queryFlag:SLIST_SORT_FLAG]){
	if(initialAutosortFlag==0){
	    [slc sortVisibleList];
	}
    }

    /* set the splitview */
    [slist setFlag:SLIST_SPLIT_VERTICAL_FLAG toValue:[gen_splitDirection tagOfTitle]];
    [slc setSplitViewDirectionFromDoc];

    /* Might as well reparse */
    [slc reparse];
    [slc setTextChanged:TRUE];
}

/****************************************************************
 ** TEMPLATE
 ****************************************************************/

- (void)template_changedDefaultSortKey:sender
{
	[[slc doc] setDefaultSortKey:[[sender selectedCell] tag]];
	[slc setTextChanged:TRUE];
}


- (void)template_applyToAllEntries:(id)sender
{
    [slc applyTemplateToAllEntries:sender];
}


- (void)template_textDidChange:(NSNotification *)aNotification
{
    [[template_lastSLC doc] setRTFTemplate:[template_Text rtfData]];
}


- (void)template_restoreDefault:(id)sender
{
    [template_Text setRtfData:[SList factoryDefaultRTFDataTemplate]];
    [[template_lastSLC doc] setRTFTemplate:[SList factoryDefaultRTFDataTemplate]];
    [template_defaultSortKeyCover selectItemWithTag:ENTRY_SMART_SORT_TAG];
}


- (void)updateTemplatePane
{
    if(template_lastSLC != slc){
	SList	*slist	= [slc	 doc];
    
	[template_defaultSortKeyCover selectItemWithTag:[slist defaultSortKey]];

	[template_Text setRtfData:[slist RTFTemplate]];
	template_lastSLC = slc;
    }
}

/****************************************************************
				ENTRY
 ****************************************************************/

/* updateEntryPane
 */

- (void)updateEntryPane
{
    NSArray *selectedPeople = [slc selectedPeopleArray:NO];
    int	count = [selectedPeople count];
    Person *person = (count>0) ? [selectedPeople objectAtIndex:0] : nil;
    BOOL readOnly =     [slc readOnly] || [person queryFlag:ENTRY_LOCKED_FLAG];

    /* Set the ones at the top */
    if(count==0){
	[entry_nameCell			setStringValue:@""];
	[entry_sortKeyCover		selectItemWithTag:ENTRY_SMART_SORT_TAG];
	[entry_sortKeyCover		setEnabled:NO];
	[entry_parseEntrySwitch		setIntValue:0];
	[entry_parseEntrySwitch		setEnabled:NO];
	[entry_dialEntryExactSwitch	setIntValue:0];
	[entry_dialEntryExactSwitch	setEnabled:NO];
	[entry_sortNameCell		setStringValue:@""];
	[entry_myEntryCell		setStringValue:@""];
    }

    if(count<2){
	[entry_parseEntrySwitch		setTitle:@"Parse this entry"];
	[entry_dialEntryExactSwitch	setTitle:@"Dial entry exactly"];
    }
    else{
	[entry_parseEntrySwitch		setTitle:@"Parse these entries"];
	[entry_dialEntryExactSwitch	setTitle:@"Dial entries exactly"];
    }
				    
    if(count>0){
	if(count>1){
	    [entry_nameCell
		setStringValue:[NSString stringWithFormat:@"%d entries selected",count]];
	}
	[entry_sortKeyCover		setEnabled:!readOnly];
	[entry_parseEntrySwitch		setEnabled:!readOnly];
	[entry_dialEntryExactSwitch	setEnabled:!readOnly];
    }
    
    if(count!=1){
	[entry_createdCell		setStringValue:@""];
	[entry_lastModifiedCell 	setStringValue:@""];
	[entry_myEntryCell		setStringValue:@""];
	return;
    }

    /* set for a single person */


    [entry_parseEntrySwitch	setIntValue:[person queryFlag:ENTRY_SHOULD_PARSE_FLAG]];
    [entry_parseEntrySwitch	setEnabled:!readOnly];

    [entry_dialEntryExactSwitch setIntValue:[person queryFlag:ENTRY_DIAL_EXACT_FLAG]];
    [entry_dialEntryExactSwitch setEnabled:!readOnly];

    [entry_sortKeyCover		selectItemWithTag:[person sortKey]];
    [entry_sortKeyCover 	setEnabled:!readOnly];
    
    [entry_createdCell 		setStringValue:titleString(@"",[person ctime],[person cusername])];
    [entry_lastModifiedCell 	setStringValue:titleString(@"",[person mtime],[person musername])];

    [entry_lastCalledCell	setStringValue:titleString(@"",[person calltime],nil)];
    [entry_lastEmailedCell 	setStringValue:titleString(@"",[person emailtime],nil)];
    [entry_lastEnvelopedCell 	setStringValue:titleString(@"",[person envtime],nil)];
    [entry_nameCell		setStringValue:[person cellName]];
    [entry_sortNameCell		setStringValue:[NSString stringWithUTF8String:[person sortName]]];

    if([person queryFlag:ENTRY_ME_FLAG]){
	[entry_myEntryCell	setStringValue:myEntryText];
    }
    else {
	[entry_myEntryCell	setStringValue:@""];
    }
}


- (void)entry_attributeChanged:(id)sender	// when an entry attribute changes
{
    id     person;
    NSArray *selectedPeople = [slc selectedPeopleArray:NO];
    NSEnumerator *en = [selectedPeople objectEnumerator];

    while(person = [en nextObject]){
	[person setFlag:ENTRY_SHOULD_PARSE_FLAG toValue:[entry_parseEntrySwitch intValue]];
	[person setFlag:ENTRY_DIAL_EXACT_FLAG toValue:[entry_dialEntryExactSwitch intValue]];
    }
}

- (void)entry_changedSortKey:sender
{
    id person;
    int sortKey = [entry_sortKeyCover tagOfTitle];
    NSArray *selectedPeople = [slc selectedPeopleArray:NO];
    NSEnumerator *en = [selectedPeople objectEnumerator];

    while(person = [en nextObject]){
	[person setSortKey:sortKey];
    }
    [slc displayPersonList:NO];		// resort the person list, if necessary
}


/****************************************************************
				UPDATE
 ****************************************************************/
- (void)windowDidUpdate:(id)sender
{
    id identifier = [[tabview selectedTabViewItem] identifier];
    NSString *title=0;

    slc   = [[NSApp mainWindow] delegate];
    doc   = [slc doc];

    if(slc){
	title = [slc fileName];
	if(title==nil) title = [[NSApp mainWindow] title];
    }
    else {
	title = @"";
	[tabview selectTabViewItemAtIndex:0];
	[window orderOut:nil];
    }

    [filenameCell setStringValue:title];

    switch([identifier intValue]){
    case 1:
	[self updateFilePane];
	break;
    case 2:
	[self updateTemplatePane];
	break;
    case 3:
	[self updateEntryPane];
	break;
    }
}



@end
