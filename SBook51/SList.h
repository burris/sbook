/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2002-2003 by Simson Garfinkel
 *
 * All Rights Reserved.
 *
 */

/*
 * The basic SList data structure --- Holds the list of all People. It's the document
 */

#import <Cocoa/Cocoa.h>
#import "XMLArchiver.h"
#import "SLCProtocol.h"

/* Defaults for files and entries */
#define DEF_SEARCH_MODE			@"SearchMode"



@interface SList:NSObject <XMLArchivableObject>
{
    /* These are saved */
    NSRect	frame;			/* window frame */
    float	divider;		/* divider height */
    unsigned long flags;			
    int		searchMode;	
    int		defaultSortKey;
    int		defaultPersonFlags;
    NSString	*defaultUsername;	// of saved XML file
    NSData	*RTFTemplate;		
    NSMutableArray *people;	
    NSMutableDictionary *peopleByGid;	// track the GIDs
    int		columnOneMode;
    NSMutableDictionary *deletedGIDs;	// keep track of what we have deleted;
    // values are the date that the object was deleted

    /* Format information derrived from the template */
    NSFont		*firstLineFont;
    NSFont		*secondLineFont;
    NSTextAlignment	firstLineAlignment;
    NSTextAlignment	secondLineAlignment;

    /* These are not saved */
    BOOL	nakedList;		// do we store extra stuff with list?
    int		fileDelim;
    NSMutableDictionary 	*addressBookInfo;
    id		labelsInfo;		
    int		lastSuccessfulSearchMode;
    NSData	*myKey;			// key used to encrypt
    NSUndoManager *undoManager;		// my undoManager
    id <SLCProtocol>	slc;			// our controller
}

+ (NSData *)factoryDefaultRTFDataTemplate;
+ (SList *)slistWithPeople:(NSArray *)people; // return an SList with these people 
- init;

/* XML */
- (void)encodeWithXMLCoder:(XMLCoder *)aCoder;
- (NSData *)xmlRepresentation;		// returns XML for SList
+ (NSData *)xmlDocType;
- (NSData *)xmlDocType;
- (NSString *)xmlAttributes;

/* Deletion */
- (NSMutableDictionary *)deletedGIDs;
- (void)cleanDeletedGIDs;

/* accessor methods */
- (void)setNakedList:(BOOL)aFlag;	// don't encode other information, just list
- (NSArray *)allPeople;			// gives a disposable array of all people
- (time_t)whenDeleted:(NSString *)aGID;	// when this GID was deleted, or 0 if it wasn't
- (int)flags;
- (void)setFlags:(unsigned long)allFlags;
- (void)setFlag:(unsigned long)mask toValue:(BOOL)aValue;
- (void)addFlag:(unsigned long)aFlag;
- (void)removeFlag:(unsigned long)aFlag;
- (BOOL)queryFlag:(unsigned long)mask;
- (int)searchMode;
- (void)setSearchMode:(int)aMode;
- (NSFont *)firstLineFont;
- (NSFont *)secondLineFont;
- (void)setEncryptionKey:(NSData *)aKey;
- (NSData *)encryptionKey;
- setFrame:(NSRect)frame;
- (NSRect)frame;
- setDivider:(float)aHeight;
- (float)divider;
- (NSData *)RTFTemplate;			// RTF, not RTFD
- (NSString *)asciiTemplate;
- (void)setAsciiTemplate:(NSString *)aTemplate;
- (void)setRTFTemplate:(NSData *)aNewTemplate;
- (int)defaultSortKey;
- (void)setDefaultSortKey:(int)aKey;
- (NSMutableDictionary *)addressBookInfo;
- labelsInfo;
- setLabelsInfo:li;
- (NSRange)rangeOfYears;		// range of years for entries; ignores year 0 
- (NSString *)defaultUsername;
- (void)setDefaultUsername:(NSString *)username;
- (void)setDefaultPersonFlags:(unsigned int)flags;
- (unsigned int)defaultPersonFlags;
- (void)setUndoManager:(NSUndoManager *)undo;
- (NSUndoManager *)undoManager;
- (void)setSLC:(id <SLCProtocol> )slc_;
- (void)setColumnOneMode:(int)aMode;
- (int)columnOneMode;

/* SList management */
- (unsigned int)numPeople;
- (void)makeMe:(Person *)me;		// make this person me (remove ME flag from others 
- (void)addPerson:(Person *)aPerson;	// doesn't add if already present
- (void)addPersonClearingStatus:(Person *)aPerson; // clears status on SLC controller...
- (void)removePerson:(Person *)aPerson;
- (void)removePeople:(NSArray *)arrayOfPeople;
- (NSArray *)findDuplicates;		// returns array of duplicate People
- (Person *)personAt:(int)aNumber;
- (NSEnumerator *)personEnumerator;
- (void)makePeoplePerformSelector:(SEL)aSelector withObject:(id)anObject;
- (Person *)personWithGid:(NSString *)gid;
- (NSArray *)allPeopleGids;
- (NSArray *)peopleWithSyncSource:(NSString *)aSource;
- (Person *)personWithSyncUID:(NSString *)aUID;


/* action methods */

- (void)setSearchMode:(int)mode;
- (int)searchMode;
- (void)sortPeople;				// sort all of the People
- (BOOL)resortPerson:aPerson;		/* resort person.  Return TRUE if person moved */
- (Person *)personNamed:(NSString *)cellName;
 
/* Search methods */
- (NSArray *)searchFor:(NSString *)string mode:(int)searchMode;
- (int)lastSuccessfulSearchMode;

/* Statistics */
- (NSString *)mostCommonUsername;
- (int)mostCommonSortKey;
- (unsigned int)mostCommonFlags;
@end


/* SList_txtwrite.m */
@interface SList(txtwrite)
-(NSData *)txtWriteWithExportInfo:(NSDictionary *)fmt;
@end



/* SList_xmlread.m */

#ifdef __cplusplus
extern "C" {
#endif

    SList *SList_xmlread(NSData *d,SList *refresh);

#ifdef __cplusplus
}
#endif

/* SList_txtread.m */


#ifdef __cplusplus
extern "C" {
#endif

    NSDictionary *SList_txt_identify(NSData *d);
    SList *SList_txtread(NSData *d);
    NSString *SList_tag_name(int tag);

#ifdef __cplusplus
}
#endif
