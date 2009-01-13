/*
 * AbastractReportView:
 * The report view creates the elements to display and
 * keeps track of them.
 */


#import <Cocoa/Cocoa.h>
#import "ViewWithUnits.h"

@class AbstractReportElement,FontWell;
@class ElementEnumerator;
@interface AbstractReportView:ViewWithUnits
{
    IBOutlet NSTextField *numEntriesCell;
    IBOutlet NSTextField *numPagesCell;

    IBOutlet NSProgressIndicator *layoutProgress;

    /* Attributed texts derrived from Fonts when createAttributes is called */
    NSMutableDictionary *attributes0;
    NSMutableDictionary *attributes1;
    NSMutableDictionary *attributes2;

    /* Page Layout */
    IBOutlet NSFormCell	*leftPageMarginCell;
    IBOutlet NSFormCell	*rightPageMarginCell;
    IBOutlet NSFormCell	*topPageMarginCell;
    IBOutlet NSFormCell	*bottomPageMarginCell;
    
    IBOutlet id presetFormatPopup;

    NSMutableArray	*elementList; // just the report elements
    NSMutableArray	*displayList;	// all of the elements
    IBOutlet FontWell   *fontWell0;
    IBOutlet FontWell   *fontWell1;
    IBOutlet FontWell   *fontWell2;
}

- (void)insertPageNumber:(int)pn;
- (void)insertPageNumbers;
- (NSFont *)font:(int)num;

/* margins */
- (float)leftPageMargin;
- (float)rightPageMargin;
- (float)topPageMargin;
- (float)bottomPageMargin;
- (void)setLeftMargin:(float)l rightMargin:(float)r topMargin:(float)t bottomMargin:(float)b;

/* Layout */
- (void)prepareForReport;		// first time through
- (IBAction)changedLayoutInformation:sender; // font changed, etc.; need to relayout elements
- (void)setLayoutProgress:(double)value;
- (NSProgressIndicator *)layoutProgress;
- (NSMutableArray *)displayList;


/* Managing the report element list */
- (int)numReportElements;
- (void)clearDisplayList;
- (void)clearElementList;
- (void)addReportElement:(AbstractReportElement *)element;
- (void)drawRect:(NSRect) rect withOffset:(NSPoint)pt;
- elementEnumerator;
@end




