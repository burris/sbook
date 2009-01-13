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

#import "TextElement.h"

@implementation TextElement

static NSFont *ft = nil;
static NSDictionary *attrs = nil;

+(void) initialize
{
    ft = [[NSFont labelFontOfSize:8.0] retain];
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
					    ft,NSFontAttributeName,
					0,0];
    [ft retain];
    [attrs retain];
}


- initText:(NSString *)text_ center:(NSPoint)pt rotate:(float)r font:(NSFont *)ft
{
    float textWidth;

    [super	init];
    rotation	= r;
    center	= pt;
    font        = [ft retain];
    text	= [text_ copy];

    textWidth	= [ft widthOfString:text];

    bounds.origin.x = center.x - textWidth/2.0;
    bounds.origin.y = center.y - textWidth/2.0;
    bounds.size.width = textWidth;
    bounds.size.height = textWidth;

    /* Calculate the bounds */
    return self;
}

- (void)dealloc
{
    [text release];
    [super dealloc];
}

- (void)drawElementIn:(NSView *)v offset:(NSPoint)pt
{
    NSAffineTransform *t = [NSAffineTransform transform];
    NSPoint where = bounds.origin;
    if(rotation!=0){

	[t translateXBy:center.x yBy:center.y];
	[t rotateByDegrees:rotation];
	[t concat];
	where.x += -center.x;
	where.y += -center.y;
    }

    [text drawAtPoint:where withAttributes:attrs];

    if(rotation!=0){

	[t invert];
	[t concat];
    }
}



@end
