/*
 * SBookText:
 * Display and Edit of the  main SBook text area.
 * Automatically parses as things change. Communications with the IconView to the left.
 * 
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2002, 2003 by Simson L. Garfinkel
 *
 *
 */

#import <Cocoa/Cocoa.h>

@class SBookIconView;
@class SLC;
@interface SBookText:NSTextView
{
    int		tag;			// every object should have a tag!
    int		changeCount;		// how many changes we were changed
    IBOutlet NSScrollView	*myScroller; // points to the scroller that we are in
    NSRect	documentVisibleRect;
    NSString	*oldFirstLine;
    SBookIconView *iconView;
    SLC		*slc;
}

+ (void)initialize;			// sets things up
- (void)awakeFromNib;			// sets ruler

/* Code to work with appkit */
- (void)setFrameOrigin:(NSPoint)newOrigin;
- (void)setFrame:(NSRect)frameRect;
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent; // tells parent that we do
- (void)setEditable:(BOOL)flag;		// whether or not this is editable

/* Code for parsing */
- (void)setIconView:(SBookIconView *)anIconView; // 
- (int)changeCount;
- (void)incrementChangeCount;
- (void)setTag:(int)aTag;
- (NSRect)documentVisibleRect;
- (void)rememberFirstLine;
- (void)checkFirstLine;

/* Code for event handling */
- (void)keyDown:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)theEvent;

/* Copy and paste */
-(IBAction)paste:(id)sender;
-(IBAction)cut:(id)sender;
- (BOOL)validateMenuItem:(id <NSMenuItem>)item;

/* Dragging */
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
//- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender;
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (IBAction)switchToFont1:sender;
- (IBAction)switchToFont2:sender;




@end
