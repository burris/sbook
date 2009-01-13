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

#import "PageElement.h"
//#import "ReportView.h"

@implementation PageElement

- initForRect:(NXRect *)r inReportView:v 
{

	[super	init];
	rect		= *r;
	bounds.size	= rect.size;
	rview		= v;
	return self;
}

- debugInfo
{
	printf("page=%d  rect=%g,%g - %g,%g   bounds=%g,%g - %g,%g\n",
	       pageNumber,
	       NX_X(&rect),NX_Y(&rect),NX_WIDTH(&rect),NX_HEIGHT(&rect),
	       NX_X(&bounds),NX_Y(&bounds),NX_WIDTH(&bounds),NX_HEIGHT(&bounds));

	return self;
}

- setRotation:(float)rot { rotation = rot; return self; }
- setPageNumber:(int)num { pageNumber = num;return self;}
- (int) pageNumber  { return pageNumber;}

- drawPSInView:v
{
	NXPoint	boundsCenter = [self center:bounds];
	NXPoint	rectCenter   = [self center:rect];

	/* 1. Translate to the center of where we should be
	 * 2. Rotate.
	 * 3. Translate to the center of where we should be
	 */

	[v	translate:boundsCenter.x :boundsCenter.y];
	[v	rotate:rotation];
	[v	translate:-rectCenter.x :-rectCenter.y];

	[rview	drawPS:&rect :1 inView:v]; /* draw PS */
	
	/* put it back */
	[v	translate:rectCenter.x :rectCenter.y];
	[v	rotate:-rotation];
	[v	translate:-boundsCenter.x :-boundsCenter.y];
	
	return self;
}

@end
