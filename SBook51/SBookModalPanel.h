#import <Cocoa/Cocoa.h>

@interface SBookModalPanel : NSPanel
{
    IBOutlet id okButton;
    BOOL	runningAsSheet;
    BOOL	sendSelectorAfterOrderOut;
}
- (IBAction)cancel:(id)sender;
- (IBAction)proceed:(id)sender;
- (int)run;
- (void)setSendSelectorAfterOrderOut:(BOOL)aFlag;
- (void)runAsSheet:(NSWindow *)baseWindow modalDelegate:(id)modalDelegate
    didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo;

/* Selector should be nil or have signature:
 * - (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
 * sheetDidEnd:returnCode:contextInfo:
 *
 * returnCode==1 if proceed:, 0 if cancel
 */

@end
