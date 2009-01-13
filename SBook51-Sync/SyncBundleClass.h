//
//  SyncBundleClass.h
//  SyncBundle
//
//  Created by Simson Garfinkel on Tue Dec 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SBookController;
@interface SyncBundleClass : NSObject {
    /* Preference Panel */

    IBOutlet NSView	*syncPreferenceView;
    IBOutlet id		sync_sbook_deletes_addressbook;
    IBOutlet NSTextField *sync_username;
    IBOutlet NSTextField *sync_password;
    IBOutlet NSTextField *sync_passphrase;
    SBookController	*sbc;
}

#define DEF_SBOOK_SYNC_USERNAME @"Sync Username"
#define DEF_SBOOK_SYNC_PASSWORD @"Sync Password"
#define DEF_SBOOK_SYNC_PASSPHRASE @"Sync Passphrase"


@end
