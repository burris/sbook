/*
 * History.h:
 */

#import <Cocoa/Cocoa.h>


@class SLC;
@interface HistoryView : NSObject
{
    NSString *searchString;		// what was searched for
    NSArray  *selectedPeople;		// who was selected; if just one, than that is displayed
    NSMutableArray *addedPeople;	// people added when the "back" button was pushed.
}
- initForSLC:(SLC *)slc;		// create a view for a given SLC
- (NSString *)searchString;
- (NSArray *)selectedPeople;
@end

@interface History : NSObject
{
    SLC *slc;				// our controlling SLC
    NSMutableArray *views;		// things that we searched for
    unsigned int ptr;				// current location in history array
}
- initForSLC:(SLC *)aSLC;
- (void)save;				// save the current view; erases anything forward of ptr
- (BOOL)hasForward;			// can we move forward?
- (BOOL)hasBack;			// can we move backward?
- (IBAction)forward:sender;				// advance forward
- (IBAction)back:sender;					// go back

@end
