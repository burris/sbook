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

@class Person;
@interface TextElement:AbstractReportElement
{
    NSString	*text;	// block of text
    NSPoint	center;
    NSFont	*font;
    float	rotation;
}

- initText:(NSString *)text center:(NSPoint)pt rotate:(float)r font:(NSFont *)ft;


@end
