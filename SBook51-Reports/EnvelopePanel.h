/* EnvelopePanel
 * The main thing this panel does is manage the two views -- label view and envelope view ---
 * and handle the return-address stationery.
 */

#import <Cocoa/Cocoa.h>
#import "SBookModalPanel.h"
#import "SBookController.h"

@class EView,LabelView,ZoomScrollView,Person;
@interface EnvelopePanel : SBookModalPanel2
{
    IBOutlet NSTabView		*tabView;
    IBOutlet NSTabViewItem	*envelopeTab;
    IBOutlet NSTabViewItem	*labelTab;
    IBOutlet EView		*eview;
    IBOutlet LabelView		*labelView;

    IBOutlet NSTextView		*addrText;
    IBOutlet NSTextView		*retAddrText;

    IBOutlet NSPopUpButton	*stationeryPopup;

    IBOutlet NSButton		*newStationeryOkayButton;
    IBOutlet NSWindow		*newStationeryNamePanel;
    IBOutlet NSTextField	*newStationeryNameField;
    IBOutlet NSTextField	*newStationeryStatusField;

    IBOutlet ZoomScrollView	*envelopeZoomScrollView;
    IBOutlet ZoomScrollView	*labelsZoomScrollView;

    IBOutlet NSButton		*includeReturnAddressButton;
    IBOutlet NSButton		*includeDestinationAddressButton;

    /* These are used for the pop-up */
    id		spacerCell;
    id		deleteCell;
    id		newCell;

    NSString	*lastStationeryTitle;

    NSData	*defaultStationery;
    NSWindow	*parentWindow;

    Person	*person;
    IBOutlet NSButton		*printLastnameFirstname;
}

+ (EnvelopePanel *)sharedEnvelopePanel;

/* Address setting */
- (void)setPerson:(Person *)aPerson;
- (void)setAddress:(NSString *)addr;

/* Labels */
- (IBAction)createLabels:sender;


/* Stationery */

- (void)setStationeryStore:(NSDictionary *)dict;
- (NSMutableDictionary *)stationeryStore;
- (NSString *)defStationery;
- (int)stationeryCount;
- (void)setDefaultStationery:(NSString *)val;
- (void)saveStationery;
- (void)loadStationery;

- (void)setStationeryPopupTitle;
- (IBAction)delete:(id)sender;
- (IBAction)newStationery:(id)sender;
- (IBAction)chooseStationery:(id)sender;
- (IBAction)cancelNewStationery:(id)sender;
- (IBAction)okNewStationery:(id)sender;
- (IBAction)changedUnits:(id)sender;

- (void)runWithWindow:(NSWindow *)aWindow;
- (IBAction)changeLastnameFirstname:sender;

@end

/* Envelope Panel */
#define DEF_ENVELOPE_PANEL_TAG_VIEW	@"EnvelopePanelTagView"
#define DEF_RETURN_ADDRESS		@"ReturnAddress"
#define DEF_LOG_ENVELOPES		@"LogEnvelopes"

/* Printing labels */
#define ENV_ICON_PRINTS_LABELS		@"EnvelopeIconPrintsLabels"
#define ENV_ICON_PRINTS_RETURN_ADDRESS	@"EnvelopeIconPrintsReturnAddress"
#define ENV_ICON_RETURN_ADDRESS		@"EnvelopeIconReturnAddress"

