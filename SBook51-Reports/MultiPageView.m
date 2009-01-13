/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2003 by Simson L. Garfinkel.
 *
 *
 */

#import "MultiPageView.h"
#import "MultiPageElement.h"
#import "LineElement.h"
#import "TextElement.h"


#define FLIP_MSG @"When printing is done, remove paper stack from output area, turn over, and re-load stack in paper tray."

@implementation MultiPageView

- initWithFrame:(NSRect )f
{
	[super	initWithFrame:f];

	foldFont	= [NSFont fontWithName:@"Times-Roman" size:6.0];
	folds = 0;
	return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (unsigned int)folds { return folds;}

- (void)setFolds:(unsigned int)numFolds
{
    if(folds==numFolds) return;		// already set

    [foldsPopup selectItemWithTag:numFolds]; // fix what the popup says
    folds	= numFolds;		// 
    [self setPageSize:[self pageSize]];	// reset the page size; sets the subview
    [self setNeedsDisplay:YES];
    [self layout:nil];
}

- (void)setDocView:(AbstractReportView *)aDocView			// the view
{
	docView	= aDocView;
}

- (void)setShowNotes:(BOOL)flag { showNotes = flag;}


- (void)setPrintOption:(int)opt
{
	printOption	= opt;
}

/* Need to make this two staples and the text */
- (void)addStaple:(NSPoint)pt0 rotate:(float)rotate
{
    float offset;
    float PI = 355.0/113.0;
    float rads = rotate * PI / 180.0;

    for(offset=-20;offset<=20;offset+=40){
	NSPoint pt = NSMakePoint(pt0.x + cos(rads) * offset,
				 pt0.y + sin(rads) * offset);

	[displayList addObject:
			 [[LineElement alloc]
			     initFrom:NSMakePoint(pt.x-4,pt.y-4)
			     to:NSMakePoint(pt.x+4,pt.y+4)
			     linewidth:1.0]];
    
	[displayList addObject:
			 [[LineElement alloc]
			     initFrom:NSMakePoint(pt.x-4,pt.y+4)
			     to:NSMakePoint(pt.x+4,pt.y-4)
			     linewidth:1.0]];
    }
    [displayList addObject:[[TextElement alloc]
			       initText:@"staple"
			       center:pt0
			       rotate:rotate
			       font:foldFont]];
}




- (void)addFirstLineAt:(float)y0 staple:(BOOL)sflag
{
    float	y	= y0 + pageHeight/2.0;

	[displayList addObject:[[LineElement alloc]
			      initFrom:NSMakePoint(0.0,y)
			      to:NSMakePoint(pageWidth,y)
			      linewidth:1.0]];

	if(sflag){
		[self	addStaple:NSMakePoint(pageWidth * .2,y) rotate:0.0];
		[self	addStaple:NSMakePoint(pageWidth * .5,y) rotate:0.0];
		[self	addStaple:NSMakePoint(pageWidth * .8,y) rotate:0.0];
	}


	[displayList addObject:[[TextElement alloc]
				   initText:@"first fold" 
				   center:NSMakePoint(pageWidth*.4,y)
				   rotate:0.0
				   font:foldFont
	 ]];

	[displayList addObject:[[TextElement alloc]
				   initText:@"first fold" 
				   center:NSMakePoint(pageWidth*.6,y)
				   rotate:0.0
				   font:foldFont
	 ]];

}

- (void)addSecondLineAt:(float)y staple:(BOOL)sflag
{
    [displayList addObject:[[LineElement alloc]
			       initFrom:NSMakePoint(pageWidth/2.0,y)
			       to:NSMakePoint(pageWidth/2.0,y+pageHeight/2.0)
			       linewidth:1.0]];

    if(sflag){
	[self addStaple:NSMakePoint(pageWidth/2.0,y+pageHeight*.1) rotate:90.0];
	[self addStaple:NSMakePoint(pageWidth/2.0,y+pageHeight*.4) rotate:90.0];
    }

    [displayList addObject:[[TextElement alloc]
			       initText:@"second fold"
			       center:NSMakePoint(pageWidth/2.0,y+pageHeight*.25)
			       rotate:90.0
			       font:foldFont
     ]];
}

- (void)addThirdLineAt:(float)y0 staple:(BOOL)sflag
{
	float y	= y0 + pageHeight*.25;

	[displayList addObject:[[LineElement alloc]
				   initFrom:NSMakePoint(pageWidth/2.0,y)
				   to:NSMakePoint(pageWidth,y)
				   linewidth:1.0]];


	if(sflag){
		[self	addStaple:NSMakePoint(pageWidth*.6,y) rotate:0.0];
		[self	addStaple:NSMakePoint(pageWidth*.9,y) rotate:0.0];
	}

	[displayList addObject:[[TextElement alloc]
				   initText:@"third fold"
				   center:NSMakePoint(pageWidth*.75,y)
				   rotate:0.0
				   font:foldFont ]];
}

/* place an ordinary book */
- (void)layout0
{
	int	i;
	int	entries = [elementList count];

	for(i=0;i<entries;i++){
	    MultiPageElement	*ie 	= [elementList objectAtIndex:i];
	    int	page 	= i+1;
	    float	pageOff = pageHeight*(page-1);

	    [ie place:NSMakePoint(0,pageOff) rotation:0];
	}
}

/* layout a single-fold book
 * It appears that (x,y) of the placed page is always the
 * top-left corner on the final output page.
 * Rotation is how the page is rotated.
 * docFrame is the section on the docView page; it is never rotated.
 * rotation is counter-clockwise in degrees
*/
- (void)layout1
{
    unsigned int i;
    unsigned int pageCount = 0;

    for(i=0;i<docPagesToPlace/2;i+=2){
	MultiPageElement *first  = [elementList objectAtIndex:i];
	MultiPageElement *second = [elementList objectAtIndex:i+1];
	MultiPageElement *last2  = [elementList objectAtIndex:(docPagesToPlace-1) - (i+1)];

	MultiPageElement *last   = [elementList objectAtIndex:(docPagesToPlace-1) - i];
	float	p1y	= pageHeight*pageCount;
	float	p2y	= pageHeight*(pageCount+1);

	[first  place:NSMakePoint(0.0,p1y) rotation:-90.0];
	[second place:NSMakePoint(0.0,p2y) rotation:90.0];
	[last2  place:NSMakePoint(0.0,p2y + pageHeight/2.0) rotation:90.0];
	[last   place:NSMakePoint(0.0,p1y + pageHeight/2.0) rotation:-90.0];
	
	[self	addFirstLineAt:p1y staple:YES];
	pageCount+=2;
    }
}

- (void)layout2
{
    unsigned int pageCount = 0;
    unsigned int i;

    for(i=0;i<docPagesToPlace/2;i+=4){ /* 4 docPages per page */
	id	a = [elementList objectAtIndex:i];
	id	b = [elementList objectAtIndex:i+1];
	id	c = [elementList objectAtIndex:i+2];
	id	d = [elementList objectAtIndex:i+3];
	
	id	w  = [elementList objectAtIndex:(docPagesToPlace-1) - (i+3)];
	id	x  = [elementList objectAtIndex:(docPagesToPlace-1) - (i+2)];
	id	y  = [elementList objectAtIndex:(docPagesToPlace-1) - (i+1)];
	id	z  = [elementList objectAtIndex:(docPagesToPlace-1) - i];
	
	float	p1y	= pageHeight*pageCount;
	float	p2y	= pageHeight*(pageCount+1);
	
	[a place:NSMakePoint(pageWidth/2.0,p1y) rotation:0.0];

	[b place:NSMakePoint(0.0,p2y) rotation:0.0];

	[c place:NSMakePoint(0.0,p2y + pageHeight/2.0) rotation:180.0];

	[d place:NSMakePoint(pageWidth/2.0,p1y+pageHeight/2.0) rotation:180.0];

	[w place:NSMakePoint(0.0,p1y+pageHeight/2.0) rotation:180.0];

	[x place:NSMakePoint(pageWidth/2.0,p2y+pageHeight/2.0) rotation:180.0];

	[y place:NSMakePoint(pageWidth/2.0,p2y) rotation:0.0];

	[z place:NSMakePoint(0.0,p1y) rotation:0.0];

	[self	addFirstLineAt:p1y staple:NO];
	[self	addSecondLineAt:p1y staple:YES];
	pageCount+=2;
    }
}



- (void)layout3
{
    unsigned int i;
    unsigned int pageCount = 0;

    for(i=0;i<docPagesToPlace/2;i+=8){ /* 8 docPages per page */
	id	a = [elementList objectAtIndex:i];
	id	b = [elementList objectAtIndex:i+1];
	id	c = [elementList objectAtIndex:i+2];
	id	d = [elementList objectAtIndex:i+3];
	id	e = [elementList objectAtIndex:i+4];
	id	f = [elementList objectAtIndex:i+5];
	id	g = [elementList objectAtIndex:i+6];
	id	h = [elementList objectAtIndex:i+7];

	id	s  = [elementList objectAtIndex:(docPagesToPlace-1) - (i+7)];
	id	t  = [elementList objectAtIndex:(docPagesToPlace-1) - (i+6)];
	id	u  = [elementList objectAtIndex:(docPagesToPlace-1) - (i+5)];
	id	v  = [elementList objectAtIndex:(docPagesToPlace-1) - (i+4)];
	id	w  = [elementList objectAtIndex:(docPagesToPlace-1) - (i+3)];
	id	x  = [elementList objectAtIndex:(docPagesToPlace-1) - (i+2)];
	id	y  = [elementList objectAtIndex:(docPagesToPlace-1) - (i+1)];
	id	z  = [elementList objectAtIndex:(docPagesToPlace-1) - i];

	float	x1	= pageWidth * .50;
	
	float	y0	= pageHeight * pageCount;
	float	y1	= pageHeight * (pageCount+.25);
	float	y2	= pageHeight * (pageCount+.5);
	float	y3	= pageHeight * (pageCount+.75);

	[a	place:NSMakePoint(x1,y1) rotation:90.0]; /* 1 */
	[b	place:NSMakePoint(0.0  ,y1+pageHeight) rotation:-90.0];	 /* 2 */
	[c	place:NSMakePoint(0.0  ,y2+pageHeight) rotation:-90.0];	 /* 3 */
	[d	place:NSMakePoint(x1   ,y2) rotation:90.0]; /* 4 */
	[e	place:NSMakePoint(0.0  ,y2) rotation:-90.0]; /* 5 */
	[f	place:NSMakePoint(x1   ,y2+pageHeight) rotation:90.0];	 /* 6 */
	[g	place:NSMakePoint(x1	  ,y1+pageHeight) rotation:90.0];	 /* 7 */
	[h	place:NSMakePoint(0.0  ,y1) rotation:-90.0]; /* 8 */

	[s	place:NSMakePoint(0.0  ,y0) rotation:-90.0]; /* 9 */
	[t	place:NSMakePoint(x1   ,y0+pageHeight) rotation:90.0];	 /* 10 */
	[u	place:NSMakePoint(x1   ,y3+pageHeight) rotation:90.0];	 /* 11 */
	[v	place:NSMakePoint(0.0  ,y3) rotation:-90.0];	 /* 12 */
	[w	place:NSMakePoint(x1   ,y3) rotation:90.0];	 /* 13 */
	[x	place:NSMakePoint(0.0  ,y3+pageHeight) rotation:-90.0];	 /* 14 */
	[y	place:NSMakePoint(0.0  ,y0+pageHeight) rotation:-90.0];	 /* 15 */
	[z	place:NSMakePoint(x1   ,y0) rotation:90.0];	 /* 16 */

	[self	addFirstLineAt:y0 staple:NO];
	[self	addSecondLineAt:y0 staple:NO];
	[self	addThirdLineAt:y0 staple:YES];

	pageCount+=2;
    }
}

/* Actually do the layout */
- (IBAction)layout:sender
{
    unsigned int i=0;
    unsigned int pages=0;

    if(![docView knowsPageRange:&docPageRange]){
	NSLog(@"MultiPageView::layout  docView %@ doesn't know page range",docView);
	return;		/* can't do it */
    }

    {
	NSSize pageSize = [self pageSize];
	pageHeight = pageSize.height;
	pageWidth  = pageSize.width;
    }


    [self	clearElementList];

    [self prepareForReport];		// gets the page size, among other things
    docPageSize=[docView rectForPage:1].size;

    switch(folds){
    default: docPagesPerPage = 1;break;
    case 1:  docPagesPerPage = 2;break;
    case 2:  docPagesPerPage = 4;break;
    case 3:  docPagesPerPage = 8;break;
    }

    /* Number of pages is number of faces.  Half the number of sheats */
    pages = (docPageRange.length + docPagesPerPage - 1) / docPagesPerPage; 
    if(pages % 2 == 1){
	pages++;		/* page page */
    }
    docPagesToPlace	= docPagesPerPage * pages;

    [self setNumPages:pages];


	
    for(i=docPageRange.location;i<docPageRange.location+docPagesToPlace;i++){

	/* Notes shoudl be displayed by the MultiPageElement... */
	NSRect docFrame		= [docView rectForPage:i];
	MultiPageElement *sv 	= [[MultiPageElement alloc]
				      initForRect:docFrame inDocView:docView];

	[sv setPage:i];
	
	if(i>=docPageRange.location+docPageRange.length){
	    [sv setShowNotes:YES];		// this is a notes page;
	}

	[elementList addObject:sv];
	[displayList addObject:sv];
    }


    /* Now place the pages in the correct position */
    switch(folds){
    default:	[self	layout0];break;
    case 1:	[self	layout1];break;
    case 2:	[self	layout2];break;
    case 3:	[self	layout3];break;
    }
    [super	changedLayoutInformation:nil];
}


- (NSRect)rectForPage:(int)page
{
    NSLog(@"MultiPageView: rectForPage %d",page);
#if 0
    switch(printOption){
    case PRINT_TOPS:
	return [super rectForPage:page*2];
    case PRINT_BOTTOMS:
	return [super rectForPage:page*2 - 1];
    }
#endif
    return [super rectForPage:page];
}

- (BOOL)knowsPageRange:(NSRangePointer)range
{
    if(![super	knowsPageRange:range]){
	return NO;
    }
    totalPages	= range->length;
    if(printOption != PRINT_ALL){
	range->length /= 2;
    }
    return YES;
}

- (void)print:sender
{
    NSPrintInfo *pi = [NSPrintInfo sharedPrintInfo];

    [pi setRightMargin:0];
    [pi setLeftMargin:0];
    [pi setTopMargin:0];
    [pi setBottomMargin:0];


    [super print:sender];
    return;

    //    if([printOptionsCover tagOfTitle]==PRINT_ALL){
	[super print:sender];
	return;
	//}

    [self	setPrintOption:PRINT_TOPS];
    [super	print:self];
    if(!NSRunAlertPanel(0,FLIP_MSG,
			@"OK, continue printing",
			@"Cancel",0)){
	return;
    }
    [self	setPrintOption:PRINT_BOTTOMS];
    [super	print:self];
}

- (void)setEnabled:(BOOL)flag		// controls popup
{
    [foldsPopup setEnabled:flag];
}

- (IBAction)foldsChanged:(id)sender
{
    [self setFolds:[foldsPopup tagOfTitle]];
}


/****************************************************************
 **
 ** Chained events...
 ** When these are changed, we also need to propiage it to the doc view.
 **
 ****************************************************************/

- (void)displayPaperSize
{
    [docView    displayPaperSize];
    [super	displayPaperSize];
}

- (void)setPageSize:(NSSize)pageSize
{
    [super setPageSize:pageSize];

    /* Set the page size of the doc View */
    switch(folds){
    case 0:
	[docView setPageSize:pageSize];
	break;
    case 1:
	[docView setPageSize:NSMakeSize(pageSize.height/2,pageSize.width)];
	break;
    case 2:
	[docView setPageSize:NSMakeSize(pageSize.width/2,pageSize.height/2)];
	break;
    case 3:
	[docView setPageSize:NSMakeSize(pageSize.height/4,pageSize.width/2)];
	break;
    }
}

- (void)addSubview:(NSView *)v
{
    NSLog(@"MultiPageView %@ add subview %@",self,v);
    [super addSubview:v];
}

@end
