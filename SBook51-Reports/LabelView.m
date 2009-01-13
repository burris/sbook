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


#include <sys/types.h>
#include <regex.h>

#import <DefaultSwitchSetter.h>

#import "ZoomScrollView.h"
#import "LabelElement.h"
#import "LabelView.h"
#import "LabelMakerPanel.h"
#import "LineElement.h"

#define LabelDragType @"LabelDragType"
#define LabelDragArray [NSArray arrayWithObject:LabelDragType]
#define DEF_ORDINAL_OFFSET @"LabelViewOrdinalOffset"
#define DEF_leftLabelMarginCell @"DEF_leftLabelMarginCell"
#define DEF_rightLabelMarginCell @"DEF_rightLabelMarginCell"
#define DEF_topLabelMarginCell @"DEF_topLabelMarginCell"
#define DEF_bottomLabelMarginCell @"DEF_bottomLabelMarginCell"
#define DEF_textPositionMatrix @"DEF_textPositionMatrix"
#define DEF_textAlignmentMatrix @"DEF_textAlignmentMatrix"
#define DEF_labelsWideCell @"DEF_labelsWideCell"
#define DEF_labelsHighCell @"DEF_labelsHighCell"


#import "tools.h"
#if 0
@interface NSString(x)
+ (NSString *)stringWithUTF8String:(const char *)bytes length:(unsigned) length;
@end
@implementation NSString(x)
+ (NSString *)stringWithUTF8String:(const char *)bytes length:(unsigned) length
{
    return [[[NSString alloc] initWithData:[NSData dataWithBytes:bytes length:length]
			      encoding:NSUTF8StringEncoding] autorelease];
}
@end
#endif


@implementation LabelView

+ (void)initialize
{
    NSMutableDictionary *appDefs = [NSMutableDictionary dictionary];

    [appDefs setObject:@"0" forKey:DEF_ORDINAL_OFFSET];
    [appDefs setObject:@"0" forKey:DEF_leftLabelMarginCell];
    [appDefs setObject:@"0" forKey:DEF_rightLabelMarginCell];
    [appDefs setObject:@"0" forKey:DEF_topLabelMarginCell];
    [appDefs setObject:@"0" forKey:DEF_bottomLabelMarginCell];
    [appDefs setObject:@"4" forKey:DEF_textPositionMatrix];
    [appDefs setObject:@"1" forKey:DEF_textAlignmentMatrix];
    [appDefs setObject:@"3" forKey:DEF_labelsWideCell];
    [appDefs setObject:@"11" forKey:DEF_labelsHighCell];

    [defaults registerDefaults:appDefs];
}


- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(readPresetLabelsFromFile:)
					  name:NSPopUpButtonWillPopUpNotification
					  object:applyPresetButton];

    popupDictionary = [[NSMutableDictionary dictionary] retain];

    setDefault(leftLabelMarginCell,DEF_leftLabelMarginCell);
    setDefault(rightLabelMarginCell,DEF_rightLabelMarginCell);
    setDefault(topLabelMarginCell,DEF_topLabelMarginCell);
    setDefault(bottomLabelMarginCell,DEF_bottomLabelMarginCell);
    setDefault(textPositionMatrix,DEF_textPositionMatrix);
    setDefault(textAlignmentMatrix,DEF_textAlignmentMatrix);
    setDefault(labelsWideCell,DEF_labelsWideCell);
    setDefault(labelsHighCell,DEF_labelsHighCell);
    [labelsPerPageField setIntValue:[labelsWideCell intValue]*[labelsHighCell intValue]];

    [self addAutoconverter:leftLabelMarginCell];
    [self addAutoconverter:rightLabelMarginCell];
    [self addAutoconverter:topLabelMarginCell];
    [self addAutoconverter:bottomLabelMarginCell];

    [super awakeFromNib];
}
    

- initWithFrame:(NSRect)frame
{
    [super initWithFrame:frame];
    return self;
}

- (void)dealloc
{
    [popupDictionary release];
    [super dealloc];
}



-(void)prepareForReport
{
    [super	prepareForReport];
    [self	loadOrdinalOffset];
}

- (int)textPositionTag
{
    return [[textPositionMatrix selectedCell] tag];
}

- (int)textAlignmentTag
{
    return [[textAlignmentMatrix selectedCell] tag];
}

/****************************************************************
 ** DRAWING CODE
 ****************************************************************/

- (void)drawRect:(NSRect )rect
{
    [super drawRect:rect];		// gets the elements drawn
    if(dragging){			// and handle the dragging if we are

	[[NSColor darkGrayColor] set];	// just display in gray
	NSRectFill(draggedSourceRect);

	if(draggedDestOrdinal != -1){
	    NSRect  loc = [self rectForOrdinal:draggedDestOrdinal];
	    NSPoint pt = loc.origin;

	    pt.y += loc.size.height;	// flipped!

	    [draggedSourceImage compositeToPoint:pt
				operation:NSCompositeSourceOver];
	}
    }
}


- (float)leftLabelMargin  { return [self convertToPoints:[leftLabelMarginCell floatValue]];}
- (float)rightLabelMargin { return [self convertToPoints:[rightLabelMarginCell floatValue]];}
- (float)topLabelMargin   { return [self convertToPoints:[topLabelMarginCell floatValue]];}
- (float)bottomLabelMargin{ return [self convertToPoints:[bottomLabelMarginCell floatValue]];}


- (void)setLabelsWide:(int)val
{
    labelsWide	= val;
}

- (void)setLabelsHigh:(int)val
{

    labelsHigh	= val;
}

- (IBAction)resetElementsLayout:sender
{
    NSEnumerator *en = [self elementEnumerator];
    LabelElement *lab = nil;

    //NSLog(@"resetElementsLayout");
    [layoutProgress setMinValue:0];
    [layoutProgress setMaxValue:[self numReportElements]];
    [layoutProgress setDoubleValue:0];

    while(lab = [en nextObject]){
	[lab setFont:[self font:0]];
	[lab set];
	[layoutProgress incrementBy:1.0];
	[displayList addObject:lab];
    }
    [layoutProgress setDoubleValue:[self numReportElements]];
    [self setNeedsDisplay:YES];
}

- (NSRect)rectForOrdinal:(int)ordinal
{
    float	leftPageMargin 		= [self leftPageMargin];
    float	rightPageMargin 	= [self rightPageMargin];
    float	topPageMargin 		= [self topPageMargin];
    float	bottomPageMargin 	= [self bottomPageMargin];

    NSSize	pageSize = [self pageSize];
    float	printablePageWidth	= pageSize.width  - (leftPageMargin + rightPageMargin);
    float	printablePageHeight	= pageSize.height - (topPageMargin + bottomPageMargin);

    float	labelWidth	= printablePageWidth  / labelsWide;
    float	labelHeight	= printablePageHeight / labelsHigh;


    int		col  = ordinal % labelsWide;
    int		row  = (ordinal / labelsWide) % labelsHigh;
    int		page = ordinal / (labelsWide * labelsHigh);

    return NSMakeRect(leftPageMargin+col*labelWidth,
		      page*pageSize.height+topPageMargin+row*labelHeight,
		      labelWidth, labelHeight);

}

- (void)addEmptyElement:(int)ordinal
{
    LabelElement *le = [[[LabelElement alloc] initPerson:nil
					      labelView:self] autorelease];

    [le	setOrdinal:ordinal];
    [le setBlank:YES];
    [displayList addObject:le];

    //NSLog(@"added empty element %@",le);
}

- (LabelElement *)elementForLocation:(NSPoint)pt
{
    id obj;
    NSEnumerator *en = [displayList objectEnumerator];
    while(obj = [en nextObject]){
	if([obj respondsToSelector:@selector(ordinal)]){
	    if([self mouse:pt inRect:[obj bounds]]){
		return obj;
	    }
	}
    }
    return nil;

}

- (LabelElement *)elementForEvent:(NSEvent *)theEvent
{
    return [self elementForLocation:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

- (int)ordinalForEvent:(NSEvent *)theEvent
{
    return [[self elementForEvent:theEvent] ordinal];
}

/* mouseDown
 * Find the element where the mouse went down and make that the ordinal.
 */

- (IBAction)mouseDown:(NSEvent *)theEvent
{
    mouseDownOrdinal = [self ordinalForEvent:theEvent];
}

/* mouseUp:
 * Find the element where the mouse went down and make that the ordinal.
 */

- (IBAction)mouseUp:(NSEvent *)theEvent
{
    int mouseUpOrdinal = [self ordinalForEvent:theEvent];
    if(mouseDownOrdinal == mouseUpOrdinal){
	ordinalOffset = mouseUpOrdinal;
	[self changedLayoutInformation:self];
    }
}


/****************************************************************
 ** Draggin support
 ****************************************************************/

/* Drag Destination */

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pb = [sender draggingPasteboard];

    [pb types];
    if([pb availableTypeFromArray:LabelDragArray]){
	return NSDragOperationMove;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

/* Drag Source */

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
    if(flag) return NSDragOperationMove;
    return NSDragOperationNone;
}

/* Allow the user to drag from one place to another */
- (void)mouseDragged:(NSEvent *)theEvent
{
    LabelElement *lab = [self elementForEvent:theEvent];

    if(lab && [[lab text] length]>0){		// only drag real elements
	NSImage         *copyImage;
	float		scale;
	NSPoint		pt;
	NSImage         *dragImage=nil;
	NSPasteboard	*pb = [NSPasteboard pasteboardWithName:NSDragPboard];
	NSSize		labelSize;

	[pb declareTypes:LabelDragArray owner:nil];

	dragging = YES;
	draggedElement = lab;
	draggedSourceOrdinal	= [lab ordinal];
	draggedSourceRect	= [lab bounds];

	draggedDestOrdinal = -1;

	/* First we make copyImage, which is a copy of this View but just for the region
	 * that is going to be dragged
	 */

	copyImage =[[NSImage alloc] initWithSize:[self bounds].size];
	[copyImage lockFocus];
	[lab drawElementIn:self offset:NSMakePoint(0,0)];
	[copyImage unlockFocus];

	/* Now we copy our that piece of copyImage into draggedSourceImage */
	labelSize = [lab bounds].size;

	draggedSourceImage = [[NSImage alloc] initWithSize:labelSize];
	[draggedSourceImage lockFocus];
	[[NSColor whiteColor] set];
	NSRectFill(NSMakeRect(0,0,[lab bounds].size.width,[lab bounds].size.height));
	[copyImage compositeToPoint:NSMakePoint(0,0)
		   fromRect:[lab bounds] operation:NSCompositeSourceOver];
	[draggedSourceImage unlockFocus];

	/* Now I need to shrink the element to the current zoom size */

	scale = [zoomScrollView scaleFactor];
	[draggedSourceImage setScalesWhenResized:YES];
	[draggedSourceImage setSize:NSMakeSize([draggedSourceImage size].width * scale,
				      [draggedSourceImage size].height * scale)];


	/* Now make the transparent dragging image */
	dragImage = [[NSImage alloc] initWithSize:[draggedSourceImage size]];
	[dragImage lockFocus];
	[draggedSourceImage dissolveToPoint:NSMakePoint(0,0)
			    fraction:0.66];
	[dragImage unlockFocus];
			    

	/* Figure where we are dragging from */

	pt = [lab bounds].origin;
	pt.y += [lab bounds].size.height;

	[self displayRect:[lab bounds]]; // display the "hole"
	[self registerForDraggedTypes:LabelDragArray];
	[self dragImage:dragImage
	      at:pt
	      offset:NSMakeSize(0,0)
	      event:theEvent
	      pasteboard:pb
	      source:self
	      slideBack:YES];
	[self unregisterDraggedTypes];	
	
	draggedSourceImage = nil;
	dragging = NO;
	[self changedLayoutInformation:nil];

	[copyImage release];
	[dragImage release];
	[draggedSourceImage release];
    }
}


/* Need to handle the offset here */
- (void)draggedImage:(NSImage *)image movedTo:(NSPoint)screenPoint
{
    NSPoint windowPoint = [[self window] convertScreenToBase:screenPoint];
    int draggedNewOrdinal;
    LabelElement *new;

    windowPoint.x += [image size].width / 2.0;
    windowPoint.y += [image size].height / 2.0;

    /* Find the ordinal of where we are over... */
    new = [self elementForLocation:[self convertPoint:windowPoint fromView:nil]];
    draggedNewOrdinal = [new ordinal];

    if(draggedNewOrdinal==draggedDestOrdinal) return; // already drew it here

    /* Draw with it at the new place */
    draggedDestOrdinal = draggedNewOrdinal;
    [self display];
}


/* Need to handle the offset here */
- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation;
{
    ordinalOffset += draggedDestOrdinal - draggedSourceOrdinal;	// drag was successful

}

/****************************************************************
 ** LAYOUT
 ****************************************************************/


- (IBAction)changedLayoutInformation:sender
{
    int		labelsPerPage		= -1;
    NSEnumerator *en = nil;
    LabelElement *lab = nil;
    int		ordinal = 0;
    int		pages = 0;

    [self	setPageSizeFromPopup];
    [self	clearDisplayList];

    /* Make sure that these values make sense */

    if([labelsWideCell intValue]<1) [labelsWideCell setIntValue:1];
    if([labelsHighCell intValue]<1) [labelsHighCell setIntValue:1];

    /* Should sort here */
    [self	setLabelsWide:[labelsWideCell intValue]];
    [self	setLabelsHigh:[labelsHighCell intValue]];

    labelsPerPage		= (labelsHigh * labelsWide);
    [labelsPerPageField setIntValue:labelsPerPage];

    if(labelsPerPage==0 || [self numReportElements]==0){
	[self	setFrameSize:NSMakeSize(0,0)];
	return ;
    }

    ordinal = 0;
    while(ordinal<ordinalOffset){
	[self addEmptyElement:ordinal++];
    }

    [layoutProgress setMinValue:0];
    [layoutProgress setMaxValue:[self numReportElements]];
    [layoutProgress setDoubleValue:0];

    en = [self elementEnumerator];
    while(lab = [en nextObject]){
	[lab setOrdinal:ordinal];
	[lab setFont:[self font:0]];
	[lab set];
	ordinal++;
	[displayList addObject:lab];
	[layoutProgress incrementBy:1.0];
    }
    [layoutProgress setDoubleValue:[self numReportElements]];

    nextOrdinal = ordinal;

    /* Fill out this page with blaks */
    pages = (ordinal + labelsPerPage - 1) / labelsPerPage;

    while(ordinal<pages*labelsPerPage){
	[self addEmptyElement:ordinal++];
    }

    [self setNumPages:pages];		// make the view big enough!

    /* Now add the lines between each page */
    if(pages>=0){
	int page;

	NSSize pageSize = [self pageSize];

	for(page=0;page<pages;page++){
	    LineElement *le;

	    le = [[[LineElement alloc]
		      initFrom:NSMakePoint(0,(page+1)*pageSize.height)
		      to:NSMakePoint(pageSize.width,(page+1)*pageSize.height)
		      linewidth:3.0
		      color:[NSColor redColor]]
		     autorelease];
	    [displayList addObject:le];
	}
    }

    [super	changedLayoutInformation:nil];
}


/****************************************************************
 ** Label presets.
 ****************************************************************/


- (void)readPresetLabelsFromFile:(NSNotification *)not
{
    NSString *file = [NSString stringWithContentsOfFile:
				   [[NSBundle mainBundle] pathForResource:@"labels" ofType:@"txt"]];
    NSEnumerator *en;
    NSString *line;
    NSString *oldTitle = [applyPresetButton title];

    [applyPresetButton removeAllItems];
    [popupDictionary   removeAllObjects];

    if(!file){
	[applyPresetButton addItemWithTitle:@"Cannot open labels.txt"];
	return;
    }
    en = [[file componentsSeparatedByString:@"\n"] objectEnumerator];
    while(line = [en nextObject]){
	NSArray *parts;

	if([line length]==0) continue;

	if([line characterAtIndex:0]=='#') continue; // skip comment
	if([line characterAtIndex:0]==';') continue; // skip comment
	if([[line substringToIndex:6] isEqualToString:@"units:"]){
	    NSString *units = [line substringFromIndex:6];

	    while([units characterAtIndex:0]==' '){
		units = [units substringFromIndex:1];
	    }
	    [unitsPopup setTitle:units];
	    continue;
	}
	parts = [line componentsSeparatedByString:@"\t"];
	if([parts count]>0){
	    [applyPresetButton addItemWithTitle:[parts objectAtIndex:0]];
	    [[applyPresetButton lastItem] setTarget:self];
	    [[applyPresetButton lastItem] setAction:@selector(applyPreset:)];
	    [popupDictionary setObject:line forKey:[parts objectAtIndex:0]];
	}
    }
    [applyPresetButton setTitle:oldTitle];
}

-(IBAction)applyPreset:sender
{
    NSString *key = [popupDictionary objectForKey:[sender title]];
    const char	*buf = [key UTF8String];
    regmatch_t pmatch[16];
    regex_t r;

    if(regcomp(&r,"([0-9]+)x([0-9]+)",REG_EXTENDED|REG_ICASE)){
	perror("regcomp1");
	return;
    }
    memset(pmatch,0,sizeof(pmatch));
    if(regexec(&r,buf,16,pmatch,0)){
	NSLog(@"Can't find widexhigh");
	return;
    }
    [labelsWideCell setStringValue:[NSString stringWithUTF8String:buf+pmatch[1].rm_so
					     length:pmatch[1].rm_eo-pmatch[1].rm_so]];
    [labelsHighCell setStringValue:[NSString stringWithUTF8String:buf+pmatch[2].rm_so
					     length:pmatch[2].rm_eo-pmatch[2].rm_so]];
    [labelsPerPageField setIntValue:[labelsWideCell intValue]*[labelsHighCell intValue]];

    if(regcomp(&r,"([0-9.]+) *, *([0-9.]+) *, *([0-9.]+) *, *([0-9.]+)",
	       REG_EXTENDED|REG_ICASE)){
	perror("regcomp2");
	return;
    }
    memset(pmatch,0,sizeof(pmatch));
    if(regexec(&r,buf,16,pmatch,0)){
	NSLog(@"Can't find margins");
	return;
    }
    [leftPageMarginCell setStringValue:[NSString stringWithUTF8String:buf+pmatch[1].rm_so
						 length:pmatch[1].rm_eo-pmatch[1].rm_so]];
    [rightPageMarginCell setStringValue:[NSString stringWithUTF8String:buf+pmatch[2].rm_so
						  length:pmatch[2].rm_eo-pmatch[2].rm_so]];
    [topPageMarginCell setStringValue:[NSString stringWithUTF8String:buf+pmatch[3].rm_so
						length:pmatch[3].rm_eo-pmatch[3].rm_so]];
    [bottomPageMarginCell setStringValue:[NSString stringWithUTF8String:buf+pmatch[4].rm_so
						   length:pmatch[4].rm_eo-pmatch[4].rm_so]];
    [self changedLayoutInformation:nil];
}


/* Modal print */
- (void)printWithWindow:(NSWindow *)windowToAttachSheet
{
    NSPrintInfo *pi = [[NSPrintInfo sharedPrintInfo] copy];	// get our own copy
    NSPrintOperation *po;

    po = [NSPrintOperation printOperationWithView:self printInfo:pi];

    [pi setTopMargin:0];
    [pi setLeftMargin:0.0];
    [pi setBottomMargin:0.0];
    [pi setRightMargin:0.0];

    /*
     * When I can get printers, we can skip this step.
     *
     * [po setShowPanels:NO];
     */
    [po setPrintInfo:pi];
    [po runOperationModalForWindow:windowToAttachSheet
	delegate:self
	didRunSelector:@selector(printOperationDidRun:success:contextInfo:)
	contextInfo:nil];
}

/* Non-modal print */
- (IBAction)print:sender
{
    [super print:self];
    [self  printOperationDidRun:nil success:YES contextInfo:nil];
}

- (void)printOperationDidRun:(NSPrintOperation *)printOperation success:(BOOL)success contextInfo:(void *)contextInfo
{
    if(success){
	[self saveNextOrdinalOffset];
    }
}

- (void)loadOrdinalOffset
{
    ordinalOffset = [[defaults objectForKey:DEF_ORDINAL_OFFSET] intValue];
}


- (void)saveNextOrdinalOffset			// remember ordinal for next
{
    int val = nextOrdinal % (labelsWide * labelsHigh);

    [defaults setObject:[NSNumber numberWithInt:val]
	      forKey:DEF_ORDINAL_OFFSET];

}



@end
