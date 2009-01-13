#import <Cocoa/Cocoa.h>
#import "ProgressPanel.h"

#include <sys/time.h>

@implementation ProgressPanel

- (void)setBigMessage:(NSString *)message
{
    //NSAssert(bigMessage,@"bigMessage==0?");
    [bigField setStringValue:message];
}


- (void)setSmallMessage:(NSString *)message
{
    //NSAssert(smallMessage,@"smallMessage==0?");
    [smallField setStringValue:message];
}

- (IBAction)cancel:(id)sender
{
    canceled = YES;
}

- (void)runWithWindow:(NSWindow *)aWindow
{
    //[NSApp beginSheet:self modalForWindow:aWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
    canceled = NO;
    [self center];
    [self makeKeyAndOrderFront:nil];
}

- (void)runDone
{
    //[NSApp stopModal];			// stop the modal session
    [self orderOut:nil];
}

- (BOOL)checkForCancel
{
    NSEvent *event = [NSApp nextEventMatchingMask:NSLeftMouseDownMask|NSLeftMouseUpMask
			    untilDate:[NSDate distantPast]
			    inMode:NSModalPanelRunLoopMode
			    dequeue:YES];
    if(event){
	[NSApp sendEvent:event];
    }
    return canceled;
}

- (void)setMinValue:(double)min
{
    [progressIndicator setMinValue:min];
}

- (void)setMaxValue:(double)max
{
    [progressIndicator setMaxValue:max];
}

- (void)setDoubleValue:(double)val
{
    [progressIndicator setDoubleValue:val];
}

- (void)setIndeterminate:(BOOL)val
{
    [progressIndicator setIndeterminate:val];
}


@end
