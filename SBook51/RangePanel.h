/* RangePanel */

#import "SBookModalPanel.h"

@class SLC;
@interface RangePanel : SBookModalPanel
{
    IBOutlet id numberSelectedField;
    IBOutlet id rangeTitle;
    IBOutlet id selectionMatrix;
    IBOutlet id timeRangeSwitch;	// do we use the selectedTimeRange?

    /* Time range */
    IBOutlet NSPopUpButton *whichPopup;
    IBOutlet NSPopUpButton *beforeOnAfterPopup;

    IBOutlet NSTextField *dateField;
    IBOutlet NSPopUpButton *monthPopup;
    IBOutlet NSPopUpButton *yearPopup;

    IBOutlet id todayButton;
    SLC		*slc;
    SEL		endSelector;
    id		endTarget;
    NSArray *selected;

    NSString *allEntries;
    NSString *allEntriesDisplayed;
    NSString *allEntriesSelected;
}

#define CREATED_TAG 10
#define MODIFIED_TAG 11
#define VIEWED_TAG 12

#define BEFORE_TAG -1
#define ON_TAG 0
#define AFTER_TAG 1

/* will call Returns NSArray of selected peopel to aSelector
 */
- (void)runAsSheet:(NSWindow *)baseWindow title:(NSString *)aTitle slc:(SLC *)slc
endTarget:aTarget didEndSelector:(SEL)aSelector;
- (IBAction)setToday:sender;
- (IBAction)rangeSelectionChanged:sender;
- (NSArray *)selected;


@end

