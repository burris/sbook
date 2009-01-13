/* DialerPanel */

#import "SBookModalPanel.h"
#import <SBookController.h>

@interface DialerPanel : SBookModalPanel3 <SBookDialer>
{
    int portfd;				// file descriptor for modem
    NSTimer  *releaseTimer;		// when modem should be released
    NSMutableString *fromModem;		// data sent from the modem
    NSFileHandle *fileHandle;
    IBOutlet NSTextField *dialingField;
    IBOutlet NSTextField *dialedNumber;
    IBOutlet NSTextField *modemSend;
    IBOutlet NSTextField *dialingTitleField;
    NSString *dialingTitle;
    NSString *modemSendFormat;
    NSTimer  *retreatTimer;

}

+(DialerPanel *)sharedDialerPanel; 
-(BOOL)openModemForWindow:(NSWindow *)aWindow andOrderOut:(BOOL)orderOutFlag;
-(void)toggleDTR:(int)msec;
-(void)toggleDTR;
-(void)modemSend:(NSString *)str addCR:(BOOL)flag;
-(BOOL)modemInUse;
-(void)releaseModem;
-(void)setDialingTitle:(NSString *)str;
-(void)dial:(NSString *)str forWindow:aWindow;

- (IBAction)releaseModem:sender;
@end
