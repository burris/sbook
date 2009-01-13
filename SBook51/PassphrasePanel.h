/* PassphrasePanel */

#import <Cocoa/Cocoa.h>
#import "SBookModalPanel.h"

@interface PassphrasePanel: SBookModalPanel
{
    IBOutlet id phrase1;
    IBOutlet id phrase2;
    IBOutlet id showTyping;
    IBOutlet id okayButton;
}

- (NSData *)key;

@end
