#import <Cocoa/Cocoa.h>


@class SList;
@class SLC;


@interface Syncher:NSObject
{
    SLC		*slc;
    SList	*doc;			// slist we are syncing from
    IBOutlet	NSMatrix *syncActionMatrix;
    IBOutlet	NSProgressIndicator *ab_to_sbook;
    IBOutlet    NSProgressIndicator *sbook_to_abook;
    IBOutlet    NSProgressIndicator *sbook_cleaner;
    IBOutlet    NSProgressIndicator *abook_cleaner;
    IBOutlet	NSFormCell *abRecordsCopied;
    IBOutlet	NSFormCell *abRecordsSkipped;
    IBOutlet	NSFormCell *sbookRecordsCopied;
    IBOutlet	NSFormCell *sbookRecordsSkipped;
    IBOutlet	NSPanel		*syncSetupPanel;
    IBOutlet	NSPanel		*syncStatusPanel;
    IBOutlet	id	totalSBookRecords;
    IBOutlet	id	totalABRecords;
    IBOutlet	id	cancel2Button;
    IBOutlet    id      okay2Button;
    IBOutlet	NSFormCell *sbookRecordsRemoved;
    IBOutlet	NSFormCell *abRecordsRemoved;
    BOOL	userQuit;

    /* State information */
    NSMutableArray	*justCopied;		// those we just synched

    /* For changing an ABPerson into a Person */
    NSString	*note;			// current note being converted

    /* Did we force? */
    int		forceTag;
    
}

/* These must be subclassed */
- (int)syncSourceCount;
- (void)syncSourceToSBook;
- (void)syncSBookToSource:(int)fastFlag; // run the GUI if flastFlag is not set

- (BOOL)personModifiedAfterSync:aPerson;
- (IBAction)cancel1:sender;
- (IBAction)cancel2:sender;
- (IBAction)sync:sender;
- (IBAction)okay:sender;
- (NSPanel *)syncSetupPanel;


- (void)setSLC:(SLC *)slc;
- (void)runWithSLC:(SLC *)slc flag:(int)tag;
- (void)checkForQuit;

@end

#define TAG_SYNC_AB_TO_SBOOK			1
#define TAG_SYNC_SBOOK_TO_AB			2
#define TAG_SYNC_AB_SBOOK			3
//#define TAG_REMOVE_ABOOK_ENTRIES_IN_SBOOK	4
//#define TAG_REMOVE_SBOOK_ENTRIES_IN_ABOOK	5
#define TAG_IMPORT_ABOOK_TO_SBOOK		6
#define TAG_EXPORT_SBOOK_TO_ABOOK		7
