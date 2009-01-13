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

#import "LineElement.h"


@implementation LineElement

- initFrom:(NSPoint)p0 to:(NSPoint)p1 linewidth:(float)aLinewidth color:(NSColor *)aColor
{
    [super	init];

    bounds = NSMakeRect(MIN(p0.x,p1.x)-aLinewidth,
			MIN(p0.y,p1.y)-aLinewidth,
			abs(p0.x-p1.x)+aLinewidth*2,
			abs(p0.y-p1.y)+aLinewidth*2);

    path = [[NSBezierPath bezierPath] retain];

    [path setLineWidth:aLinewidth];
    [path moveToPoint:p0];
    [path lineToPoint:p1];

    color = [aColor retain];
    return self;
}

- initFrom:(NSPoint)p0 to:(NSPoint)p1 linewidth:(float)aLinewidth
{
    return [self initFrom:p0 to:p1 linewidth:aLinewidth color:[NSColor blackColor]];
}

- (void)dealloc
{
    [path release];
    [color release];
    [super dealloc];
}

- (void)drawElementIn:(NSView *)v offset:(NSPoint)pt
{
    [[NSColor blackColor] set];
    [path	stroke];
}

@end
