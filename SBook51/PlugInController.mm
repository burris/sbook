#import "PlugInController.h"
#import "SBookController.h"
#import "tools.h"

@implementation PlugInController


- (id)init
{
    [super init];
    return self;
}

- (NSPanel <PreferencePanelProtocol> *)preferencePanel
{ 
    if(!preferencePanel){
	[NSBundle loadNibNamed:@"PreferencePanel" owner:self ];
	if(!preferencePanel){
	    NSRunAlertPanel(@"SBook",@"Could not PreferencePanel nib!",nil,nil,nil);
	}
    }
    return preferencePanel;
}

- (NSPanel <PreferencePanelProtocol> *)preferencePanelNoLoad
{
    return preferencePanel;
}

- (void)showPreferencePanel:sender
{
    [[self preferencePanel] makeKeyAndOrderFront:self];
}



- (void)loadPlugInBundle:(NSString *)fileName
{
    NSAutoreleasePool *myPool = [[NSAutoreleasePool alloc] init]; // create an autorelease pool
    NSBundle *bundle = [NSBundle bundleWithPath:fileName];

    if([bundle load]==NO){
	NSRunAlertPanel(@"Plugin failure",
			@"Could not load plugin %@",nil,nil,nil,fileName);
	return;
    }

    NSArray *a2 = [fileName componentsSeparatedByString:@"/"];
    NSMutableString *bundleName = [[[a2 objectAtIndex:[a2 count]-1] mutableCopy] autorelease];
    [bundleName replaceString:@".bundle" withString:@"" global:NO];
    NSMutableString *className = [[bundleName mutableCopy] autorelease];
    [className appendString:@"Class"];

    NSLog(@"PlugIn %@ Loaded",bundleName);
   
    id cl	= [bundle classNamed:className];
    id instance = [[cl alloc] init];

    /* If there is a matching nib, load it... */
    [NSBundle loadNibNamed:bundleName owner:instance];

    /* Now tell the instance to start */
    [instance startup:self];
    [myPool release];			// release the pool
}

- (void)scanDirectoryForPlugins:(NSString *)dir
{
    NSArray *array = nil;
    NSEnumerator *en;
    NSString *bundlePath;

    array = [NSBundle pathsForResourcesOfType:@"bundle" inDirectory:dir];
    en = [array objectEnumerator];
    while(bundlePath = [en nextObject]){
	[self loadPlugInBundle:bundlePath];
    }
}

/****************************************************************
 *** Plug-in Menu management
 ****************************************************************/


- (BOOL)validateMenuItem:(id <NSMenuItem>)item
{
    SEL action = [item action];
    if(action == @selector(showPreferencePanel:)){
	return YES;
    }
    return NO;
}

- (NSMenuItem *)addActionToMenu:(NSMenu *)aMenu
			  title:(NSString *)title
			 action:(SEL)aSelector
			 target:(id)target
{
    NSMenuItem *item= [[NSMenuItem alloc] initWithTitle:title
				     action:aSelector
				     keyEquivalent:@""];

    [item setTarget:target];
    [aMenu addItem:item];
    return item;
}

- (NSMenu *)menu:(NSString *)aTitle fromMenu:(NSMenu *)aMenu
{
    // if title is split, look for submenu and call recursively */
    if(aMenu==nil) return nil;
    NSRange r = [aTitle rangeOfString:@"/"];
    if(r.length==1){
	NSString *rightPart = [aTitle substringFromIndex:r.location+1];
	NSString *leftPart    = [aTitle substringToIndex:r.location];
	NSMenuItem *subitem = [aMenu itemWithTitle:leftPart];
	return [self menu:rightPart fromMenu:[subitem target]];
    }
    return [[aMenu itemWithTitle:aTitle] target];
}

-(NSMenu *)menu:(NSString *)aTitle
{
    return [self menu:aTitle fromMenu:[NSApp mainMenu]];
}    


- (void)installPreference:(NSString *)title view:(NSView *)aView
{
    [[self preferencePanel] installPreference:title view:aView];
}


@end
