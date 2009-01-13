//
//  SyncBundleClass.m
//  SyncBundle
//
//  Created by Simson Garfinkel on Tue Dec 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "SyncBundleClass.h"
#import "AddressBookSyncer.h"

/* These are from SBook51 directory */
#import "DefaultSwitchSetter.h"
#import "PlugInController.h"
#import "SLC.h"
#import "SList.h"


@implementation SyncBundleClass

+ (void)initialize
{
    NSMutableDictionary *appDefs= [NSMutableDictionary dictionary];

    [appDefs setObject:@"1"  forKey:DEF_SBOOK_DELETES_ABADDRESSBOOK];
    [defaults registerDefaults:appDefs];
}

- (void)startup:(PlugInController *)owner                      // called when loaded          
{
    sbc = [NSApp delegate];

    /* Sync */
    /* Add view to preferences panel */
    [owner installPreference:@"Sync" view:syncPreferenceView];

    /* Add our menu options */
    [owner addActionToMenu:[owner menu:@"File"]
	   title:@"Sync with Apple AddressBook"
	   action:@selector(syncWithAppleAddressBook:)
	   target:self];
	   
    [owner addActionToMenu:[owner menu:@"File"]
	   title:@"Fast Sync on Save"
	   action:@selector(autoSyncOnSave:)
	   target:self];
	   
    
    [owner addActionToMenu:[owner menu:@"File/Import"]
	   title:@"Import from Apple AddressBook"
	   action:@selector(importFromAppleAddressBook:)
	   target:self];
	   
    [owner addActionToMenu:[owner menu:@"File/Export"]
	   title:@"Export to Apple AddressBook"
	   action:@selector(exportToAppleAddressBook:)
	   target:self];
	   
    [owner addActionToMenu:[owner menu:@"File/Export"]
	   title:@"Fast Sync To Apple AddressBook"
	   action:@selector(fastSyncToAppleAddressBook:)
	   target:self];
	   
    [owner addActionToMenu:[owner menu:@"Entry"]
	   title:@"Push Entry to Apple AddressBook"
	   action:@selector(pushEntryToAppleAddressBook:)
	   target:self];

    [[NSNotificationCenter defaultCenter]
	addObserver:self selector:@selector(sbookIsSaving:)
	name:SBookWillSaveFileNotification object:nil];
}

-(void)awakeFromNib
{
    setDefault(sync_sbook_deletes_addressbook,DEF_SBOOK_DELETES_ABADDRESSBOOK);
    setDefault(sync_username,DEF_SBOOK_SYNC_USERNAME);
    setDefault(sync_password,DEF_SBOOK_SYNC_PASSWORD);
    setDefault(sync_passphrase,DEF_SBOOK_SYNC_PASSPHRASE);
}

/****************************************************************
 *** Notifications
 ****************************************************************/


-(void)fastSyncToAppleAddressBookForSLC:(SLC *)slc
{
    AddressBookSyncer *abs = [slc objectOfClass:[AddressBookSyncer class]];
    [abs setSLC:slc];
    [abs syncSBookToSource:1];
}

-(void)sbookIsSaving:(NSNotification *)n
{
    SLC *slc = [n object];
    /* Sync on save */
    if([[slc doc] queryFlag:SLIST_AUTOSYNC_FLAG]){
	[self fastSyncToAppleAddressBookForSLC:slc];
    }

}



/****************************************************************
 *** Menu Commands
 ****************************************************************/

- (BOOL)validateMenuItem:(id <NSMenuItem>)item
{
    id currentPerson	= [[NSApp delegate] currentPersonNoSave];
    SLC *currentSLC	= [[NSApp delegate] currentSLCNoSave];
    SEL action		= [item action];

    /* This menu requires an active person */
    if(action == @selector(pushEntryToAppleAddressBook:)){
	return currentPerson ? YES : NO;		// there is a person!
    }
    if(action == @selector(autoSyncOnSave:)){
	if(currentSLC){
	    [item setState:[[currentSLC doc] queryFlag:SLIST_AUTOSYNC_FLAG]];
	    return YES;
	}
	return NO;
    }

    return currentSLC ? YES : NO;	// these just need an SLC
}

- (void)pushEntryToAppleAddressBook:(id)sender
{
    Person *aPerson = [sbc currentPerson]; // forces the save
    AddressBookSyncer *abs = [[[AddressBookSyncer alloc] init] autorelease];

    [abs syncPerson:aPerson flag:SYNC_AB_SAVE_FLAG]; // make sure it gets saved
}

- (void)fastSyncToAppleAddressBook:(id)sender
{
    [self fastSyncToAppleAddressBookForSLC:[sbc currentSLC]];
}


- (IBAction)syncWithAppleAddressBook:(id)sender
{
    SLC *slc = [sbc currentSLC];
    AddressBookSyncer *abs = [slc objectOfClass:[AddressBookSyncer class]];
    [abs runWithSLC:slc flag:0];
}

- (IBAction)autoSyncOnSave:(id)sender
{
    SLC *slc = [sbc currentSLC];
    SList *doc = [slc doc];

    [slc saveEntry];			// make sure it is written
    [doc setFlag:SLIST_AUTOSYNC_FLAG toValue:![doc queryFlag:SLIST_AUTOSYNC_FLAG]];
}


- (IBAction)importFromAppleAddressBook:sender
{
    SLC *slc = [sbc currentSLC];
    AddressBookSyncer *abs = [slc objectOfClass:[AddressBookSyncer class]];
    [abs runWithSLC:slc flag:TAG_IMPORT_ABOOK_TO_SBOOK];
}


- (IBAction)exportToAppleAddressBook:sender
{
    SLC *slc = [sbc currentSLC];
    AddressBookSyncer *abs = [slc objectOfClass:[AddressBookSyncer class]];
    [abs runWithSLC:slc flag:TAG_EXPORT_SBOOK_TO_ABOOK];
}



@end
