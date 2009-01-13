/* ImportingTabAlertPanel */

#import <Cocoa/Cocoa.h>

@interface ImportingTabAlertPanel : NSPanel
{
    IBOutlet id ignoreFirstLineSwitch;
    IBOutlet id swapNamesSwitch;
}
- (int)run;
- (IBAction)cancel:(id)sender;
- (IBAction)proceed:(id)sender;
- (BOOL)ignoreFirstLine;
- (BOOL)swapNames;
@end
