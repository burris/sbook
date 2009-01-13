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

#import "FontWell.h"
//#define DEBUG

@class NSPasteboard;
@interface NSPasteboard(FontWell)
- (BOOL)checkForType:( NSString *)aType;
- (NSFont *)font;
- (NSColor *)color;
@end

@implementation NSPasteboard(FontWell)
-(BOOL)checkForType:(NSString *)aType
{
    if([self availableTypeFromArray:[NSArray arrayWithObject:aType]]){
	return YES;
    }
    return NO;
}

-(NSFont *)font
{
    if([self checkForType:NSFontPboardType]){
	NSData *data = [self dataForType:NSFontPboardType];
	NSFont *font = [NSUnarchiver unarchiveObjectWithData:data];
	return font;
    }
    return nil;
}

-(NSColor *)color
{
    if([self checkForType:NSColorPboardType])
        return [NSColor colorFromPasteboard:self];
    return nil;
}


@end




@implementation FontWell
static	NSMutableArray	*activeWellList; /* list of active wells */
static  FontWell	*sharedFontWell; /* The well for the font panel */

+ (void)initialize
{
    activeWellList = [[NSMutableArray alloc] init];
}

+ (void)deactivateAllWells
{
    [activeWellList makeObjectsPerformSelector:@selector(setActive:) withObject:nil];
}

+ (void)activeWellsTakeFontFrom:sender
{
    NSArray *listCopy = [NSArray arrayWithArray:activeWellList];
    NSFont	*aFont=nil;

    if([sender isKindOfClass:[NSFont class]]){
	aFont = sender;
    }
    if(!aFont && [sender respondsToSelector:@selector(font)]){
	aFont = [sender font];
    }
    if(!aFont){
	return;				// can't get the font
    }
			  

    [listCopy	makeObjectsPerformSelector:@selector(setFont:) withObject:aFont];
    [listCopy	makeObjectsPerformSelector:@selector(performClick:) withObject:nil];
    [listCopy	makeObjectsPerformSelector:@selector(deactivateOnSetIfNeeded) ];
}

- (BOOL)acceptsFirstResponder { return YES;}

- (id)initWithFrame:(NSRect)frameRect
{
    [super 	initWithFrame:frameRect];
    [self	setColor:[NSColor blackColor]];	// 
    [self	registerForDraggedTypes:[NSArray arrayWithObject:NSFontPboardType]];
    [self	setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];

    contextMenu = [[NSMenu alloc] initWithTitle:@""];

    // TK: Move to localized names 
    [contextMenu addItemWithTitle:@"Font" action:nil keyEquivalent:@""]; 
    [contextMenu addItemWithTitle:@"Size" action:nil keyEquivalent:@""];
    return self;
}

- (void)dealloc
{
    [activeWellList	removeObject:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (BOOL)acceptsFirstMouse	{ return YES;}

- (void)setInFontPanel:(BOOL)flag
{
    inFontPanel=flag;
    if(flag){
	[self setBordered:NO];
	[self setSupportsColor:NO];
    }
}

- (void)displayFontPanel
{
    NSFontManager	*fm = [NSFontManager sharedFontManager];
    NSFontPanel	*pan = [fm fontPanel:YES];

    if(sharedFontWell==nil){

	sharedFontWell =	[[FontWell alloc] initWithFrame:NSMakeRect(0,0,200,100)];

	[sharedFontWell	removeFromSuperview]; // get it out of the parent
	[sharedFontWell	setInFontPanel:YES];
	[pan		setAccessoryView:sharedFontWell];
	[sharedFontWell	setAutoresizingMask:NSViewWidthSizable|NSViewMaxXMargin];
	[[NSNotificationCenter defaultCenter] addObserver:sharedFontWell
					      selector:@selector(fontPanelDidUpdate:)
					      name:NSWindowDidUpdateNotification
					      object:pan];
    }
    [pan		orderFront:self];
    [pan		setDelegate:self];
}


- (BOOL)isActive
{
    return [activeWellList containsObject:self];
}

- (void)drawRect:(NSRect)rect
{
    NSDrawWhiteBezel([self bounds],rect); /* fill region with white */
    if([self isActive]){
	[[NSColor blueColor] set];
	NSFrameRectWithWidth([self bounds],4);
    }

    [displayString drawInRect:NSInsetRect([self bounds],0,drawPointSize/2)];
}

- (void)drawWellInside:(NSRect)rr
{
    contentRect=rr; // might have been changed when resizing or so
    NSDrawWhiteBezel(rr,rr);
    if ([self supportsColor])
        [displayString addAttribute:NSForegroundColorAttributeName
		       value:[self color]
		       range:NSMakeRange(0,[[displayString string] length])];
    [displayString drawInRect:NSInsetRect(rr,2,drawPointSize/2)];
}



- (NSFont *)font
{
    if(inFontPanel){
	return [[NSFontManager sharedFontManager] selectedFont];
    }
    return theFont;
}

- (void)computeDisplayedFont
{
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    NSFont	*aFont = displayFont;
    NSString	*str = nil;

    if(fontAttributes){
	[fontAttributes release];		// get rid of our copy
	fontAttributes = nil;
    }

    if(aFont==0){
	/* calculate the proper size to draw the font */
	drawPointSize	= [theFont pointSize];
	if(drawPointSize < 10.0) drawPointSize = 10.0;
	if(drawPointSize > 16.0) drawPointSize = 16.0;
	
	aFont = [NSFont fontWithName:[theFont fontName] size:drawPointSize];
    }
    [attrs setObject: aFont forKey:NSFontAttributeName];

    str  = [NSString stringWithFormat:@"%@ %g point",
		     [theFont displayName], [theFont pointSize]];

    [displayString release];
    displayString   = [[NSMutableAttributedString alloc]
			  initWithString:str attributes:attrs];
    [displayString setAlignment:NSCenterTextAlignment
		   range:NSMakeRange(0,[displayString length])];
    [self 	setNeedsDisplay:YES];

#ifdef DEBUG
    NSLog(@"afont=%@",aFont);
    NSLog(@"displayString=%@",displayString);
#endif
}

- (void)setFont:(NSFont *)font
{

    if(!font) return;			// doesn't make sense

    if(inFontPanel){
	[[NSFontManager sharedFontManager] setSelectedFont:font isMultiple:NO];
    }

    if([theFont isEqual:font]) return;

    if(theFont != font){
	[theFont release];
	theFont = [font retain];
    }

    [self computeDisplayedFont];
}

- (void)takeFontFrom:(id)sender {
    [self setFont:[sender font]];
}



- (void)setActive:(BOOL)flag
{
    if([self isActive]==flag) return ;	/* wish Apple did this in their methods */

    if(flag){
	[activeWellList addObject:self];
	/* set the font panel to be our font */
	[[NSFontManager sharedFontManager] setSelectedFont:[self font] isMultiple:NO];

	if(supportsColor) [super activate:YES];

    }
    else{
	[activeWellList removeObject:self];
	if(supportsColor) [super deactivate];
    }
    [self	setNeedsDisplay:YES];
}

- (void)deactivate
{
    [self setActive:NO];
}
- (void)activate:(BOOL)exclusive {
    if (exclusive) [[self class] deactivateAllWells];
    [self setActive:YES];
}


- (void)setDisplayFont:(NSFont *)aFont
{
    if(displayFont != aFont){
	[displayFont release];
	displayFont = [aFont retain];
    }
#ifdef DEBUG
    NSLog(@"%@: set font to %@",self,aFont);
#endif    
    [self computeDisplayedFont];
}



- (BOOL)supportsColor {
    return supportsColor;
}
- (void)setSupportsColor:(BOOL)colored {
    supportsColor=colored;
}

- (void)takeColorFrom:(id)sender {
    if ([self supportsColor]) [super takeColorFrom:sender];
}
- (void)setColor:(NSColor *)color {
    if ([self supportsColor]) {
        [super setColor:color];
        [self setNeedsDisplay:YES];

	if(fontAttributes){
	    [fontAttributes release];		// get rid of our copy
	    fontAttributes = nil;
	}
    }
}
- (NSColor *)color
{
    return [self supportsColor]?[super color]:[NSColor blackColor];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    [NSMenu popUpContextMenu:contextMenu withEvent:theEvent forView:self];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    /* If we have a shift-click, invert our active status,
     * and make sure the font panel is displayed.
     * Don't do this if we are in the font panel.
     */
    if(([theEvent modifierFlags] & NSShiftKeyMask) && !inFontPanel){
	[self		setActive:![self isActive]];
	[self		displayFontPanel];
	return;
    }

    if([theEvent clickCount]==2){
	/* If second mouse click, display the font panel
	 * make this font well active, and make the others not active,
	 * and set this well to deactivate on the next change...
	 */
	[self displayLinkedFontPanel:nil];
	return;
    }
}

- (NSDictionary *)fontAttributes	// returns an NSDictionary of font attributes
{

    if(!fontAttributes){
	id cname = nil;			// color name
	id cvalue = nil;		// color value

	if([self supportsColor]){
	    cname = NSForegroundColorAttributeName; //
	    cvalue = [self color];
	}

	fontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
					   theFont,NSFontAttributeName,
				       cvalue,cname,
				       nil,nil];
	[fontAttributes retain];
	//NSLog(@"created font attributes: %@",fontAttributes);
    }
    return fontAttributes;
}



/****************************************************************
			       DRAGGING
 ****************************************************************/

- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)anEvent 		{ return YES;}
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)lflag;
{
	return NSDragOperationAll;
}


- (void)mouseDragged:(NSEvent *)theEvent
{
    NSSize 	offset 	= {8, 8};
    NSPasteboard *pb 	= [NSPasteboard pasteboardWithName:NSDragPboard];
    NSPoint	location= [theEvent locationInWindow];
    NSSize		isize 	= {16.0,16.0};
    NSRect		ibounds = NSMakeRect(0,0,16.0,16.0);
    NSImage	*image	= [[[NSImage alloc] initWithSize:isize] autorelease];
    NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:@"F"];
	
    /* create our image */
    [image lockFocus];
    [[NSColor whiteColor] set];
    NSRectFill(ibounds);
    
    [[NSColor blackColor] set];
    [as setAlignment:NSCenterTextAlignment range:NSMakeRange(0,[as length])];
    [as drawInRect:NSMakeRect(2,2,12,12)];

    NSFrameRect(ibounds);
    [image unlockFocus];

    /* This magic uses our privateText object (not the field editor!) to convert the font
     * to pasteboard format...
     */
	
    [pb declareTypes:[NSArray arrayWithObject:NSFontPboardType] owner:self];
    [pb setData:[NSArchiver archivedDataWithRootObject:theFont] forType:NSFontPboardType];
    
    /* Drag code goes here */
    location = [self convertPoint:location fromView:nil];
    [self dragImage:image at:location offset:offset
	  event:theEvent pasteboard:pb source:self slideBack:NO];
}

/* You need these methods to give you the acceptFont:atPoint:...
 * (Don't forget to register to accept NSFontPboardType)
 */

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if([sender draggingSource]==self) return 0;		/* not interesting case */

    [self	lockFocus];
    [[NSColor brownColor] set];
    NSFrameRectWithWidth([self bounds],2.0);
    [self	unlockFocus];
    [[NSGraphicsContext currentContext] flushGraphics];
    return 	NSDragOperationCopy;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    if([sender draggingSource]==self) return;		/* not interesting case */

    [self	display];	/* redraw without box */
    [[NSGraphicsContext currentContext] flushGraphics];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pb = [sender draggingPasteboard];
    id	font = [pb font];
    NSColor *color=[pb color];

    if(font){
	[self	setFont:font];
	return YES;
    }
    if (color) {
        [self setColor:color];
        return YES;
    }
    return NO;			/* failed? */
}

- (IBAction)displayLinkedFontPanel:(id)sender
{
    [self	displayFontPanel];
    [FontWell	deactivateAllWells];
    [self	setActive:YES];
}


- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    [self sendAction:[self action] to:[self target]]; /* do target/action */
}

- (void)performClick:sender
{
    [self sendAction:[self action] to:[self target]];
}

- (void)changeFont:(id)sender
{
    NSFont *newFont = [sender convertFont:theFont];

    [self setFont:newFont];
}

/* If we are in the font panel, redraw if our internal font
 * does not equal the font panel's font.
 */

- (void)fontPanelDidUpdate:(NSNotification *)n
{
    NSFont	*fmFont = [[NSFontManager sharedFontManager] selectedFont];

    if(fmFont && [fmFont isEqual:theFont]==NO){
	[self setFont:fmFont];
	[activeWellList makeObjectsPerformSelector:@selector(setFont:) withObject:fmFont];
	[activeWellList makeObjectsPerformSelector:@selector(performClick:) withObject:nil];
    }
}


- (void)windowWillClose:(NSNotification *)notification
{
    if([self isActive]){
	[self setActive:NO];
    }
}


@end
