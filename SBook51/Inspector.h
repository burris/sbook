/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2002 by Simson Garfinkel
 *
 * All Rights Reserved.
 *
 *
 */

#import <Cocoa/Cocoa.h>

@class SLC,SList;
@interface Inspector:NSObject
{
	/* general */
	id	window;
	IBOutlet id tabview;

	/* always present */
	IBOutlet id filenameCell;

	/* file inspecting */
	SLC		*slc;		/* current file being inspected */
	SList		*doc;		// current SList being inspected
	NSArray		*fileSwitches;
	IBOutlet id	file_statusCell;
	IBOutlet id	file_autosortSwitch;

	IBOutlet id	file_dontParseBoldSwitch;
	IBOutlet id	file_dontParseItalicSwitch;
	IBOutlet id	file_dontParseAfterBlankSwitch;
	IBOutlet id	file_dontParseSwitch;

	IBOutlet id	file_dialFileExactSwitch;
	IBOutlet id	file_dialBoldExactSwitch;
	IBOutlet id	file_openOnStartupSwitch;
	IBOutlet id	gen_splitDirection;

	/* Template inspector */
	SLC		*template_lastSLC;
	IBOutlet id	template_defaultSortKeyCover;
	IBOutlet NSTextView	*template_Text;
	
	/* entry inspecting */
	IBOutlet id	entry_nameCell;
	IBOutlet id	entry_sortNameCell;
	IBOutlet id	entry_createdCell;
	IBOutlet id	entry_lastModifiedCell;
	IBOutlet id	entry_lastCalledCell;
	IBOutlet id	entry_lastEnvelopedCell;
	IBOutlet id	entry_lastEmailedCell;
	
	IBOutlet id	entry_parseEntrySwitch;
	IBOutlet id	entry_sortKeyCover;
	IBOutlet id	entry_dialEntryExactSwitch;
	IBOutlet NSTextField	*entry_myEntryCell;
	NSString	*myEntryText;	// remember localized text

	/* For font changing */
	NSFont	*firstLineFont;
	NSFont	*secondLineFont;
	int	firstLineAlignment;
	int	secondLineAlignment;
}

- (NSWindow *)window;			// returns window

/* File */
- (NSString *)fileName;			// current file being inspected
- (void)file_changedAttrib:(id)sender;	// when a file attribute changes
- (void)updateFilePane;			// reads all of the items from file

/* Template */
- (void)template_changedDefaultSortKey:(id)sender;
- (void)template_applyToAllEntries:(id)sender;
- (void)template_restoreDefault:(id)sender;
- (void)updateTemplatePane;

/* Entry */
- (void)entry_attributeChanged:(id)sender;	// when an entry attribute changes
- (void)entry_changedSortKey:sender;
- (void)updateEntryPane;


@end

#define	FILE_VIEW	0
#define ENTRY_VIEW	1
#define TEMPLATE_VIEW	2
  
