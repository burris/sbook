/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law.
 *
 */

#import <Cocoa/Cocoa.h>
#import <assert.h>

#import "SList.h"
#import "Person.h"
#import "XMLCoder.h"
#import "tools.h"
#import "md5.h"
#import "XMLArchiver.h"
#import "EncryptedObject.h"
#import "DefaultSwitchSetter.h"

@interface Histogram:NSObject
{
    NSMutableDictionary *dict;
}
- (void)tallyObject:object;
- mostCommonObject;
+ (Histogram *)histogram;
@end
@implementation Histogram
-init
{
    [super init];
    dict	= [[NSMutableDictionary dictionary] retain];
    return self;
}

+(Histogram *)histogram
{
    return [[[self alloc] init] autorelease];
}

- (void)dealloc
{
    [dict release];
    [super dealloc];
}
    
- (void)tallyObject:object
{
    NSNumber *count;

    count = [dict objectForKey:object];
    if(!count){
	count = [NSNumber numberWithInt:0];
    }
    [dict setObject:[NSNumber numberWithInt:[count intValue]+1]
	  forKey:object];
}

- mostCommonObject
{
    NSEnumerator *en = [dict objectEnumerator];
    int most = 0;
    id mostObj = nil;
    id  obj = nil;
    
    while(obj = [en nextObject]){
	if([obj intValue] > most){
	    most = [obj intValue];
	    mostObj = obj;
	}
    }
    return mostObj ? [[dict allKeysForObject:mostObj] objectAtIndex:0] : nil;
}

@end

@implementation SList

static NSTextView *myText = 0;
static NSTextView *myText2 = 0;
static NSData *factoryDefaultRTFDataTemplate = 0;

+(void)initialize
{
    NSMutableDictionary *appDefs =	[NSMutableDictionary dictionary];

    myText	= [[NSTextView alloc] init]; // for finding the first line
    myText2	= [[NSTextView alloc] init]; // for finding the first line

    factoryDefaultRTFDataTemplate = [[NSData dataWithContentsOfFile:
					       [[NSBundle mainBundle]
						   pathForResource:@"template" ofType:@"rtf"]]
				    retain];

    if(!factoryDefaultRTFDataTemplate){
	NSRunAlertPanel(@"Error",@"Cannot find template.rtf!",nil,nil,nil);
    }

    /* Now create the RTFD template */

    [appDefs  setObject:[NSNumber numberWithInt:SEARCH_AUTO] forKey:DEF_SEARCH_MODE];
    [defaults registerDefaults:appDefs];
}

+ (SList *)slistWithPeople:(NSArray *)newPeople // return an SList with these people
{
    SList *ret = [[SList alloc] init];
    [ret->people release];
    ret->people = [newPeople retain];
    return ret;
}


+ (NSData *)factoryDefaultRTFDataTemplate
{
    return factoryDefaultRTFDataTemplate;
}

- init
{
    [super init];
    people		= [[NSMutableArray alloc] init];
    peopleByGid		= [[NSMutableDictionary alloc] init];
    addressBookInfo	= [[NSMutableDictionary alloc] init];
    deletedGIDs		= [[NSMutableDictionary alloc] init];
    RTFTemplate		= [[SList factoryDefaultRTFDataTemplate] retain];
    defaultSortKey	= ENTRY_SMART_SORT_TAG;
    flags		= SLIST_SORT_FLAG | SLIST_DONT_PARSE_ITALIC;

    return self;
}

- (void)dealloc
{
    [people	release];
    [peopleByGid release];
    [deletedGIDs release];
    [super	dealloc];
}


+ (NSData *)xmlDocType
{
    char *type = "<!DOCTYPE entries PUBLIC \"-//Simson L. Garfinkel// DTD SBook5 //EN//XML\" "
	"\"http://www.sbook5.com/1.0/sbook.dtd\">\n";

    return [NSData dataWithUTF8String:type];
}

- (NSData *)xmlDocType
{
    return [SList xmlDocType];
}

- (NSString *)xmlAttributes
{
    return nil;
}

/****************************************************************
 ** Deletion
 ****************************************************************/

- (void)cleanDeletedGIDs
{
    NSEnumerator *en = [peopleByGid keyEnumerator];
    NSString *key;
    while(key = [en nextObject]){
	[deletedGIDs removeObjectForKey:key];
    }
}

- (NSMutableDictionary *)deletedGIDs { return deletedGIDs;}

- (time_t)whenDeleted:(NSString *)str
{
    NSString *when = [deletedGIDs objectForKey:str];
    return when ? [when intValue] : 0;
}


/****************************************************************
			 accessor methods
****************************************************************/

- (void)setNakedList:(BOOL)aFlag{    nakedList = aFlag; }
- setFrame:(NSRect)aFrame 	{ frame	= aFrame; return self; }
- (NSRect)frame 		{ return frame; }
- setDivider:(float)aHeight 	{ divider = aHeight; return self; }
- (float)divider 		{ return divider; }
- (unsigned int)defaultPersonFlags {return defaultPersonFlags;}
- (void)setDefaultSortKey:(int)aKey 	{ defaultSortKey = aKey;  }
- (void)setDefaultPersonFlags:(unsigned int)f { defaultPersonFlags = f;}
- (NSString *)defaultUsername   { return defaultUsername;}
- (void)setDefaultUsername:(NSString *)name { [defaultUsername release];defaultUsername = [name retain];}
- (NSMutableDictionary *)addressBookInfo		{ return addressBookInfo;}
- labelsInfo			{ return labelsInfo;}
- setLabelsInfo:li		{ labelsInfo = li;return self;}
- (int)searchMode		{ return searchMode; }
- (int)flags			{ return flags;			}
- (void)addFlag:(unsigned long)aFlag	{ flags	|= aFlag;               }
- (void)setFlag:(unsigned long)mask toValue:(BOOL)aValue
{
    [self setFlags:(flags & ~mask) | (aValue ? mask : 0)];
}
- (void)removeFlag:(unsigned long)fg	{ flags &= ~fg;			}
- (BOOL)queryFlag:(unsigned long )mask	{ return flags & mask ? YES : NO;		}
- (int)lastSuccessfulSearchMode { return lastSuccessfulSearchMode;}
- (void)setUndoManager:(NSUndoManager *)undo {undoManager = undo;}
- (void)setSLC:(id <SLCProtocol> )slc_ {slc = slc_;} 
- (NSUndoManager *)undoManager { return undoManager;}

- (void)setColumnOneMode:(int)aMode { columnOneMode = aMode;}
- (int)columnOneMode {return columnOneMode;}


- (int)defaultSortKey
{
    if(defaultSortKey==0){		// this is a bug?
	defaultSortKey = ENTRY_SMART_SORT_TAG;
    }
    return defaultSortKey;
}


- (void)setEncryptionKey:(NSData *)newKey
{
    [myKey release];
    myKey = [newKey retain];
}

- (NSData *)encryptionKey {return myKey;}

- (void)setSearchMode:(int)aMode
{
    if(aMode==SEARCH_AUTO ||
       aMode==SEARCH_WORD_MATCH ||
       aMode==SEARCH_FULL_TEXT ||
       aMode==SEARCH_PHONETIC){
	searchMode = aMode;
    }
}


- (void)setFlagsToValue:obj
{
    [self setFlags:[obj intValue]];
}

- (void)setFlags:(unsigned long)aFlag
{
    if(flags==aFlag) return;

    [undoManager registerUndoWithTarget:self
		 selector:@selector(setFlagsToValue:)
		 object:[NSNumber numberWithInt:flags]];
    [undoManager setActionName:@"Restore SList Setting"];


    flags	= aFlag;
    if([self queryFlag:SLIST_SORT_FLAG]){
	[self sortPeople];
    }
}


/* The fonts are special. If they are not defined, sensible defaults are returned */

- (NSFont *)firstLineFont
{
    if(firstLineFont) return firstLineFont;
    return [NSFont fontWithName:@"Helvetica" size:14.0];
}

- (NSFont *)secondLineFont
{
    if(secondLineFont) return secondLineFont;
    return [NSFont fontWithName:@"Helvetica" size:12.0];
}


static void processTime(time_t t,int *ymin,int *ymax)
{
    struct tm *tm;

    if(t==0) return;
    tm = localtime(&t);
    if(*ymin==0 || *ymin > tm->tm_year) *ymin = tm->tm_year;
    if(*ymax==0 || *ymax < tm->tm_year) *ymax = tm->tm_year;
}

- (NSRange)rangeOfYears
{
    NSEnumerator *en = [people objectEnumerator];
    Person *person;
    int year0 = 0;
    int year1 = 0;

    while(person = [en nextObject]){
	processTime([person atime],&year0,&year1);
	processTime([person mtime],&year0,&year1);
	processTime([person ctime],&year0,&year1);
    }
    year0 += 1900;
    year1 += 1900;

    return NSMakeRange(year0,year1-year0);
}



/* XML Stuff */

- (NSString *)xmlName
{
    return @"entries";
}

- (void)encodeWithXMLCoder:(XMLCoder *)aCoder
{
    NSString *version = nil;
    version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];

    NSLog(@"version=%@",version);
    [self cleanDeletedGIDs];

    defaultPersonFlags	= [self mostCommonFlags];

    [defaultUsername release];
    defaultUsername	= [[self mostCommonUsername] retain];

    [aCoder setUseSpaces:NO];		// don't use spaces


    if(nakedList == NO){
	if(version){
	    [aCoder encodeXMLName:@"sbookversion"   stringValue:version];
	}
	[aCoder encodeXMLName:@"frame"		rect:frame];
	[aCoder encodeXMLName:@"columnonemode"	intValue:columnOneMode];
	[aCoder encodeXMLName:@"divider"	intValue:(int)divider];
	[aCoder encodeXMLName:@"flags"		intValue:flags];
	[aCoder encodeXMLName:@"defaultsortkey"	intValue:[self defaultSortKey]];
	[aCoder encodeXMLName:@"searchmode"	intValue:[self searchMode]];
	[aCoder encodeXMLName:@"template"	stringValue:[self asciiTemplate]];
	[aCoder encodeXMLName:@"rtftemplate"	binData:[self RTFTemplate]];
	[aCoder encodeXMLName:@"entrycount"	intValue:[people count]];
	[aCoder encodeXMLName:@"defaultpersonflags" unsignedIntValue:defaultPersonFlags];
	[aCoder encodeXMLName:@"deletedpeople"	subName:@"delent" dictionary:deletedGIDs];
    }
    [aCoder encodeXMLObject:people];
}

- (NSData *)xmlRepresentation
{
    NSData *ret = [XMLArchiver archiveXMLObject:self];
    
    if([self queryFlag:SLIST_ENCRYPTED_FLAG]){
	NSAssert(myKey!=0,@"SList xmlRepresentation: myKey==0?");
	ret = [XMLArchiver archiveXMLObject:[EncryptedObject plaintext:ret andKey:myKey]];
    }
    return ret;
}



/*
 * return the template for this file
 */

- (NSData *)RTFTemplate
{
    return RTFTemplate;
}

/*
 * asciiTemplate: Turn the template into the ASCII representation
 */

- (NSString *)asciiTemplate
{
    NSMutableString *ret=0;
    unichar lastChar;

    [myText setRtfData:[self RTFTemplate]];

    /* Now get the data out */

    ret = [NSMutableString stringWithString:[myText string]];

    /* If the template is 0 length, add a \n */

    if([ret length]==0){
	[ret appendString:@"\n"];
    }
    
    /* If the last character is not a \n, add a \n */

    lastChar = [ret characterAtIndex:[ret length]-1];
    if(lastChar != '\n'){
	[ret appendString:@"\n"];
    }
    return ret;
}

- (void)setAsciiTemplate:(NSString *)str
{
    [myText setString:str];
    NSData *data = [myText rtfData];

    [self setRTFTemplate:data];
}

- (void)setRTFTemplate:(NSData *)rtf
{
    NSRange r;

    [RTFTemplate release];RTFTemplate = nil;
    [firstLineFont release];firstLineFont = nil;
    [secondLineFont release];secondLineFont = nil;

    RTFTemplate = [[NSData dataWithData:rtf] retain];
    /* Figure out the first and second line fonts */
    [myText setRtfData:rtf];
    [myText setSelectedRange:NSMakeRange(0,0)];
    firstLineFont = [myText font];

    r = [myText getParagraphRange:1];
    if(r.location>0 && r.length>0){
	r.length=1;
	[myText2 setRtfData:[myText RTFFromRange:r]];
	[myText2 setSelectedRange:NSMakeRange(0,0)];
	secondLineFont = [myText2 font];
    }
    else{
	secondLineFont = [NSFont fontWithName:@"Helvetica" size:12.0]; // default
    }
}

/****************************************************************
  SList Management
 ****************************************************************/

- (unsigned int)numPeople 		{ return [people count]; }

// make this person me (remove ME flag from others 
- (void)makeMe:(Person *)me
{
    /* First clear the ME flag in all entries */
    NSEnumerator *en = [people objectEnumerator];

    while( Person *p = [en nextObject]){
	[p setFlag:ENTRY_ME_FLAG toValue:0];
    }
    [me setFlag:ENTRY_ME_FLAG toValue:YES];
    
}


- (void)addPerson:(Person *)aPerson
{
    extern int demo_mode();
    id undoTarget = slc;

    if(aPerson==nil) return;		// can't add what you don't have
    if(slc==nil) undoTarget = self;

    assert([aPerson class] == [Person class]);
	
    /* If we have a Person with this GID, change the GID
     * of the incoming person (unless this person is already in the
     * database, in which case we do nothing...)
     */
    while([peopleByGid objectForKey:[aPerson gid]]!=0){
	if([people containsObject:aPerson]){
	    return ;			// already in DB
	}
	[aPerson newGID];		// get a ne ew GID...
    }

    [aPerson	setDoc:self];		// you now belong to me
    [people	addObject:aPerson];
    [peopleByGid setObject:aPerson forKey:[aPerson gid]];

    if([self queryFlag:SLIST_SORT_FLAG]) [self resortPerson:aPerson];

    if([undoManager isUndoing] || [undoManager isRedoing]){
	[slc addPersonToVisibleList:aPerson];
    }

    /* Remember how to undo this */
    [undoManager registerUndoWithTarget:undoTarget
		 selector:@selector(removePerson:)
		 object:aPerson];

    if([undoManager isUndoing]==NO && [undoManager isRedoing]==NO){

	/* And remember how to undo this */
	[undoManager setActionName:[NSString stringWithFormat:@"Add Entry '%@'",
					     [aPerson cellName]]];
    }
}

- (void)addPersonClearingStatus:(Person *)aPerson
{
    [ slc setStatus:@""];
    [ self addPerson:aPerson];
}

-(void) removePerson:(Person *)aPerson
{
    /* Do not display the person anymore */
    if([undoManager isUndoing] || [undoManager isRedoing]){
	[slc removePersonFromVisibleList:aPerson];
    }

    /* Register how to undo */
    [undoManager registerUndoWithTarget:self
		 selector:@selector(addPersonClearingStatus:)
		 object:aPerson];

    if([undoManager isUndoing]==NO && [undoManager isRedoing]==NO){
	/* And remember how to undo this */
	[undoManager setActionName:[NSString stringWithFormat:@"Remove Entry '%@'",
					     [aPerson cellName]]];
    }

    /* And finally, remove the person */
    [people		removeObject:aPerson];
    [peopleByGid	removeObjectForKey:[aPerson gid]];

    [deletedGIDs	setObject:[NSNumber numberWithInt:time(0)]
			forKey:[aPerson gid]];
    if([aPerson syncUID]){
	[deletedGIDs	setObject:[NSNumber numberWithInt:time(0)]
			forKey:[aPerson syncUID]];
    }

}

- (void)removePeople:(NSArray *)arrayOfPeople
{
    /* This needs undo support --- or does it? Right now, it is only called
     * when we are undoing...
     */
    NSEnumerator *en = [arrayOfPeople objectEnumerator];
    Person *obj;
    [people removeObjectsInArray:arrayOfPeople];
    while(obj = [en nextObject]){
	[peopleByGid removeObjectForKey:[obj gid]];
    }
    [[self undoManager] removeAllActionsWithTarget:self ]; // be safe for now
}


- (NSArray *)findDuplicates		// returns number removed; uses MD5 on rtfd
{
    NSEnumerator *en = [self personEnumerator];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSMutableArray *ret = [NSMutableArray array];
    Person *per;
    while(per = [en nextObject]){
	NSData *md5 = [per rtfdMD5];
	if([dict objectForKey:md5]){
	    /* We already have this person */
	    [ret addObject:per];
	}
	else {
	    [dict setObject:per forKey:md5]; // remember
	}
    }
    return ret;
}


-(Person *)personAt:(int)aNumber
{
    return [people objectAtIndex:aNumber];
}

-(Person *)personWithGid:(NSString *)gid
{
    return [peopleByGid objectForKey:gid];
}

- (NSArray *)allPeopleGids
{
    return [peopleByGid allKeys];
}

- (NSArray *)allPeople
{
    return [people copy];
}

- (NSArray *)peopleWithSyncSource:(NSString *)aSource
{
    NSMutableArray *ret = [NSMutableArray array];
    NSEnumerator *en = [people objectEnumerator];
    while(Person *person = [en nextObject]){
	if([[person syncSource] isEqualToString:aSource]){
	    [ret addObject:person];
	}
    }
    return ret;
}

- (Person *)personWithSyncUID:(NSString *)aUID
{
    NSEnumerator *en = [people objectEnumerator];
    while(Person *person = [en nextObject]){
	if([[person syncUID] isEqualTo:aUID]){
	    return person;
	}
    }
    return nil;
}

- (NSEnumerator *)personEnumerator
{
    return [people objectEnumerator];
}

- (void)makePeoplePerformSelector:(SEL)aSelector withObject:(id)anObject
{
    [people makeObjectsPerformSelector:aSelector withObject:anObject];
}


/****************************************************************
  Action methods
 ****************************************************************/

- (void)sortPeople
{
    [people sortUsingFunction:PersonSortFun context:0];
}

/* resortPerson:
 * Check to see if this person is properly in place.
 * If not, remove from the list and insert sorted...
 * returns true if the sort order was changed.
 */
- (BOOL)resortPerson:aPerson
{
    [self sortPeople];
    return true;
}

/****************************************************************
 ** SEARCHING
 ****************************************************************/

- (Person *)personNamed:(NSString *)cellName
{
    unsigned int	i;

    for(i=0;i<[people count];i++){
	id	ap = [people objectAtIndex:i];

	if(![[ap cellName] compare:cellName]) return ap;
    }
    return nil;
}

/* searchFor --
 * 0 length search gets all people.
 */

-(NSArray *)searchFor:(NSString *)string mode:(int)aMode
{
    if([string length]==0){
	return [NSArray arrayWithArray:people];
    }

    /* If we are doing an auto search, try each mode until
     * we get an answer that has an element in it.
     */
    if(aMode==SEARCH_AUTO){
	NSArray *ret;

	ret = [self searchFor:string mode:SEARCH_WORD_MATCH];
	if([ret count]>0) return ret;
	
	ret = [self searchFor:string mode:SEARCH_FULL_TEXT];
	if([ret count]>0) return ret;

	ret = [self searchFor:string mode:SEARCH_PHONETIC];
	return ret;
    }

    /* Boolean operators: &  */
    NSArray *and_ = [string componentsSeparatedByString:@"&"];
    if([and_ count]>1){
	NSEnumerator *en = [and_ objectEnumerator];
	NSString *s2 = [en nextObject];

	NSMutableArray *ret = [NSMutableArray arrayWithArray:[self searchFor:s2 mode:aMode]];
	while((s2 = [en nextObject]) && ([s2 length]>0)){
	    NSArray *r2 = [self searchFor:s2 mode:aMode];
	    [ret removeObjectsNotInArray:r2];
	}
	return ret;
    }

    /* Boolean operators: | */
    NSArray *or_ = [string componentsSeparatedByString:@"|"];
    if([or_ count]>1){
	NSEnumerator *en = [or_ objectEnumerator];
	NSString *s2 = [en nextObject];

	NSMutableArray *ret = [NSMutableArray arrayWithArray:[self searchFor:s2 mode:aMode]];
	while((s2 = [en nextObject]) && ([s2 length]>0)){
	    NSArray *r2 = [self searchFor:s2 mode:aMode];
	    [ret addUniqueObjects:r2];
	}
	return ret;
    }

    NSMutableArray *ret = [[NSMutableArray alloc] init];
    lastSuccessfulSearchMode = aMode;

    NXAtomList	*mlist = atomsForNames([string UTF8String]); // get the mlist
    NSEnumerator *en = [people objectEnumerator];
    Person *person;
    while(person = [en nextObject]){
	bool matched = false;

	switch(aMode){
	default:
	    NSLog(@"invalid search mode '%d' defaulting to WORD_MATCH",aMode);
	case SEARCH_WORD_MATCH:
	    matched = sbookIncrementalMatch([person cellNames],mlist);
	    break;
	case SEARCH_PHONETIC:
	    matched = sbookIncrementalMatch([person metaphones],mlist);
	    break;
	case SEARCH_FULL_TEXT:
	    matched = [person hasText:string options:NSCaseInsensitiveSearch];
	    break;
	}
	if(matched){
	    [ret addObject:person];
	}
    }
    delete mlist;
    return ret;
}

/* 
 * TEMPLATE STUFF
 */

- (void)readFormatFromRTFTemplate
{
    [myText	setRtfdData:[self RTFTemplate]];
    
    [myText	setSelectedRange:NSMakeRange(0,0)];
    
    firstLineFont	= [myText font];
    firstLineAlignment	= [myText alignment];
    
    [myText	setSelectedRange:[myText getParagraphRange:1]];
    
    secondLineFont	= [myText font];
    secondLineAlignment	= [myText alignment];
}


/****************************************************************
 ** Statistics
 ****************************************************************/

- (NSString *)mostCommonUsername
{
    Histogram *hist = [Histogram histogram];
    NSEnumerator *en = [people objectEnumerator];
    Person *person;

    if([people count]==0) return @"";	// there is no most common username

    while(person = [en nextObject]){
	[hist tallyObject:[person cusername]];
	[hist tallyObject:[person musername]];
    }

    return [hist mostCommonObject];
}

- (int)mostCommonSortKey
{
    Histogram *hist = [Histogram histogram];
    NSEnumerator *en = [people objectEnumerator];
    Person *person;

    while(person = [en nextObject]){
	[hist tallyObject:[NSNumber numberWithInt:[person sortKey]]];
    }
    return [[hist mostCommonObject] intValue];
}
    
- (unsigned int)mostCommonFlags
{
    Histogram *hist = [Histogram histogram];
    NSEnumerator *en = [people objectEnumerator];
    Person *person;

    while(person = [en nextObject]){
	[hist tallyObject:[NSNumber numberWithUnsignedInt:[person flags]]];
    }
    return [[hist mostCommonObject] unsignedIntValue];
}


@end
