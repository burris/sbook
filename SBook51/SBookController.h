/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law.
 *
 */

#import "PlugInController.h"

@class PassphrasePanel;
@class Person,SList,SLC;
@class ReportBundleClass;

/* Protocol for the dialer */
@protocol SBookDialer
- (void)dial:(NSString *)str  forWindow:aWindow;
@end
@protocol SBookLocalizedDialer
- (void)dial:(NSString *)number withLocalRules:(BOOL)useRules forWindow:(NSWindow *)aWindow;
@end
@protocol ReportClassInstance
-(void)printEnvelope:(Person *)aPerson address:(NSString *)aString forWindow:(NSWindow *)aWindow;
@end



@interface SBookController:PlugInController <NSURLHandleClient>
{
    /* Nibs that can load */
    IBOutlet id    infoPanel;
    IBOutlet id    infoVersionCell;
    IBOutlet id	   openURLField;
    IBOutlet id    emailer;
    IBOutlet id    bulkEmailer;
    IBOutlet id    mailingLabels;
    IBOutlet id    inspector;
    IBOutlet id    newLogger;
    IBOutlet id    slistController;
    IBOutlet id    importingTabAlertPanel;
    IBOutlet id    passphraseCreatePanel;
    IBOutlet id    passphraseEnterPanel;

    /* Panels that are loaded for plug-ins */

    IBOutlet id <SBookDialer>		dialerPanel;
    IBOutlet id <SBookLocalizedDialer>	localizedDialer;
    id <ReportClassInstance,NSObject>	reportBundleClassInstance;

    /* Other stuff */
    IBOutlet NSMenu	*specialMenu;

    NSURL	*newVersionURL;
    NSURLHandle *newVersionURLHandle;
    NSString    *newVersionAvailable;
    time_t	build;			// my build time
    BOOL	debug_menu_added;
}

/* These return IDs of controllers of things loaded from nibs */
- infoPanel;
- inspector;
- mailingLabels;
- importingTabAlertPanel;
- passphraseCreatePanel;
- passphraseEnterPanel;
- (void)showInspector:sender;
- (void)showLicense:sender;
- (void)import:sender;
- (void)openURL:(id)sender;
- (void)openURL_Okay:(id)sender;
- (void)openURL_Cancel:(id)sender;
- (void)setStatus:(NSString *)aStatus;

/* Autolaunch */
- (BOOL)willOpenFileOnStartup:(NSString *)filename;
- (void)setOpenFileOnStartup:(NSString *)filename toValue:(BOOL)shouldOpen;

/* Special Menu */
- (BOOL)fileInSpecialMenu:(NSString *)filename;
- (void)setFileInSpecialMenu:(NSString *)filename toValue:(BOOL)showShow;
- (void)refreshSpecialMenu;

- (void)bugsAndSuggestions:sender;
- (NSString *)newVersionAvailable;	// returns version number of new version, if it is available
- (IBAction)newInThisRelease:sender;
- (IBAction)knownBugsInThisRelease:sender;
- (NSString *)appVersion;

- (void)removeEmptyWindow;		// remove an empty window if we find it

/* required plug-in support */
-(id <SBookDialer>)dialerPanel;
-(id <SBookLocalizedDialer>)localizedDialer;
-(void)setDialerPanel:(id <SBookDialer,NSObject> )aDialer;
-(void)setLocalizedDialer:(id <SBookLocalizedDialer, NSObject>)aLocalizedDialer;
-(void)setReportBundleClassInstance:(id <ReportClassInstance>) anInstance;
-(id <ReportClassInstance>)reportBundleClassInstance;

@end


/* Helper things for the plug-ins */
@interface SBookController(Helpers)
-(Class)PersonClass;
-(int)debug;
-(void)find:(const char *)line city:(char **)city state:(char **)state zip:(char **)zip;
-(unsigned int)parse_company:(const char *)buf;
-(unsigned int)parse_telephone:(const char *)buf arg:(unsigned int *)arg;
-(unsigned int)identifyLine:(const char *)buf;
-(void)extractLabel:(const char *)line toBuf:(char *)buf;
-(id)DefaultSwitchSetterClass;
-(SLC *)currentSLCNoSave;
-(SLC *)currentSLC;
-(Person *)currentPersonNoSave;
-(Person *)currentPerson; // current entry of active window, automatically saved.
@end

/* Notification */
// object is the SLC doing the save
#define SBookWillSaveFileNotification @"SBookWillSaveFileNotification"
#define SBookDidSaveFileNotification  @"SBookDidSaveFileNotification"


/* globals */

extern  SBookController *AppDelegate;
extern	int demo_mode();
extern const char *bookDefaultRTF;
