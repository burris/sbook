/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2002 by Simson Garfinkel
 *
 * All Rights Reserved.
 *
 * AbstractReportElement --- the basic rectangular text block
 * used for address books and mailing labels.
 * 
 *
 */

#import <Cocoa/Cocoa.h>

@class AbstractReportPanel;
@class AbstractReportView;
@interface AbstractReportElement:NSObject
{
	NSRect		bounds;		// bounds of element
}
- (NSRect)bounds;
- (void)setBounds:(NSRect)rect;
- (void)setOrigin:(NSPoint)pt;
- (void)setSize:(NSSize)size;
- (void)setx:(float)x y:(float)y;
- (void)setWidth:(float)aWidth;
- (void)setHeight:(float)aHeight;
- (void)screenStroke:(NSRect)r color:(NSColor *)aColor; // draw the rectangle on the screen
- (void)drawElementIn:(NSView *)v offset:(NSPoint)pt;
- (void)addLine:(NSString *)buf tag:(int)tag; // must be subclassed
@end

static inline NSRect MakeOffsetRect(NSRect r,NSPoint pt){
    return NSMakeRect(NSMinX(r)+pt.x,
		      NSMinY(r)+pt.y,
		      NSWidth(r),
		      NSHeight(r));
}

static inline NSPoint MakeOffsetPoint(NSPoint p1,NSPoint p2){
    return NSMakePoint(p1.x+p2.x,
		       p1.y+p2.y);
}


