#import "SBookReportView.h"

@implementation SBookReportView

- (void)awakeFromNib
{
    NSFont *ft = [NSFont userFontOfSize:[NSFont smallSystemFontSize]];

    [fontWell0 setDisplayFont:ft];
    [fontWell1 setDisplayFont:ft];
    [fontWell2 setDisplayFont:ft];

    [super awakeFromNib];
}

- (void)deactivateFontWells;
{
    [fontWell0	setActive:NO];
    [fontWell1	setActive:NO];
    [fontWell2	setActive:NO];
}


-(void)prepareForReport
{
    [self	deactivateFontWells];
    [super      prepareForReport];
}

- (NSFont *)font:(int)num
{
    switch(num){
    case 0:
	return [fontWell0 font];
    case 1:
	return [fontWell1 font];
    case 2:
	return [fontWell2 font];
    }
    NSLog(@"%@: num=%d",self,num);
    NSAssert(0,@"num is out of range");
    return nil;
}

- (void)setFont:(int)num to:(NSFont *)aFont
{
    switch(num){
    case 0:
	[fontWell0 setFont:aFont];
	return;
    case 1:
	[fontWell1 setFont:aFont];
	return;
    case 2:
	[fontWell2 setFont:aFont];
	return;
    }
    NSLog(@"%@: num=%d",self,num);
    NSAssert(0,@"num is out of range");
}


- (NSDictionary *)fontAttributes:(int)num
{
    switch(num){
    case 0:
	return [fontWell0 fontAttributes];
    case 1:
	return [fontWell1 fontAttributes];
    case 2:
	return [fontWell2 fontAttributes];
    }
    NSLog(@"%@: num=%d",self,num);
    NSAssert(0,@"num is out of range");
    return nil;
}


@end
