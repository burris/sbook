/*
 * SWindowFieldEditor:
 * This is the field editor for the search field at the top of the SBookWindow.
 * We do so many funky things with it that we did not want to
 * use the standard field editor.
 *
 *
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2002,2003 by Simson L. Garfinkel.
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law.
 *
 */

#import <Cocoa/Cocoa.h>

#import "SWindowFieldEditor.h"
#import "SBookController.h"
#import "SLC.h"
#import "SBookIconView.h"
#import "ExportingTableView.h"
#import "SBookText.h"

#import "defines.h"

@implementation SWindowFieldEditor


- (void)awakeFromNib
{
    slc = [[self window] delegate];
}


/* Do we have a section?
 * hasTextSelection - true if there are letters in the field that are selected.
 * hasPersonSelection - true if people in the browser are selected.
 */

- (BOOL)hasTextSelection
{
    return [self selectedRange].length > 0;
}

- (BOOL)hasPeopleSelection
{
    return [slc numSelectedPeople] > 0;
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)item
{
    /* Special case the special things we know how to copy or past */
    SEL action = [item action];

    if(action == @selector(copy:)){
	if([self hasPeopleSelection]) return YES;
    }

    if(action == @selector(cut:) ||
       action == @selector(delete:)){
	if([self hasPeopleSelection] &&
	   [slc numLockedSelectedPeople]==0){
	    return YES;			// entries present that are not locked
	}
    }

    if(([item action] == @selector(paste:))){
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	
	[pb types];
	if([pb dataForType:TYPE_SBOOK_ARRAY]){
	    return YES;
	}
    }
    return [super validateMenuItem:item];
}

/* Some key events, like arrows, need to be specially handeled.
 * If we get an up or down arrow, we want to send it to the SLC.
 *
 */
- (void)keyDown:(NSEvent *)event
{
    unichar ch = [[event characters] characterAtIndex:0];
    bool    alt = ([event modifierFlags] & NSAlternateKeyMask) ? true : false;
    

    switch(ch){
    case 'p' - 'a' + 1:			// control-p
    case NSUpArrowFunctionKey:
        [slc previousEntry:nil];
	return ;
    case NSDownArrowFunctionKey:
    case 'n' - 'a' + 1:			// control-N
    case '\r':				// carriage return
    case '\n':				// line feed
	if(alt){
	    [slc previousEntry:nil];
	}
	else {
	    [slc nextEntry:nil];
	}
	return;
    case '\t':
	[[self window] makeFirstResponder:[slc entryText]];
	return;
    }
    [super keyDown:event];
}


/* If we get a copy and there is a selection within the field editor,
 * then copy those characters. If there is no selection, then tell the SLC to put
 * the selected People
 */
-(void)copy:sender
{
    if([self selectedRange].length == 0){
	[slc copy:sender];
        return;
    }
    [super copy:sender];

}

/* If selection is empty, we should send copy to matrix instead */
-(void)cut:sender
{
    if([self selectedRange].length == 0){
	[slc cut:sender];
	return;
    }
    [super cut:sender];
}

-(void)delete:sender
{
    if([self selectedRange].length == 0){
	[slc delete:sender];
	return;
    }
    [super delete:sender];
}

/* Send selectall to the matrix ... */
-(void)selectAll:sender
{
    [[slc nameTable] selectAll:sender];
}



/* if paste has a Person on the pasteboard, we should send paste to the matrix instead */
-(void)paste:sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];

    [pb types];
    if([pb dataForType:TYPE_SBOOK_ARRAY]){
	[slc paste:sender];
	return;
    }
    [super paste:sender];
}


/* Don't implement these functions */
- (void)changeFont:sender	{ return; }
- (void)alignLeft:sender 	{ return; }
- (void)alignRight:sender	{ return; }
- (void)alignCenter:sender	{ return; }

@end
