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
#import "AbstractReportView.h"
#import "AbstractReportElement.h"


@implementation AbstractReportView

- (void)awakeFromNib
{
    [self addAutoconverter:leftPageMarginCell];
    [self addAutoconverter:rightPageMarginCell];
    [self addAutoconverter:topPageMarginCell];
    [self addAutoconverter:bottomPageMarginCell];
    [self prepareForReport];		// give us a running chance!

    [super awakeFromNib];
}

- (void)setLayoutProgress:(double)value
{
    [layoutProgress setDoubleValue:value];
}

-(void)prepareForReport
{
    [self       setPageSizeFromPopup];
}


- (NSProgressIndicator *)layoutProgress {return layoutProgress;}
- (NSMutableArray *)displayList { return displayList;}

- (BOOL)isOpaque  { return YES;}
- (BOOL)isFlipped { return YES;}

- initWithFrame:(NSRect)frameRect
{
    [super	initWithFrame:frameRect];
    displayList	= [[NSMutableArray alloc] init];
    elementList	= [[NSMutableArray alloc] init];

    return self;
}

- (void)clearDisplayList
{
    [displayList removeAllObjects];
    [self setNeedsDisplay:YES];
}
    
- (void)clearElementList;
{
    [displayList removeAllObjects];
    [elementList removeAllObjects];
    [self setNeedsDisplay:YES];
}

- (void)addReportElement:(AbstractReportElement *)element
{
    [elementList	addObject:element];
    [numEntriesCell	setIntValue:[displayList count]];
}

- (int)numReportElements
{
    return [elementList count];
}

/****************************************************************
 ** Margins
 ****************************************************************/

- (float)leftPageMargin  { return [self convertToPoints:[leftPageMarginCell   floatValue]];}
- (float)rightPageMargin { return [self convertToPoints:[rightPageMarginCell  floatValue]];}
- (float)topPageMargin 	 { return [self convertToPoints:[topPageMarginCell    floatValue]];}
- (float)bottomPageMargin{ return [self convertToPoints:[bottomPageMarginCell floatValue]];}

- (void)setLeftMargin:(float)l rightMargin:(float)r topMargin:(float)t bottomMargin:(float)b
{
    [leftPageMarginCell setFloatValue:[self convertFromPoints:l]];
    [rightPageMarginCell setFloatValue:[self convertFromPoints:r]];
    [topPageMarginCell setFloatValue:[self convertFromPoints:t]];
    [bottomPageMarginCell setFloatValue:[self convertFromPoints:b]];
}



/****************************************************************
 ** DRAWING CODE
 ****************************************************************/

- (void)drawRect:(NSRect) rect withOffset:(NSPoint)pt
{
    NSEnumerator *en;
    id obj=nil;

    [[NSColor whiteColor] set];
    NSRectFill(rect);

    en = [displayList objectEnumerator];
    while(obj = [en nextObject]){
	if(NSIntersectsRect(rect,[obj bounds])){
	    [obj drawElementIn:self offset:pt];
	}
    }
}

- (void)drawRect:(NSRect )rect 
{
    [self drawRect:rect withOffset:NSMakePoint(0,0)];
}

/****************************************************************
 ** PRINTING CODE
 ****************************************************************/

- (BOOL)knowsPageRange:(NSRangePointer)range
{
    float height = [self pageSize].height;
    if([displayList count]==0 || height==0.0){
	return NO;
    }

    range->location	= 1;
    range->length 	= [self bounds].size.height / height;
    return YES;
}

- (float)heightAdjustLimit
{
    return 0.0;
}

- (float)widthAdjustLimit
{
    return 0.0;
}

- (NSPoint)locationOfPrintRect:(NSRect)aRect
{
    NSSize size = [[NSPrintInfo sharedPrintInfo] paperSize];
    return NSMakePoint(0,aRect.size.height - size.height);
}


/****************************************************************
 ** LAYOUT
 ****************************************************************/

- (void)insertPageNumber:(int)pn
{
}

- (void)insertPageNumbers
{
    NSRange	r;

    memset(&r,0,sizeof(r));
    if([self knowsPageRange:&r]){
	unsigned int i;

	for(i=r.location;i<r.location+r.length;i++){
	    [self	insertPageNumber:i];
	}
    }
}

/* Actually do the page layout.
 * The subclass will do the main work, then call this method to do the page numbers.
 */
/* Do the things that we would always want to do */
- (IBAction)changedLayoutInformation:sender
{
    NSRange	range;
    NSSize	pageSize = [self pageSize];

#ifdef DEBUG_CONSTRUCTION
    NSLog(@"changedLayoutInformation");
#endif

    [self	insertPageNumbers];
    if([self	knowsPageRange:&range]){
	[numPagesCell setIntValue:range.length]; /* say how many pages */
	[self	setFrameSize:NSMakeSize(pageSize.width,pageSize.height*range.length)];
    }
    [self	setNeedsDisplay:YES];
}

- elementEnumerator
{
    return [elementList objectEnumerator];
}

- (NSFont *)font:(int)num
{
    switch(num){
    case 0: return [fontWell0 font];
    case 1: return [fontWell1 font];
    case 2: return [fontWell2 font];
    }
    return nil;
}


- (void)print:sender
{
    NSPrintInfo *pi = [NSPrintInfo sharedPrintInfo];

    [pi setRightMargin:0];
    [pi setLeftMargin:0];
    [pi setTopMargin:0];
    [pi setBottomMargin:0];

    [super print:sender];
}

@end
