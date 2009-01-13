/* EView
 * The envelope view  
 */

#import <Cocoa/Cocoa.h>
#import "ViewWithUnits.h"

@class FontWell;
@interface EView : ViewWithUnits
{
    IBOutlet NSTextView		*addrText;
    IBOutlet NSTextView		*retAddrText;
    NSString			*addrZip;	

    IBOutlet NSButton		*printBarcode;

    IBOutlet NSButton		*printFIM;
    IBOutlet NSButton		*printOutlines;
    IBOutlet NSButton		*printReturnAddress;

    IBOutlet FontWell		*retAddrFontWell;
    IBOutlet FontWell		*addrFontWell;

    NSRect fromRect,toRect;
    NSBezierPath *postnet;

    NSMutableDictionary *popupDictionary;
    NSTextView			*drawText;
}

- (void)drawText:(NSString *)str inRect:(NSRect)rect withFont:(NSFont *)aFont;
- (void)printWithWindow:(NSWindow *)windowToAttachSheet;
- (void)createPOSTNET;
- (void)drawFIM;
- (void)textDidChange:(NSNotification *)notification;
- (IBAction)redisplay:sender;

@end

