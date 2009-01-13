#import "OpenOnLaunchBrowser.h"
#import "SBookController.h"
#import "defines.h"

@implementation OpenOnLaunchBrowser

-(void)awakeFromNib
{
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,0]];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pb = [sender draggingPasteboard];
    NSArray *filenames = [pb propertyListForType:NSFilenamesPboardType];
    NSEnumerator *en = [filenames objectEnumerator];
    id obj;

    while(obj = [en nextObject]){
	[AppDelegate setOpenFileOnStartup:obj toValue:YES];
    }
    return YES;
}

-(void)add:(id)sender
{
    [[NSOpenPanel openPanel]
	beginSheetForDirectory:nil
	file:nil
	types:[NSArray arrayWithObjects:SBOOK_FILE_EXTENSION,nil]
	modalForWindow:[self window]
	modalDelegate:self
	didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
	contextInfo:nil];
    [self reloadColumn:0];
}

-(void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    NSEnumerator *en = [[sheet filenames] objectEnumerator];
    id obj;

    NSLog(@"code=%d",returnCode);
    if(returnCode){
	while(obj = [en nextObject]){
	    [AppDelegate setOpenFileOnStartup:obj toValue:YES];
	}
    }
}

- (void)delete:(id)sender
{
    NSArray *sel = [self selectedCells];
    NSEnumerator *en = [sel objectEnumerator];
    id cell;

    while(cell = [en nextObject]){
	[AppDelegate setOpenFileOnStartup:[cell stringValue] toValue:NO];
    }
    [self reloadColumn:0];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)item
{
    if([item action] == @selector(delete:)){
	if([self selectedCell]) return YES;
    }
    return [super validateMenuItem:item];
}



@end
