/*
 * AbstractReportPanel:
 * (C) Copyright 2002 by Simson L. Garfinkel.
 *
 * The reportPanel creates the report elements that are then displayed by the AbstractReportView.
 */

#import <Cocoa/Cocoa.h>
#import "SBookModalPanel.h"

@class ZoomScrollView,SLC,FontWell,Person,AbstractReportView;
@class AbstractReportElement;
@interface AbstractReportPanel: SBookModalPanel2
{
    IBOutlet	ZoomScrollView	   *zoomScrollView;
    IBOutlet	AbstractReportView *preview;

    NSString	*currentEntryLabel;

    /* List stuff */
    NSMutableArray	*personList;		/* all people from which elements are built */
    
    /* Selection GUI */
    IBOutlet NSButtonCell *showEntireEntrySwitch;
    IBOutlet NSButtonCell *showNamesSwitch;
    IBOutlet NSButtonCell *showAddressesSwitch;
    IBOutlet NSButtonCell *showPhonesSwitch;
    IBOutlet NSButtonCell *showEmailsSwitch;
    IBOutlet NSButtonCell *showURLsSwitch;
    IBOutlet NSButtonCell *displayLastnameFirstnameSwitch;

    BOOL		justNames;	// add elements of just names
    
    IBOutlet NSButtonCell *includeWoAddress;
    IBOutlet NSButtonCell *includeWoPhone;
    IBOutlet NSButtonCell *includeWoEmail;
    IBOutlet NSButtonCell *includeWoURL;

    IBOutlet NSProgressIndicator *selectionProgress;

    SLC	*slc;
    BOOL	firstTimeThrough;
}

/* Behavior methods --- these must be subclassed */
- (AbstractReportElement *)newElementForPerson:(Person *)aPerson;	// new, autoreleased, element
- (BOOL)showEntryLabels;		// do we show "phone:" label itself

/* Accessors */
- (ZoomScrollView *)zoomScrollView;
- (SLC *)slc;
- (void)setSLC:(SLC *)slc;
- (int)dpf;				// don't parse flag, from slc
- (NSProgressIndicator *)selectionProgress;

/* Report-making methods */
- (BOOL)showType:(int)type;		// should we show this LIBSBOOK type ?
- (void)prepareForReport;
- (BOOL)shouldStartNewEntry:(int)tag lastTag:(int)lastTag;
- (void)processPerson:(Person *)person;	// called for each
- (void)generateReportForPeople:(NSArray *)peopleArray;
- (BOOL)displayLastnameFirst;

/* GUI methods */
- (IBAction)reportFinished:sender;
- (IBAction)print:sender;
- (IBAction)changedSelectionCriteria:sender;	/* reads from cells and resort */


@end

	
