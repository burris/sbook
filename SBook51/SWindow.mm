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
 * the only reason to have an SWindow class is to implement drag&drop import of file icons...
 */


#import "SWindow.h"
#import "SBookController.h"
#import "SLC.h"
#import "tools.h"

#import "defines.h"

#define DEBUG_DRAG

NSString *ABVCardPBoardType = @"ABVCardStringPBoardType";

@implementation SWindow

/* dragging */
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)mask backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag;
{
    [super initWithContentRect:contentRect styleMask:mask backing:bufferingType defer:flag];
    [self   registerForDraggedTypes:[NSArray arrayWithObjects:TYPE_SBOOK_ARRAY,
					     ABVCardPBoardType,
					     NSFilenamesPboardType,
					     0]];
    return self;
}


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    id source = [sender draggingSource];
    if([source respondsToSelector:@selector(window)] &&
       [source window] == self){
	return NSDragOperationNone;	// do not accept drag from self
    }
    return NSDragOperationMove | NSDragOperationCopy;	// otherwise, accept Move and Copy
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    int count=0;
    NSPasteboard *pb = [sender draggingPasteboard];
    SLC *slc = [self delegate];

#ifdef DEBUG_DRAG
    NSLog(@"SWindow::performDragOperation");
#endif

    [pb types];
    if([pb dataForType:TYPE_SBOOK_ARRAY]){
	[slc pasteWithPasteboard:pb];
	return YES;
    }
    /* NSVCardPboardType replaces ABVCardPBoardType */
    NSLog(@"%@ = %@?",NSVCardPboardType,ABVCardPBoardType);
    if([pb dataForType:NSVCardPboardType]){
	NSString *str = [pb stringForType:NSVCardPboardType];
	id plist = [str propertyList];
	NSEnumerator *en = [plist objectEnumerator];
	NSString *vcard;

	while(vcard = [en nextObject]){
	    if([slc importVCard:vcard]){
		count++;
	    }
	}
	[slc notifyImportCount:count];
	    
	return YES;
    }
    if([pb dataForType:NSFilenamesPboardType]){
	NSArray *fnames= [[pb stringForType:NSFilenamesPboardType] propertyList];
	NSEnumerator *en = [fnames objectEnumerator];
	NSString *fname;
	BOOL imported = NO;

	while(fname = [en nextObject]){
	    if([slc isFileVCard:fname]){
		if([slc importVCard:[NSString stringWithContentsOfFile:fname]]){
		    [slc notifyImportCount:1];
		    imported = YES;
		}
	    }
	    if([slc isFileSBookXML:fname]){
		[slc importSBookXMLFilenameArray:[NSArray arrayWithObject:fname]
		     flag:0];
		imported = YES;
	    }
	}
	return imported;
    }
    return [super performDragOperation:sender];
}

@end
