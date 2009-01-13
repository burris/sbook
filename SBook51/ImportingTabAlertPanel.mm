#import "ImportingTabAlertPanel.h"

@implementation ImportingTabAlertPanel

- (IBAction)cancel:(id)sender
{
    [NSApp stopModalWithCode:NO];
}

- (IBAction)proceed:(id)sender
{
    [NSApp stopModalWithCode:YES];
}

-(int)run
{
    int ret;

    [self center];
    [self makeKeyAndOrderFront:self];
    ret = [NSApp runModalForWindow:self];
    [self orderOut:self];
    return ret;
}

- (BOOL)ignoreFirstLine
{
    return [ignoreFirstLineSwitch intValue];
}

- (BOOL)swapNames
{
    return [swapNamesSwitch intValue];
}

@end
