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
 * The AddressBookView's page is the minipage.
 */

#import <Person.h>
#import <DefaultSwitchSetter.h>

#import "AddressBookView.h"
#import "AddressBookPanel.h"
#import "AddressElement.h"
#import "TextElement.h"
#import "FontWell.h"
#import "MultiPageView.h"

#define DPI 72.0

@implementation AddressBookView

+ (void)initialize
{
    NSMutableDictionary *appDefs = [NSMutableDictionary dictionary];
    [defaults registerDefaults:appDefs];
}

- (void)dealloc
{
    [super dealloc];
}


- (void)awakeFromNib
{
    [fontWell0 setDisplayFont:[NSFont systemFontOfSize:9]];
    [fontWell1 setDisplayFont:[NSFont systemFontOfSize:9]];
    [fontWell2 setDisplayFont:[NSFont systemFontOfSize:9]];

    [fontWell0 setSupportsColor:NO];
    [fontWell1 setSupportsColor:NO];
    [fontWell2 setSupportsColor:NO];

    [self setAddressFormat:[presetFormatPopup tagOfTitle]];

    [self addAutoconverter:gutterCell];
    [self addAutoconverter:phoneNumberWidthCell];
    [self addAutoconverter:betweenEntrySpacingCell];

    [super awakeFromNib];

}

/* Accessor methods */
- (int)columns
{
    int ret = [[columnsPopup selectedCell] tag];
    NSAssert(ret!=0,@"columnsMatrix returns 0 columns?");
    return ret;
}

- (BOOL)includeLabels 	{ return YES;}

/* Our new spaces */
- (float)gutter			{ return [self convertToPoints:[gutterCell floatValue]];}
- (float)betweenEntrySpacing 	{ return [self convertToPoints:[betweenEntrySpacingCell
								   floatValue]];}

- (BOOL) displayPhoneNumbers		// whether or not they are being displayed
{
    return [(AddressBookPanel *)[self window] showType:P_BUT_TELEPHONE];
}


/****************************************************************
   DERRIVED VALUES
 ****************************************************************/ 

- (float)columnWidth
{
    float	printable
	= [self pageSize].width - ([self leftPageMargin] + [self rightPageMargin]);

    float	gutterSpace = [self gutter] * ([self columns]-1);
    float	columnSpace = printable - gutterSpace;

    return 	columnSpace / [self columns];
}

- (float)realPhoneNumberWidth
{
    return [self convertToPoints:[phoneNumberWidthCell floatValue]];
}


- (float)phoneNumberWidth
{
    AbstractReportPanel *pan = (AbstractReportPanel *)[self window];
    if([pan showType:P_BUT_TELEPHONE]==NO){
	return 0.0;
    }
	
    if(![pan showType:P_BUT_ADDRESS]){
	/* Not showing addresses; expand phone to whole entry */
	return [self columnWidth];
    }

    /* only return our part */
    return [self realPhoneNumberWidth];
}

- (void)setMargins:(float)margin
	    gutter:(float)gutter
  phoneNumberWidth:(float)width
 betweenEntrySpace:(float)space
	   columns:(int)cols
	     folds:(int)folds
{
    [self setLeftMargin:margin rightMargin:margin topMargin:margin bottomMargin:margin];

    [gutterCell			setFloatValue:[self convertFromPoints:gutter]];
    [phoneNumberWidthCell	setFloatValue:[self convertFromPoints:width]];
    [betweenEntrySpacingCell	setFloatValue:[self convertFromPoints:space]];
    [columnsPopup	selectItemWithTag:cols];

    [multiPageView	setFolds:folds];
}


/* Set the address to a pre-defined report type */
- (void)setAddressFormat:(int)tag
{
	NSEnumerator *en;
	id obj;
	bool isManual = (tag==0);

	[multiPageView	setEnabled:isManual];
	[columnsPopup	setEnabled:isManual];


	switch(tag){
	case 0:				// manual
	    return;
	    
	      case 1:			/* address book */
		  [self 	setMargins:.25 * DPI 		gutter:DPI/6.0
				phoneNumberWidth:1.5 * DPI 	betweenEntrySpace:DPI/12.0
				columns:2 folds:0];
		  [fontWell0	setFont:[NSFont fontWithName:@"Times-Bold" size:9.0]];
		  [fontWell1	setFont:[NSFont fontWithName:@"Times-Roman" size:7.0]];
		  [fontWell2	setFont:[NSFont fontWithName:@"Times-Roman" size:7.0]];
		  break;

	      case 2:			/* day planner */
		  [self 	setMargins:.5 * DPI 		gutter:0
				phoneNumberWidth:1.25 * DPI 	betweenEntrySpace:.1 * DPI
				columns:1 folds:0];
		  [fontWell0	setFont:[NSFont fontWithName:@"Times-Bold"  size:9.0]];
		  [fontWell1	setFont:[NSFont fontWithName:@"Times-Roman" size:7.0]];
		  [fontWell2	setFont:[NSFont fontWithName:@"Times-Roman" size:7.0]];
		  break;

	      case 3:			/* Pocket-book 1 fold */
		  [self 	setMargins:.5 * DPI		gutter:0.5 * DPI
				phoneNumberWidth:1.25 * DPI 	betweenEntrySpace:.1 * DPI
				columns:2 folds:1];
		  [fontWell0	setFont:[NSFont fontWithName:@"Times-Bold"  size:9.0]];
		  [fontWell1	setFont:[NSFont fontWithName:@"Times-Roman" size:7.0]];
		  [fontWell2	setFont:[NSFont fontWithName:@"Times-Roman" size:7.0]];
		  break;

	      case 4:			/* Pocket-book 2 fold */
		  [self 	setMargins: 0.2  * DPI		gutter:0.2 * DPI
				phoneNumberWidth:0.6 * DPI 	betweenEntrySpace:.1 * DPI
				columns:2 folds:2];
		  [fontWell0	setFont:[NSFont fontWithName:@"Times-Bold"  size:7.0]];
		  [fontWell1	setFont:[NSFont fontWithName:@"Times-Roman" size:6.0]];
		  [fontWell2	setFont:[NSFont fontWithName:@"Times-Roman" size:6.0]];
		  break;

	      case 5:			/* Pocket-book 3 fold */
		  [self 	setMargins: 0.2  * DPI		gutter:0.10 * DPI
				phoneNumberWidth:1 * DPI 	betweenEntrySpace:.05 * DPI
				columns:1 folds:3];
		  [fontWell0	setFont:[NSFont fontWithName:@"Times-Bold"  size:6.0]];
		  [fontWell1	setFont:[NSFont fontWithName:@"Times-Roman" size:5.0]];
		  [fontWell2	setFont:[NSFont fontWithName:@"Times-Roman" size:5.0]];
		  break;

	}

	en = [displayList objectEnumerator];
	while(obj = [en nextObject]){
	    if([obj respondsToSelector:@selector(set)]){
		[obj set];
	    }
	}
}

- (void)changedPresetAddress:sender
{
    [self setAddressFormat:[presetFormatPopup tagOfTitle]];
    [self changedLayoutInformation:nil];
}



- (void)insertPageNumber:(int)pageNumber
{
#if 0 
    /* We do not have TextElement debugged yet */
    NSFont *font = [fontWell0 font];
    id	pn = [[[TextElement alloc] init] autorelease];
    
    float x = (pageNumber % 2) ? pageWidth - 24.0 : 24.0;
    float y = ((pageNumber-1) * pageHeight) + pageHeight - [self bottomPageMargin] + [font pointSize]/2.0;

    [pn	setFont:0 to:font];
    [pn	setText:[NSString stringWithFormat:@"-%d-",pageNumber]];
    [pn	setCenter:NSMakePoint(x,y)];
    [displayList	addObject:pn];
#endif
}


/* Layout algorithm:
 *  1.  Tell BookView how big each page is.
 *  2.	Tell each entry its width
 *  2.  Tell BookView it has a new list.
 */
- (void)changedLayoutInformation:sender
{
    NSEnumerator *en = [elementList objectEnumerator]; // list of address elements
    AddressElement *ent = nil;
    float	x = 0;
    id		previousEnt = nil;
    int		pages=0;
    int		numColumns = [self columns];
    float	columnWidth,phoneNumberWidth,columnOffset,heightThisPage;
    float	betweenEntrySpacing;
    int		column = 0;
    BOOL	firstEntry = YES;
    AddressBookPanel *panel = (AddressBookPanel *)[self window];
    BOOL	displayPersonNames = [panel showType:P_BUT_PERSON];
    NSString	*lastPerson = nil;
    float	height = [self pageSize].height;


    [multiPageView	setPageSizeFromPopup];

    columnWidth		= [self columnWidth];
    phoneNumberWidth	= [self phoneNumberWidth];
    columnOffset	= columnWidth + [self gutter];
    heightThisPage	= [self topPageMargin];
    betweenEntrySpacing = [self betweenEntrySpacing];

    if([elementList count]==0){
	[self   setNumPages:0];
	[super  changedLayoutInformation:nil];
	return;
    }

    [layoutProgress setMinValue:0];
    [layoutProgress setMaxValue:[displayList count]];
    [layoutProgress setDoubleValue:0];

    /* Loop through all entries in the display list.
     * Each entry corresponds to a different name/address block.
     *
     * We display the person name whenever the person's name changes
     * or when we are at the top of a new block
     */
    ent = [en nextObject]; // get the first element
    while(ent){
	id nextEnt = [en nextObject];

	if(firstEntry){
	    heightThisPage	= [self topPageMargin];
	    pages		= 1;
	    column		= 1;
	    x			= [self leftPageMargin];
	    [numPagesCell	setIntValue:pages];
	    firstEntry = NO;
	}

	if(displayPersonNames && ![lastPerson isEqualTo:[ent person]]){
	    [ent setDisplayPersonName:YES]; // display the name!
	    [lastPerson release];
	    lastPerson = [[ent person] retain];
	}

	// tell it the new width
	[ent    setWidth:columnWidth phoneWidth:phoneNumberWidth]; 
	[displayList addObject:ent];
	[layoutProgress incrementBy:1.0];

	if((heightThisPage + [ent height]) > (height-[self bottomPageMargin])){

	    /* Entry does not fit in this column */
	    if(displayPersonNames){
		[ent	setDisplayPersonName:YES];
	    }
	    if(++column <= numColumns){
		/* bump it to the next column */
		x		+= columnOffset;
	    }
	    else{
		/* bump to the next page */
		pages++;
		column		= 1;
		x		= [self leftPageMargin];
		[numPagesCell setIntValue:pages];
	    }
	    /* Reset the height */
	    heightThisPage	= [self topPageMargin];
	}

	/* Place the entry */
	[ent	setOrigin:NSMakePoint(x,heightThisPage + (pages-1)*height)];
	//NSLog(@"origin y=%f",heightThisPage);

	heightThisPage	+= [ent height];
	if([ent person] != [nextEnt person]){ /* space down for next entry */
	    heightThisPage += betweenEntrySpacing;
	    //NSLog(@"Adding %f %@!=%@",betweenEntrySpacing,[ent person],[nextEnt person]);
	}
	previousEnt	= ent;
	ent		= nextEnt;
    }
    [self		setNumPages:pages];
    [layoutProgress	setDoubleValue:[displayList count]];
    [super		changedLayoutInformation:nil];
    [self		setNeedsDisplay:YES];
}

- (NSFont *)fontForTag:(int)tag
{
    if(tag==P_BUT_TELEPHONE) return [fontWell2 font];
    if(tag==P_BUT_PERSON || tag==P_BUT_COMPANY) return [fontWell0 font];
    return [fontWell1 font];
}

- (NSDictionary *)fontAttrsForTag:(int)tag
{
    if(tag==P_BUT_TELEPHONE) return [fontWell2 fontAttributes];
    if(tag==P_BUT_PERSON || tag==P_BUT_COMPANY) return [fontWell0 fontAttributes];
    return [fontWell1 fontAttributes];
}

- (void)prepareForReport
{
    [self displayPaperSize];
    [multiPageView displayPaperSize];
    [super prepareForReport];
}

@end
