/*
 * Person.h
 * high-level person stuff
 * 
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2002, 2003 by Simson Garfinkel.
 *
 * All Rights Reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import "XMLArchiver.h"

#define FAKECOCOA_H			// avoid brining in cocoa defines
#import "libsbook.h"

/* Defaults for files and entries */
#define DEF_LAST_FIRST			@"LastnameFirstname"

@class SList;
@interface Person:NSObject  <XMLArchivableObject>
{
    /* Archived Information */
    NSString	*gid;		/* global identifier for this entry */
    unsigned long entrySN;	/* serial number for this entry */
    unsigned long flags;	/* flag */
    int		sortKey;	/* word to start sorting at; may be -1 for last word */
    time_t	c_time;		/* when created */
    time_t	mtime;		/* when last modified */
    time_t	atime;		/* when last accessed */
    time_t	calltime;	/* last called */
    time_t	envtime;	/* last envelope time */
    time_t	emailtime;	/* last envelope time */
    NSString	*cellName;	/* first line as displayed in matrix */
    NSString	*cellNameLF;	/* cellName, last name first */
    NSString    *lastName;
    NSString    *firstName;

    NSString	*cusername;	/* person who created entry      */
    NSString	*musername;	/* last person to modify entry   */

    /* Synchronization support.
     * This needs to become a syncObject that we maintain for each syncSource...
     */
    NSString	*syncSource;	/* Where we got this record from */
    NSString	*syncUID;	// UID on SyncSource
    time_t      syncTime;	/* When it entry was synced from syncSource */
    time_t      syncMtime;	/* source's mtime */
    NSData	*syncMD5;	/* binary MD5; stored as Base64 */
    
    /* The SList we happen to be in, for setting our default font */
    SList	*doc;

    /* The data. You may have either or both.
     * Set to NIL if you don't have it.
     */
    NSString	*asciiString;		/* Alternatively the ASCII string */
    NSData	*rtfdData;		/* RTFD data to be displayed */
    NSData	*base64RtfdData;	/* Base64-encoded RTFD; superseeds rtfdData */

    /* Derrived Information */
    NXAtomList	*names;		/* each name in first line */
    NXAtomList	*metaphones;	/* metaphones; one for each name */
    NXAtom	sortName;	/* just computing */
    NXAtom	theSmartSortName;
    struct TextParagraphs *tp;		// paragraphs that were found
    unsigned int *results;
    NSMutableArray	*asciiLines;
    int		isPerson;
    BOOL	parsed;
}

+(NSString *)SBookAsciiForPeople:(NSArray *)arrayOfPeople;
+(NSString *)vCardForPeople:(NSArray *)arrayOfPeople;
+(NSString *)findZip:(NSString *)str;	// returns the zip code from last line of string
- initForRTFDData:(NSData *)newData sortKey:(int)sKey;
- (NSString *)vCard:(BOOL)withRTFD; // a vCard that corresponds to this Person; with optional RTFD
- (void)touch;
- (int)compareTo:(Person *)aPerson;	// runs PersonSortFun(self,aPerson)

/* XML */
- (void)encodeWithXMLCoder:(XMLCoder *)aCoder;


/* Derrived information */
- (BOOL)blankEntry;			// only has whitespacep
- (NSString *)firstName;		// 
- (NSString *)lastName;			// 
- (NSString *)cellName:(BOOL)lastNameFirstFlag;
- (NSString *)cellName;			// reads default from Defaults database
- (NXAtomList *)metaphones;
- (NXAtomList *)cellNames;
- (BOOL)isPerson;			// as opposed to isCompany

/* sortKeys:
 * 1=first name, 2=second, 3=third, -1 for last, -2 second last, SMART_SORT=smart sort.
 */

- (int)sortKey;
- setSortKey:(int)aKey;   
- (NXAtom)sortName;
- (void)setSmartSortNameAndPersonFlag;

- (void)checkpointForUndo;		// makes a copy of what we are

/* Parsed results */
- (void)releaseParsedData;
- (void)parse;
- (unsigned int)numAsciiLines;			// number of ASCII Lines
- (NSString *)asciiLine:(unsigned int)n;	// a particular ASCII Line, without the newline at end
- (int)sbookTagForLine:(unsigned int)n;		// returns the sbook tag of line N
- (int)firstLineWithTag:(unsigned)tag;	// returns first line that has the sbook tag "tag"; -1 if line is not to be found
- (void)setCellName:(NSString *)cellName;
- (void)computeCellNameFromRTFDData;		// from the RTFD

/* initialization methods */
- (void)newGID;				// make a new GID

/* Coder */
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (void)setDoc:(SList *)aDoc;

/* entryData accessor methods.
 * Some of them automatically convert between ascii and RTFd
 */
- (NSData *)rtfdData;
- (void)fixAscii;
- (NSString *)asciiString;
- (NSData *)asciiMD5;			// returns md5 for asciiString in UTF8 coding
- (NSData *)rtfdMD5;			// returns md5 for asciiString in UTF8 coding
- (NSData *)base64RtfdData;
- (void)setRTFDData:(NSData *)newData  andUpdateMtime:(BOOL)flag; // setting RTFD always sets ASCII too
- (void)setAsciiData:(NSData *)newData releaseRtfdData:(BOOL)releaseRtfd  andUpdateMtime:(BOOL)flag; 
- (BOOL)hasRtfdData;			// true if the RTFd data has been generated
- (BOOL)hasAsciiString;
- (void)discardAscii;
- (void)discardFormatting;
- (void)discardRtfdData;		// only discards if there is AsciiString
- (void)setB64RTFDData:(NSData *)newB64Data; // does not touch AsciiData or mTime

/* accessor methods */
- (NSString *)gid;
- (NSString *)cusername;
- (NSString *)musername;
- (void)setGid:(NSString *)gid;		// global ID
- (void)setCtime:(time_t)t;
- (void)setAtime:(time_t)t;
- (void)setMtime:(time_t)t;
- (void)setCusername:(NSString *)cusername;
- (void)setMusername:(NSString *)musername;
- (void)setEntrySN:(unsigned int)n;
- (unsigned int)entrySN;
- (void)setSyncTime:(time_t)t;
- (void)setSyncMtime:(time_t)t;
- (void)setSyncMD5:(NSData *)data;
- (time_t)syncTime;
- (time_t)syncMtime;
- (NSData *)syncMD5;
- (void)setSyncSource:(NSString *)string;
- (NSString *)syncSource;
- (void)setSyncUID:(NSString *)string;
- (NSString *)syncUID;

/* Accessors for Flags */
- (unsigned long)flags;
- (void)setFlags:(unsigned long)someFlags;
- (void)setFlag:(unsigned long)aFlag toValue:(BOOL)aValue;
- (void)addFlag:(unsigned long)aFlag;
- (void)removeFlag:(unsigned long)aFlag;
- (BOOL)queryFlag:(unsigned long)mask;

/* Accessors for action */

- (void)touch;
- (time_t)atime;
- (time_t)ctime;
- (time_t)mtime;
- (time_t)calltime;
- (time_t)envtime;
- (time_t)emailtime;
- (void)updateAccessTime;
- (void)telephoned;
- (void)emailed;
- (void)enveloped;

/* Search/replace */
- (BOOL)hasText:(NSString *)text       options:(unsigned)opts;
- (int) hasTextCount:(NSString *)text  options:(unsigned)opts;// number of times the text is in the string
- (void)replaceText:(NSString *)search withText:(NSString *)replace options:(unsigned)opts; // does both rich and non-rich

/* Undo/redo */
- (void)takeInstanceVariablesFromArchivedData:(NSData *)theData;


@end


#ifdef __cplusplus
extern "C" {
#endif
int PersonSortFun(Person *p1,Person *p2,void *context); // context is for AppKit
#ifdef __cplusplus
}
#endif
