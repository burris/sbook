/* DialerPanel */

#import "SBookModalPanel.h"

@interface DialerPanel : SBookModalPanel
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

+(DialerPanel *)sharedPanel; 
-(BOOL)openModemForWindow:(NSWindow *)aWindow andOrderOut:(BOOL)orderOutFlag;
-(void)toggleDTR:(int)msec;
-(void)toggleDTR;
-(void)modemSend:(NSString *)str addCR:(BOOL)flag;
-(BOOL)modemInUse;
-(void)releaseModem;
-(void)setDialingTitle:(NSString *)str;
-(void)dialString:(NSString *)str  forWindow:aWindow;
-(void)dial:(NSString *)str withRules:(BOOL)flag forWindow:(NSWindow *)window;



@end
