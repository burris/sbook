/*
 * (C) Copyright Simson L. Garfinkel
 *
 * PluginController.h:
 *
 * Provides a framework for doing bundle plug-ins in Cocoa programs.
 */

#import <Cocoa/Cocoa.h>

@class PlugInController;

@protocol PreferencePanelProtocol
- (void)installPreference:(NSString *)title view:(NSView *)aView;
- (void)reloadFromDefaults;
@end

@protocol PlugInOwner
- (BOOL)validateMenuItem:(id <NSMenuItem>)item;	// these get chained to the owner
@end

@protocol PlugIn
- (void)startup:(PlugInController *)owner;			// called when loaded
@end

@interface PlugInController : NSObject
{
    NSPanel <PreferencePanelProtocol> *preferencePanel;
    NSMutableDictionary *enableRules;
}
- (NSPanel <PreferencePanelProtocol> *)preferencePanel;
- (NSPanel <PreferencePanelProtocol> *)preferencePanelNoLoad;

- (void)loadPlugInBundle:(NSString *)path; // loads a PlugInBundle 
- (void)scanDirectoryForPlugins:(NSString *)dir;	// and load the ones you find
- (void)installPreference:(NSString *)title view:(NSView *)aView;
- (void)showPreferencePanel:sender;


- (NSMenuItem *)addActionToMenu:(NSMenu *)aMenu
			  title:(NSString *)aString
			 action:(SEL)aSelector
			 target:(id)target ;

- (NSMenu *)menu:(NSString *)title;

- (BOOL)validateMenuItem:(id <NSMenuItem>)item;
//- (void)addEntryItem:(NSMenuItem *)item;
@end

