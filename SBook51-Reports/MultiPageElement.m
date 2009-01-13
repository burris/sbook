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

#import <appkit/appkit.h>

#import "MultiPageElement.h"
#import "MultiPageView.h"

@implementation MultiPageElement

static NSFont *ft=nil;
static NSDictionary *attrs=nil;

+(void)initialize
{
    ft = [[NSFont fontWithName:@"Times" size:10.0] retain];
    attrs = [[NSDictionary dictionaryWithObjectsAndKeys:
			       ft, NSFontAttributeName,
			   [NSColor blackColor],NSStrokeColorAttributeName,
			   0,0] retain];
}

- initForRect:(NSRect)r inDocView:(AbstractReportView *)v 
{
	[super	init];
	docRect		= r;
	bounds.origin   = NSMakePoint(0,0);
	bounds.size	= docRect.size;
	docView		= v;
	rotation = 0;

	NSLog(@"initForRect %@",self);
	return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (page %d) rot=%g docRect=(%g,%g) / (%g,%g) notes=%d docView=%@",
		     [super description],pageNumber,rotation,
		     NSMinX(docRect), NSMinY(docRect),
		     NSWidth(docRect), NSHeight(docRect),
		     showNotes,
		     docView ];
}

- (void)place:(NSPoint)where rotation:(float)degrees
{
    /* If we are turning on side, swap height and width */
    if(degrees==90 || degrees==-90 || degrees==270){
	float t = bounds.size.width;
	bounds.size.width = bounds.size.height;
	bounds.size.height = t;
    }
    rotation = degrees;
    bounds.origin = where;
}

- (void)setPage:(int)num { pageNumber = num;}
- (void)setDebug:(BOOL)flag
{
    debug = flag;
}
- (void)setShowNotes:(BOOL)flag
{
    showNotes = flag;
}

inline NSPoint center(NSRect r){
    return NSMakePoint(NSMidX(r),NSMidY(r));
}

- (void)drawElementIn:(NSView *)v offset:(NSPoint)pt
{
    NSPoint	boundsCenter = center(bounds);
    NSPoint	docRectCenter   = center(docRect);
    NSAffineTransform *t = [NSAffineTransform transform];
    
    NSLog(@"drawElement %@",self);

    /* 1. Translate to the center of where we should be
     * 2. Rotate.
     * 3. Translate to the center of where we should be
     */

    [t	translateXBy:boundsCenter.x yBy:boundsCenter.y];
    [t	rotateByDegrees:rotation];
    pt.x += -docRectCenter.x;
    pt.y += -docRectCenter.y;

    [t  concat];
    
    if(showNotes || 1){
	NSBezierPath *bp = [NSBezierPath bezierPath];
	float y = NSMinY(docRect) + NSHeight(docRect)*.2;

	NSString *str = [NSString stringWithFormat:@"Notes for Page %d",pageNumber];

	float w = [ft widthOfString:str];

	[[NSColor blackColor] set];
	[bp setLineWidth:2.0];
	[bp moveToPoint:MakeOffsetPoint(NSMakePoint(NSMinX(docRect)+NSWidth(docRect)*.1,y), pt)];

	[bp relativeLineToPoint:NSMakePoint(NSWidth(docRect)*.2,0)];
	[bp relativeMoveToPoint:NSMakePoint(NSWidth(docRect)*.4,0)];
	[bp relativeLineToPoint:NSMakePoint(NSWidth(docRect)*.2,0)];
	[bp stroke];

	[str drawAtPoint:MakeOffsetPoint(NSMakePoint(NSMidX(docRect)-w/2,y-10), pt)
	   withAttributes:attrs];

    }

    if(!showNotes){
	[docView	drawRect:docRect withOffset:pt]; /* draw the subview */
    }
	
    /* put it back */
    [t	invert];
    [t  concat];
}

@end
