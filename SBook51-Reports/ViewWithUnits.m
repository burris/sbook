#import <DefaultSwitchSetter.h>

#import "ViewWithUnits.h"

#define DEF_UNITS	@"DefaultUnits"
#define DEF_PAPERSIZE	@"PaperSize"

@implementation NSPopUpButton(mpv)
- (int)tagOfTitle
{
    return [[self itemWithTitle:[self title]] tag];
}
- (void)selectItemWithTag:(int)tag
{
    int index = [self indexOfItemWithTag:tag];

    if(index>=0){
	[self selectItemAtIndex:index];
    }
}
@end



@implementation ViewWithUnits

+ (NSString *)convertPointsToUnits:(double)value tag:(int)tag
{
    switch(tag){
    case TAG_INCHES: return [NSString stringWithFormat:@"%g\"",value/72.0];
    case TAG_CM:     return [NSString stringWithFormat:@"%g cm",(value*2.54/72.0)];
    case TAG_MM:     return [NSString stringWithFormat:@"%g mm",(value*25.4/72.0)];
    case TAG_POINTS: return [NSString stringWithFormat:@"%g points",value];
    case TAG_PICAS:  return [NSString stringWithFormat:@"%g picas",value/12.0];
    }
    NSLog(@"tag=%d",tag);
    NSAssert(0,@"tag is invalid");
    return @"Unknown tag";
}

-initWithFrame:(NSRect)aRect
{
    [super initWithFrame:aRect];
    autoConvertArray	= [[NSMutableArray alloc] init];
    printInfo		= [[NSPrintInfo sharedPrintInfo] retain];
    return self;
}

- (void)dealloc
{
    [autoConvertArray release];
    [printInfo release];
    [super dealloc];
}

- (void)addAutoconverter:obj
{
    if(obj){
	[autoConvertArray addObject:obj];
    }
}


-(void)awakeFromNib
{
    setDefault(unitsPopup,DEF_UNITS);
    setDefault(paperSizePopup,[NSString stringWithFormat:@"%@ %@",DEF_PAPERSIZE,
					[self description]]);
    oldUnitsTag = [unitsPopup tagOfTitle];
}

- (double)unitMultiplierForTag:(int)tag
{
    switch(tag){
    case TAG_INCHES:	return 72.0;
    case TAG_CM:	return 72.0 / 2.54;
    case TAG_MM:	return 72.0 / 25.4;
    case TAG_POINTS:	return 1;
    case TAG_PICAS:	return 72.0 / 6.0;
    }
    NSLog(@"tag=%d",tag);
    NSAssert(0,@"[AbstractReportPanel convertToPoints] Unknown Tag");
    return 0;
}

- (double)convertToPoints:(double)value
{
    return value * [self unitMultiplierForTag:[unitsPopup tagOfTitle]];
}

- (double)convertFromPoints:(double)value
{
    return value / [self unitMultiplierForTag:[unitsPopup tagOfTitle]];
}

- (NSSize)paperSizeForTag:(int)tag
{
    switch(tag){
    case TAG_PAPER_US_LETTER:	return NSMakeSize(8.5*72,11*72);
    case TAG_PAPER_A4:		return NSMakeSize(8.26*72.0,11.69*72.0);
    }
    NSLog(@"tag=%d",tag);
    //NSAssert(0,@"Unknown tag in paperSizeForTag");
    return NSMakeSize(0,0);
}

- (int)unitsTag
{
    return [unitsPopup tagOfTitle];
}

-(void)setPageSizeFromPopup
{
    if(paperSizePopup){
	NSSize sz = [self paperSizeForTag:[paperSizePopup tagOfTitle]];

	[self	setPageSize:sz];
    }
}


- (NSRect)rectForPage:(int)page
{
    /* set theRect for what it should be, but return depending on if this is
     * a valid page number or not.
     */
    NSSize pageSize = [self pageSize];
    return NSMakeRect(0.0, pageSize.height * (page-1),
		      pageSize.width, pageSize.height);
}

- (BOOL)knowsPageRange:(NSRangePointer)range
{
    range->location = 1;
    range->length   = [self pages];
    return YES;
}


- (unsigned int)pages
{
    NSSize pageSize = [self pageSize];
    return [self bounds].size.height / pageSize.height;
}

- (void)setNumPages:(unsigned int)pages
{
    NSSize pageSize = [self pageSize];
    [self setFrameSize:NSMakeSize(pageSize.width,pageSize.height * pages)];
}

- (void)displayPaperSize
{
    NSSize pageSize = [self pageSize];
    int unitsTag = [unitsPopup tagOfTitle];
    [paperSizeField setStringValue:
			[NSString stringWithFormat:@"%@ x %@",
				  [[self class] convertPointsToUnits:pageSize.width  tag:unitsTag],
				  [[self class] convertPointsToUnits:pageSize.height tag:unitsTag]]
    ];
}


- (NSSize)pageSize
{
    return pageSize_;
}

- (void)setPageSize:(NSSize)aSize
{
    pageSize_ = aSize;
    if(paperSizeField){
	[self displayPaperSize];
    }
    [printInfo setPaperSize:aSize];
}

- (void)takeSizeFromPrintInfo:(NSPrintInfo *)pi
{
    [self setPageSize:[pi paperSize]];
    [paperNameField setStringValue:[pi localizedPaperName]];
}


- (IBAction)changedPaperSize:sender
{
    [self setPageSizeFromPopup];
}



- (IBAction)pageSetup:sender
{
    NSPageLayout *pl = [NSPageLayout pageLayout];

    [pl runModalWithPrintInfo:printInfo];
    [self takeSizeFromPrintInfo:printInfo];
}

- (IBAction)changedUnits:sender
{
    int newTag = [self unitsTag];
    double m1 = [self unitMultiplierForTag:oldUnitsTag];
    double m2 = [self unitMultiplierForTag:newTag];
    NSEnumerator *en = [autoConvertArray objectEnumerator];
    id obj;
    
    [self displayPaperSize];
    
    while(obj = [en nextObject]){
	[obj setDoubleValue:[obj doubleValue] * m1 / m2];
    }

    oldUnitsTag = [unitsPopup tagOfTitle];
}

@end
