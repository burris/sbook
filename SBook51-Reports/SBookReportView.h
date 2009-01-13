/* SBookReportView */

#import <Cocoa/Cocoa.h>
#import "AbstractReportView.h"

@interface SBookReportView : AbstractReportView
{
    /* Fonts */
    IBOutlet FontWell	*fontWell0;
    IBOutlet FontWell	*fontWell1;
    IBOutlet FontWell	*fontWell2;
}

/* Font stuff */
- (void)deactivateFontWells;
- (NSFont *)font:(int)num;		// font from font num
- (void)setFont:(int)num to:(NSFont *)aFont;
- (NSDictionary *)fontAttributes:(int)num; // font attributes for font num

@end
