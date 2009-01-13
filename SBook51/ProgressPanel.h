/* ProgressPanel */

#import <Cocoa/Cocoa.h>
#import "SBookModalPanel.h"

@interface ProgressPanel : SBookModalPanel
{
    IBOutlet NSTextField *bigField;
    IBOutlet NSTextField *smallField;
    IBOutlet NSProgressIndicator *progressIndicator;
    BOOL canceled;
}
- (void)runWithWindow:(NSWindow *)aWindow;
- (BOOL)checkForCancel;
- (IBAction)cancel:(id)sender;
- (void)runDone;
- (void)setMinValue:(double)min;
- (void)setMaxValue:(double)max;
- (void)setDoubleValue:(double)val;	// and does a display if it has been more than 100 msec since last set
- (void)setIndeterminate:(BOOL)val;
- (void)setBigMessage:(NSString *)message;
- (void)setSmallMessage:(NSString *)smallMessage;

@end
