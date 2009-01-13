#import <Cocoa/Cocoa.h>

@class ABAddressBook;
@class ABPerson;
@class SList;
@class SLC;
@class Person;
@class SBookController;

#import "Syncher.h"

/* Sync */
#define DEF_SBOOK_DELETES_ABADDRESSBOOK	@"SBookDeletesAppleAddressBook"
#define DEF_SBOOK_AUTOSYNC @"SBookAutoSync"

@interface AddressBookSyncer:Syncher
{
    ABAddressBook *ab;			// address book we are syncing from
    NSMutableString *myAddressBookName;	// name of this address book
    SBookController *sbc;
}

- (void)setMyAddressBookName;
- (bool)check:(Person *)per at:(unsigned int)line forCityState:(NSMutableDictionary *)tia;
- (ABPerson *)copyFromPerson:(Person *)per toABP:(ABPerson *)abp;
- (Person *)syncABPerson:(ABPerson *)abperson;
- (ABPerson *)abpersonForPerson:(Person *)per;
// Person --> ABPerson (creates new if necessary)
- (ABPerson *)syncPerson:(Person *)per flag:(int)flag;

/* Flags */
#define SYNC_FORCE_FLAG   0x0001
#define SYNC_AB_SAVE_FLAG 0x0002
#define SYNC_GUI_FLAG     0x0004	// update the GUI elements

@end

