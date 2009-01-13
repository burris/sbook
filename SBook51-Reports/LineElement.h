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

@interface LineElement:AbstractReportElement
{
    NSBezierPath *path;
    float	linewidth;
    NSColor	*color;
}

- initFrom:(NSPoint)p0 to:(NSPoint)p1 linewidth:(float)linewidth color:(NSColor *)c;
- initFrom:(NSPoint)p0 to:(NSPoint)p1 linewidth:(float)linewidth;
@end
