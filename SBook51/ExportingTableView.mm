
#import "ExportingTableView.h"
#import "SLC.h"
#import "SList.h"

#import "defines.h"

@interface ExportingTableViewHelper : NSView
{
    ExportingTableView *helpedView;
}
- initFromView:(ExportingTableView *)aView;
@end

@implementation ExportingTableViewHelper

- initFromView:(ExportingTableView *)aView
{
    [super init];
    helpedView = aView;
    [self setToolTip:@"Change what is displayed in SBook entry list."];
    return self;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [helpedView popMenuWithEvent:theEvent];
}

- (void)drawRect:(NSRect)rect
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSRect r1,r2,r3;

    NSDrawGrayBezel(rect,rect);
    [[NSColor blackColor] set];
    r1 = NSMakeRect(NSMidX(rect)-1,NSMidY(rect)-1-4,2,2);
    r2 = NSMakeRect(NSMidX(rect)-1-4,NSMidY(rect)-1-4,2,2);
    r3 = NSMakeRect(NSMidX(rect)-1+4,NSMidY(rect)-1-4,2,2);

    [path appendBezierPathWithOvalInRect:r1];
    [path appendBezierPathWithOvalInRect:r2];
    [path appendBezierPathWithOvalInRect:r3];
    [path fill];
}


@end

@implementation ExportingTableView

- (void)dealloc
{
    [contextMenu release];
    [super dealloc];
}

- (unsigned int)gridStyleMask
{
    return NSTableViewSolidVerticalGridLineMask | NSTableViewSolidHorizontalGridLineMask;
}


- (void)setColumnOneMode
{
    int columnOneMode = [doc columnOneMode];
    NSString *title=@"";
    int startNumberOfColumns = [[self tableColumns] count];

    switch(columnOneMode){
    case Nothing:
	/* Make sure that no second column is displayed */
	[[col1 headerCell] setTitle:@""];
	if(startNumberOfColumns==2){
	    [self removeTableColumn:col2];
	    [col1 setWidth:NSWidth([self bounds])];
	}
	[self setAllowsColumnResizing:YES];
	break;
    case FirstPhone:
    case FirstEmail:
    case SecondLine:
	[[col1 headerCell] setTitle:@"name"];
	/* Make sure that the second column is displayed */
	if(startNumberOfColumns==1){
	    [self addTableColumn:col2];
	    [self setAllowsColumnReordering:NO];
	    [self scrollRowToVisible:0];	// because the scroller can get confused
	}
	switch(columnOneMode){
	case FirstPhone:	title = @"phone";break;
	case FirstEmail:	title = @"email";break;
	case SecondLine:	title = @"";break;
	default:		title = @"";break;
	}
	[self setAllowsColumnResizing:YES];

	[col1 setWidth:NSWidth([self bounds])/2];
	[col2 setWidth:NSWidth([self bounds])/2];
	[[col2 headerCell] setTitle:title];
    }
    [self setNeedsDisplay:YES];
}

- (void)awakeFromNib
{
    NSArray *tableColumns = [self tableColumns];
    ExportingTableViewHelper *j;

    col1 = [[tableColumns objectAtIndex:0] retain];
    col2 = [[tableColumns objectAtIndex:1] retain]; 
    savedHeaderView = [[self headerView] retain];
    slc = [[self window] delegate];
    doc = [slc doc];
    [self setColumnOneMode];

    j = [[ExportingTableViewHelper alloc] initFromView:self];
    [j setFrame:[[self cornerView] frame]];
    [self setCornerView:j];

}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (NSImage*)dragImageForRows:(NSArray*)dragRows
		       event:(NSEvent*)dragEvent
	     dragImageOffset:(NSPointPointer)dragImageOffset
{
    return [[NSWorkspace sharedWorkspace] iconForFileType:VCARD_FILE_EXTENSION];
}

/*
 * note: flag refers to other applicatons.
 */
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
#ifdef DEBUG_DRAGGING
    NSLog(@"ExportWell draggingSourceOperationMaskForLocal(flag=%d) return NSDragOperationCopy",flag);
#endif    
    return NSDragOperationCopy;		// Only allow copy
}

/* Don't know what to do with keyclicks; pass them to the search cell...
 * field editor
 */
- (void)keyDown:(NSEvent *)theEvent
{
    unichar ch = [[theEvent characters] characterAtIndex:0];

    if(ch==0x7f || ch==63272){		// either delete
	/* Delete! */
	
	[slc delete:self];
	return;
    }

    if(ch>= 0xf700 && ch<=0xf8ff){	// function keys stay here
	[super keyDown:theEvent];
	return;
    }

    /* Otherwise, pass to the search field */
    [slc putCursorAtEndOfSearchCell];
    [[slc fieldEditor] keyDown:theEvent];
}



- (void)popMenuWithEvent:(NSEvent *)theEvent
{
    if(!contextMenu){
	contextMenu = [[NSMenu alloc] init];

	showPhone = [[NSMenuItem alloc] init];
	[showPhone setTitle:@"Show Phone"];
	[showPhone setTarget:self];
	[showPhone setAction:@selector(showPhone:)];
	[contextMenu addItem:showPhone];

	showEmail = [showPhone copy];
	[showEmail setTitle:@"Show Email"];
	[showEmail setAction:@selector(showEmail:)];
	[contextMenu addItem:showEmail];

	showSecondLine = [showPhone copy];
	[showSecondLine setTitle:@"Show Second Line"];
	[showSecondLine setAction:@selector(showSecondLine:)];
	[contextMenu addItem:showSecondLine];
    }
    [NSMenu popUpContextMenu:contextMenu withEvent:theEvent forView:self];

    [showPhone setState:[doc columnOneMode]==FirstPhone];
    [showEmail setState:[doc columnOneMode]==FirstEmail];
    [showSecondLine setState:[doc columnOneMode]==SecondLine];
}

- (void)showPhone:(id)sender
{
    int new_ = [doc columnOneMode]==FirstPhone ? Nothing : FirstPhone;
    [doc setColumnOneMode:new_];
    [self setColumnOneMode];
}

- (void)showEmail:(id)sender
{
    int new_ = [doc columnOneMode]==FirstEmail ? Nothing : FirstEmail;
    [doc setColumnOneMode:new_];
    [self setColumnOneMode];
}

- (void)showSecondLine:(id)sender
{
    int new_ = [doc columnOneMode]==SecondLine ? Nothing : SecondLine;
    [doc setColumnOneMode:new_];
    [self setColumnOneMode];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if([theEvent modifierFlags] & NSControlKeyMask == NSControlKeyMask){
	[self popMenuWithEvent:theEvent];
	return;
    }
    [super mouseDown:theEvent];

}



@end
