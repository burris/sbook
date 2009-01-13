#import "SBookModalPanel.h"

@implementation SBookModalPanel2

- (void)setSendSelectorAfterOrderOut:(BOOL)aFlag
{
    sendSelectorAfterOrderOut = aFlag;
}

- (IBAction)cancel:(id)sender
{
    if([self isSheet] || runningAsSheet){
	[NSApp endSheet:self returnCode:NO];
	[self orderOut:self];
	return;
    }
    [NSApp stopModalWithCode:NO];
}

- (IBAction)proceed:(id)sender
{
    if([self isSheet] || runningAsSheet){
	if(sendSelectorAfterOrderOut==NO) [NSApp endSheet:self returnCode:YES];
	[self orderOut:self];
	if(sendSelectorAfterOrderOut==YES) [NSApp endSheet:self returnCode:YES];
	return;
    }
    [NSApp stopModalWithCode:YES];
}

-(int)run
{
    int ret;

    runningAsSheet = NO;
    [self center];
    [self makeKeyAndOrderFront:self];
    [self center];
    ret = [NSApp runModalForWindow:self];
    [self orderOut:self];
    return ret;
}

- (void)runAsSheet:(NSWindow *)baseWindow modalDelegate:(id)modalDelegate
    didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo
{
    runningAsSheet = YES;
    [NSApp beginSheet:self modalForWindow:baseWindow modalDelegate:modalDelegate
	   didEndSelector:didEndSelector contextInfo:contextInfo];

    if(baseWindow==nil){
	[NSApp activateIgnoringOtherApps:YES];
	[self performSelector:@selector(makeKeyAndOrderFront:)
	      withObject: nil
	      afterDelay:0.1];
	      
    }
}


@end
