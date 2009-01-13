#import <Cocoa/Cocoa.h>

/* ViewWithUnits implements a simple paginated view
 * with a units pop-up.
 */

@interface ViewWithUnits:NSView
{
    IBOutlet NSPopUpButton *paperSizePopup;
    IBOutlet NSPopUpButton *unitsPopup;	// can have multiple connections; uses notifications
    IBOutlet NSTextField   *paperSizeField;
    IBOutlet NSTextField   *paperNameField;
    NSSize	pageSize_;		// in points
    int		oldUnitsTag;
    NSMutableArray *autoConvertArray;
    NSPrintInfo    *printInfo;
}
+ (NSString *)convertPointsToUnits:(double)value tag:(int)tag;
- (void)takeSizeFromPrintInfo:(NSPrintInfo *)pi;
- (void)addAutoconverter:obj;
- (NSSize)paperSizeForTag:(int)tag;	
- (int)unitsTag;
- (void)setPageSizeFromPopup;
- (double)convertToPoints:(double)value;
- (double)convertFromPoints:(double)value;
- (void)displayPaperSize;

- (IBAction)changedPaperSize:sender;
- (IBAction)changedUnits:sender;
- (IBAction)pageSetup:sender;		// let the user change size with conventional GUI


- (void)setPageSize:(NSSize)aSize;
- (NSSize)pageSize;
- (NSRect)rectForPage:(int)page;
- (unsigned int)pages;				// based on current height
- (void)setNumPages:(unsigned int)pages;	// set this many pages

@end

#define P_BUT_NAME	0		// special tag
#define TAG_INCHES	1
#define TAG_CM		2
#define TAG_MM		3
#define TAG_POINTS	4
#define TAG_PICAS	5

#define TAG_PAPER_US_LETTER	1
#define TAG_PAPER_A4		2

@interface NSPopUpButton(mpv)
- (int)tagOfTitle;
- (void)selectItemWithTag:(int)tag;
@end

