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
@interface MultiPageElement:AbstractReportElement
{
	NSRect	docRect;		// part of docView that we draw
	AbstractReportView  *docView;
	float	rotation;		/* our rotation */
	int	pageNumber;		/* our page number, just for debugging */
	BOOL    debug;
	BOOL	showNotes;
}

- initForRect:(NSRect)r inDocView:(AbstractReportView *)dv;
- (void)place:(NSPoint)where rotation:(float)degrees;	
- (void)setPage:(int)aPage;
- (void)setShowNotes:(BOOL)flag;
- (void)drawElementIn:(NSView *)v offset:(NSPoint)pt;
@end
