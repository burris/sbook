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

#import "AbstractReportElement.h"
#import "AbstractReportView.h"

@implementation AbstractReportElement
 
- (NSRect)bounds	         { return bounds; }	
- (void)setBounds:(NSRect)rect   { bounds = rect;      }
- (void)setOrigin:(NSPoint)pt	 { bounds.origin = pt; }
- (void)setSize:(NSSize)size     { bounds.size = size; }
- (void)setx:(float)x y:(float)y { [self setOrigin:NSMakePoint(x,y)];}
- (void)setWidth:(float)aWidth	 { bounds.size.width = aWidth; }
- (void)setHeight:(float)aHeight { bounds.size.height = aHeight; }


- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ bounds=(%g,%g) / (%g,%g)",
		     [super description],
		     NSMinX(bounds), NSMinY(bounds),
		     NSWidth(bounds), NSHeight(bounds)];
}

- (void)screenStroke:(NSRect)r color:(NSColor *)aColor
{
    if([NSGraphicsContext currentContextDrawingToScreen]==YES){
	[aColor set];
	NSFrameRectWithWidth(r,1.0);
    }
}

- (void)drawElementIn:(NSView *)v offset:(NSPoint)pt
{
    [self screenStroke:MakeOffsetRect(bounds,pt) color:[NSColor greenColor]];
}


- (void)addLine:(NSString *)buf tag:(int)tag
{
    NSAssert(0,@"addLine:tag: must be subclassed in AbstractReportElement");
}

@end



