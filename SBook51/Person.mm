/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2001, 2002, 2003 by Simson L. Garfinkel
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law.
 *
 */

#import "Person.h"
#import "XMLCoder.h"
#import "metaphone.h"
#import "SList.h"
#import "tools.h"
#import "base64.h"

NSString *myUserName=0;
static NSTextView *myText = 0;



/* Context required for AppKit */
extern "C"
int PersonSortFun(Person *p1,Person *p2,void *context)
{
    int ret;
    ret =  compareAtomLists([p1 cellNames],[p1 sortName],
			    [p2 cellNames],[p2 sortName]);
    return ret;
}

@implementation Person

+(void)initialize
{
    myUserName		= [[NSString stringWithUTF8String:getenv("USER")] retain];
    myText		= [[NSTextView alloc] init]; // for finding the first line
}

+(NSString *)SBookAsciiForPeople:(NSArray *)arrayOfPeople
{
    NSMutableString *ret = [[NSMutableString alloc] init];
    NSEnumerator *en = [arrayOfPeople objectEnumerator];
    BOOL first=YES;

    while(Person *person = [en nextObject]){
	if(!first){
	    [ret appendString:@"=======================\n"];
	}
	first = NO;
	[ret appendString:[person asciiString]];
    }
    return ret;
}

+(NSString *)vCardForPeople:(NSArray *)arrayOfPeople
{
    NSMutableString *ret = [[NSMutableString alloc] init];
    NSEnumerator *en = [arrayOfPeople objectEnumerator];

    while(Person *person = [en nextObject]){
	[ret appendString:[person vCard:YES]];
    }
    return ret;
}


+ (NSString *)findZip:(NSString *)text
{
    int len = 0;
    const char *ret;
    char *buf;

    ret = find_zip([text lossyCString],&len);
    if(!ret) return nil;

    buf = (char *)alloca(len+1);
    memcpy(buf,ret,len);
    buf[len] = '\000';

    return [NSString stringWithCString:buf];
}




/* designated initializer */
-initForRTFDData:(NSData *)newData sortKey:(int)sKey
{
	
    [super	init];
    [self	setRTFDData:newData andUpdateMtime:YES];
    [self	setSortKey:sKey];

    c_time	= time(0);
    atime	= c_time;
    mtime	= c_time;

    [self	setCusername:myUserName];
    [self	setFlag:ENTRY_SHOULD_PARSE_FLAG toValue:YES];
    [self	newGID];
    return self;
}

-init
{
    return [self initForRTFDData:nil sortKey:ENTRY_SMART_SORT_TAG];
}

- (oneway void)dealloc
{
    [rtfdData release];		rtfdData =nil;
    [cellName release];		cellName = nil;
    [cellNameLF release];	cellNameLF = nil;
    [lastName release];		lastName = nil;
    [firstName release];	firstName = nil;

    [asciiString release];	asciiString = nil;
    [asciiLines  release];	asciiLines = nil;
    if(names) 		{delete names;names=0;            }
    if(metaphones)	{delete metaphones;metaphones=0;  }
    if(tp)              {[NSTextView freeParagraphs:tp];tp=0; }
    if(results)		{free(results);results = 0;       }
    
    [super dealloc];
}


- (int)compareTo:(Person *)aPerson	// runs PersonSortFun(self,aPerson)
{
    return PersonSortFun(self,aPerson,0);
}

/****************************************************************
 *** PersonFlat went here
 ****************************************************************/

- (void)touch
{
    [self  setMusername:myUserName];
    [self setMtime:time(0)];
    entrySN++;
    return;				// implemented by higher-level
}

- (void)newGID
{
    // start with a random GID

    if(gid) [gid release];
    gid		= [[NSString stringWithFormat:@"%x-%x",time(0),random()] retain]; 
}


/* Coder */
- (id)initWithCoder:(NSCoder *)coder
{
    int version;

    version  = [[coder decodeObject] unsignedIntValue];
    flags    = [[coder decodeObject] unsignedIntValue];
    sortKey  = [[coder decodeObject] intValue];
    c_time   = [[coder decodeObject] intValue];
    mtime    = [[coder decodeObject] intValue];
    atime    = [[coder decodeObject] intValue];
    calltime = [[coder decodeObject] intValue];
    envtime  = [[coder decodeObject] intValue];
    emailtime= [[coder decodeObject] intValue];
    gid      = [[coder decodeObject] retain];
    entrySN  = [[coder decodeObject] unsignedIntValue];
    [(Person *)self	setCellName:[coder decodeObject]];
    asciiString= [[coder decodeObject] retain];
    rtfdData = [[coder decodeObject] retain];
    cusername= [[coder decodeObject] retain];
    musername= [[coder decodeObject] retain];
    syncSource = [[coder decodeObject] retain];
    syncUID = [[coder decodeObject] retain];
    syncTime = [[coder decodeObject] intValue];
    syncMtime = [[coder decodeObject] intValue];
    syncMD5   = [[coder decodeObject] retain];
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    NSNumber *Nenvtime   = [NSNumber numberWithInt:envtime];
    NSNumber *Nemailtime = [NSNumber numberWithInt:emailtime];
    NSNumber *NentrySN   = [NSNumber numberWithUnsignedInt:entrySN];

    [coder encodeObject:[NSNumber numberWithUnsignedInt:1]];
    [coder encodeObject:[NSNumber numberWithUnsignedInt:flags]];
    [coder encodeObject:[NSNumber numberWithInt:sortKey]];
    [coder encodeObject:[NSNumber numberWithInt:c_time]];
    [coder encodeObject:[NSNumber numberWithInt:mtime]];
    [coder encodeObject:[NSNumber numberWithInt:atime]];
    [coder encodeObject:[NSNumber numberWithInt:calltime]];
    [coder encodeObject:Nenvtime];
    [coder encodeObject:Nemailtime];
    [coder encodeObject:gid];
    [coder encodeObject:NentrySN];
    [coder encodeObject:cellName];
    [coder encodeObject:asciiString];
    [coder encodeObject:rtfdData];
    [coder encodeObject:cusername];
    [coder encodeObject:musername];
    [coder encodeObject:syncSource];
    [coder encodeObject:syncUID];
    [coder encodeObject:[NSNumber numberWithInt:syncTime]];
    [coder encodeObject:[NSNumber numberWithInt:syncMtime]];
    [coder encodeObject:syncMD5];
}


/****************************************************************
  ACCESSOR METHODS
 ****************************************************************/

- (NSString *)cusername		{ return cusername;		}
- (NSString *)musername		{ return musername;		}

- (unsigned long)flags			  { return flags;			}
- (void)addFlag:(unsigned long)aFlag	  { flags	|= aFlag;               }
- (void)setFlags:(unsigned long)newFlags  { flags = newFlags | ENTRY_FLAGS_SET; }
- (void)setFlag:(unsigned long)mask toValue:(BOOL)aValue
{
    flags = (flags & ~mask) | (aValue ? mask : 0) | ENTRY_FLAGS_SET;
}
- (void)removeFlag:(unsigned long)fg	{ flags &= ~fg;			}
- (BOOL)queryFlag:(unsigned long)mask	{
    int ret = flags & mask ? YES : NO;
    return ret;
}


/* Accessors for actions */

- (time_t)ctime 		{ return c_time;		}
- (time_t)mtime 		{ return mtime; 		}
- (time_t)atime 		{ return atime; 		}
- (time_t)calltime		{ return calltime; 		}
- (time_t)envtime 		{ return envtime;	 	}
- (time_t)emailtime		{ return emailtime;	 	}
- (unsigned int)entrySN { return entrySN;}
- (void)setEntrySN:(unsigned int)val {entrySN = val;}
- (NSData *)syncMD5		{return syncMD5;}

- (NSString *)gid		{ return gid;	}
- (void)setGid:(NSString *)gid_
{
    if(gid!=gid_){
	[gid release];
	gid = [gid_ retain];
    }
}


- (void)setCtime:(time_t)t	{ c_time = t;	}
- (void)setAtime:(time_t)t	{ atime = t;	}
- (void)setMtime:(time_t)t	{ mtime = t;	}

- (void)setCusername:(NSString *)str
{
    if(str!=cusername){
	[cusername release];
	cusername = [str retain];
    }
}


- (void)setMusername:(NSString *)str
{
    if(str!=musername){
	[musername release];
	musername = [str retain];
    }
}

- (void)setSyncTime:(time_t)t { syncTime = t;}
- (void)setSyncMtime:(time_t)t { syncMtime = t;}
- (void)setSyncSource:(NSString *)str
{
    if(syncSource!=str){
	[syncSource release];
	syncSource = [str retain];
    }
}


- (void)setSyncUID:(NSString *)str
{
    if(syncUID != str){
	[syncUID release];
	syncUID = [str retain];
    }
}

- (time_t)syncTime {return syncTime;}
- (time_t)syncMtime {return syncMtime;}
- (NSString *)syncSource { return syncSource;}
- (NSString *)syncUID { return syncUID;}

- (void)setSyncMD5:(NSData *)d
{
    if(syncMD5 != d){
	[syncMD5 release];
	syncMD5 = [d retain];
    }
}


- (void)setDoc:(SList *)aDoc
{
    doc = aDoc;
}





/****************************************************************
 ** SMART DATA ACCESSORS.
 ** Person can maintain data in ASCII or RTF representation (or both!)
 ** If we have RTF and they ask for asciiString, do the conversion.
 ** We can't convert the other way, though, because we don't know the template.
 **/
 

- (BOOL) hasRtfdData
{
    if(rtfdData || base64RtfdData) return YES;
    return NO;
}

- (BOOL) hasAsciiString
{
    return asciiString ? YES : NO;
}

- (NSString *)asciiString
{
    if(!asciiString){
	/* make the asciiString */
	[myText setRtfdData:[self rtfdData]];
	asciiString = [[myText string] copy];
	[self fixAscii];			// make sure it is good
    }
    return [[asciiString copy] autorelease];
}

- (NSData *)asciiMD5
{
    //NSLog(@"Person.mm: computing md5 on '%@'",[self asciiString]);
    return [[[self asciiString] dataUsingEncoding:NSUTF8StringEncoding] md5];
}

- (NSData *)rtfdMD5
{
    return [[self rtfdData] md5];
}

/****************************************************************/
								 

/*
 * applyTemplateToMyTextAndCopyOutRtfData:
 * Used for turning ascii->RTF.
 * Applies format of first line to the first line and
 * format of the second line to the remaining lines.
 */
- (void)applyTemplateToMyTextAndCopyOutRtfData
{
    NSRange r;
    NSTextStorage   *ts = [myText textStorage];
    int len = [ts length];
    NSRange allRange = NSMakeRange(0,len);
    NSRange halfRange = NSMakeRange(len/2,len/2);

    /* First, remove the background color */
    [ts removeAttribute:NSParagraphStyleAttributeName  range:allRange];
    [ts removeAttribute:NSBackgroundColorAttributeName range:allRange];
    [ts removeAttribute:NSForegroundColorAttributeName range:allRange];
    [ts addAttribute:NSForegroundColorAttributeName
	value:[NSColor blackColor] range:allRange];

    /* Now apply the first line font */
    [myText setFont:[doc firstLineFont]];

    r = [myText secondLineToEnd];
    if(r.location>0 && r.length>0){
	[myText setFont:[doc secondLineFont] range:r];
    }
    rtfdData = [[myText rtfdData] retain];
    [self setFlag:ENTRY_NEEDS_TEMPLATE_APPLIED_FLAG toValue:NO]; // because we just applied it
}

/*
 * - rtfdData:
 * Return the RTFDdata
 */

- (NSData *)rtfdData
{
    /* If we have b64rtfddata and no rtfddata, then convert the b64 data to rtfddata */
    if(rtfdData==nil && base64RtfdData){
	rtfdData = [dataForB64Data(base64RtfdData) retain];
    }

    if(rtfdData){
	/* Apply the template if necessary */
	if([self queryFlag:ENTRY_NEEDS_TEMPLATE_APPLIED_FLAG]){
	    [myText setRtfdData:rtfdData];
	    [self   applyTemplateToMyTextAndCopyOutRtfData];
	}
	return rtfdData;
    }

    if(asciiString==0){
	NSLog(@"Person.mm: Something wrong: no ascii nor RTFD for person!");
	asciiString = @"";		// stopgap
    }

    /* Convert the asciiString into an rtfData, applying the
     * template if possible.
     */
    [myText setString:asciiString];
    [self  applyTemplateToMyTextAndCopyOutRtfData];

    return rtfdData;
}

/* discardAscii: */
- (void)discardAscii
{
    if([self hasRtfdData]){
	[asciiString release];
	asciiString = 0;
    }
}

/* discardFormatting:
 * Set the flag on this object that it needs the template applied.
 * The template will be applied when it is loaded in.
 * We can't just discard the rtfdData because there might actually be
 * an embedded object or something.
 */
- (void)discardFormatting
{
    [self setFlag:ENTRY_NEEDS_TEMPLATE_APPLIED_FLAG toValue:YES];
}

- (void)discardRtfdData
{
    if(asciiString){
	[rtfdData release];
	rtfdData = nil;

	[base64RtfdData release];
	base64RtfdData = nil;
    }
}

/****************************************************************/



- (void)updateAccessTime
{
    atime = time(0);
}


-(void)telephoned
{
    calltime = time(0);
}

- (void)emailed
{
    emailtime = time(0);
}

- (void)enveloped
{
    envtime = time(0);
}

/* Make sure that EOLs are \n's.
 *  - Remove any \r's
 *  - Remove any \n's at the end
 *  - If the entry doesn't end with a single \n, make it end with one.
 * designed to be fast.
 */
- (void)fixAscii
{
    NSAssert(asciiString!=0,@"fixAscii called when asciiString was nil?");
    unsigned int length = [asciiString length];
    if(length==0){
	NSLog(@"0 length ascii fixed");
	[asciiString release];
	asciiString = @"\n";
	return;
    }

    /* If the last character is not a \n, add it */
    if([asciiString characterAtIndex:length-1]!='\n'){
	NSString *newString = [asciiString stringByAppendingString:@"\n"];
	[asciiString release];
	asciiString = [newString retain];
	length = [asciiString length];	// changed
	NSLog(@"appended newline to %@",self);
    }
	    

    while(length>1){			// if length==1, it ends with a \n

	/* kill all \n's at end until it the lastchar is not a \n */

	unichar lastchar = [asciiString characterAtIndex:length-1];
	unichar prevchar = [asciiString characterAtIndex:length-2];

	if(lastchar=='\n' && prevchar!='\n') return; // it's fine

	
	NSString *newString = [asciiString substringWithRange:NSMakeRange(0,length-1)];
	[asciiString release];
	asciiString = [newString retain];
	length = [asciiString length];	// changed
    }
}

/* setASCIIData:
 * We can also have the ascii string set.
 * If it is, then the RTFData is not valid (needs to have the template applied.)
 */
- (void)setAsciiData:(NSData *)data releaseRtfdData:(BOOL)releaseRtfdData
      andUpdateMtime:(BOOL)updateFlag
{
    NSRange firstLineRange;

    /* First, get rid of the old stuff */
    if(releaseRtfdData){
	[rtfdData release];
	rtfdData = nil;

	[base64RtfdData release];
	base64RtfdData = nil;
    }

    [self releaseParsedData];

    /* Now make a copy with UTF8 encoding */
    [asciiString release];
    asciiString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self fixAscii];

    if(updateFlag) [self touch];

    /* And set the cellname */
    firstLineRange = [asciiString rangeOfString:@"\n"];
    if(firstLineRange.location==NSNotFound){
	[self setCellName:asciiString];
    }
    else {
	[self setCellName:[asciiString substringToIndex:firstLineRange.location]];
    }
}

/*
 * setRTFDData -
 * sets the rtf data and the cell name.
 * If the rtfdData hasn't changed, don't update.
 */

- (void)setRTFDData:(NSData *)newData andUpdateMtime:(BOOL)updateFlag
{
    if(rtfdData && [rtfdData isEqual:newData]){
	// has not changed
	return;
    }

    /* First, get rid of the old stuff */
    [rtfdData		release];	rtfdData = nil;
    [base64RtfdData	release];	base64RtfdData = nil;
    [self		releaseParsedData];

    [asciiString release]; asciiString = nil;
    
    /* Now retain the data being passed in. (it better not be mutable! */
       
    rtfdData = [newData retain];
    [self computeCellNameFromRTFDData];
    if(updateFlag)	[self touch];
}

- (void)computeCellNameFromRTFDData
{
    /* And get the first line for the CellName */
    if(rtfdData==nil && base64RtfdData==nil && asciiString==nil){
	[self setCellName:@""];
	return;
    }

    [myText setRtfdData:[self rtfdData]];
    [self setCellName:[myText getParagraph:0]];
}



- (void)setB64RTFDData:(NSData *)newB64Data // always releases ASCII and does not update MTime
{
    [base64RtfdData release];
    base64RtfdData = [newB64Data retain];

    [rtfdData release];
    rtfdData = nil;
}

- (NSData *)base64RtfdData
{
    NSData *rd;
    int len;
    NSMutableData *b64Data;

    if(base64RtfdData) return base64RtfdData;

    rd = [self rtfdData];

    /* Create b64RtfdData from rtfdData */
    /* Dump as base64 */
    b64Data = [[NSMutableData alloc] initWithLength:[rd length]*2+64];
    len = b64_ntop((const unsigned char *)[rd bytes],[rd length],
		   (char *)[b64Data mutableBytes],[b64Data length]);
    [b64Data setLength:len];
    base64RtfdData = b64Data;
    return base64RtfdData;
}


/****************************************************************
 *** SEARCH
 ****************************************************************/

- (BOOL)hasText:(NSString *)text options:(unsigned)opts
{
    NSRange r = [[self asciiString] rangeOfString:text options:opts];

    return r.location != NSNotFound;
}

// number of times the text is in the string
- (int)hasTextCount:(NSString *)text options:(unsigned)opts
{
    int count = 0;
    NSString *str = [self asciiString];
    int len = [str length];

    if([str length]>0 && [text length]>0){
	NSRange r;
	int pos = 0;

	do {
	    r = [str rangeOfString:text options:opts
		     range:NSMakeRange(pos,len-pos)];
	    if(r.length>0){
		count++;
		pos = r.location + r.length; // start next search
	    }
	} while(r.length>0);
    }
    return count;
}

// does both rich and non-rich
- (void)replaceText:(NSString *)search withText:(NSString *)replace options:(unsigned)opts
{
#if 0
    if([self hasRtfdData]==NO || 1){
	/* NO RTF Data. Just modify the Ascii String */
	NSMutableString *newString = [asciiString mutableCopy];
	[asciiString release];
	[newString replaceOccurancesOfString:search
		   withString:replace options:opts
		   range:NSMakeRange(0,[newString length])];
	asciiString = newString;
	[self touch];
	return;
    }
    /* Modify the data instead */

    [myText setString:[self rtfdData]];
    NSString *str2 = [myText string];

    NSString *str = [self asciiString];
    int len = [str length];

    if([str length]>0 && [text length]>0){
	NSRange r;
	int pos = 0;

	do {
	    r = [str rangeOfString:text options:opts
		     range:NSMakeRange(pos,len-pos)];
	    if(r.length>0){
		count++;
		pos = r.location + r.length; // start next search
	    }
	} while(r.length>0);
    }
#endif
}



- (void)takeInstanceVariablesFromArchivedData:(NSData *)theData
{
    NSUnarchiver *unarchiver = [[NSUnarchiver alloc] initForReadingWithData:theData];

    [self initWithCoder:unarchiver];	// copy over the instance variables

    [unarchiver release];		// get rid of the unarchiver

}




/****************************************************************
 *** XML
 ****************************************************************/
- (NSString *)xmlName		{ return @"entry";}

/* gid and entrySN are put in the attributes; the rest are put into the XML body */
- (NSString *)xmlAttributes
{
    return [NSString stringWithFormat:@"gid=\"%@\" entrysn=\"%d\"",gid,entrySN];
}


- (NSData *)xmlDocType
{
    char *type = "<!DOCTYPE entries PUBLIC \"-//Simson L. Garfinkel// DTD SBook5 //EN//XML\" "
	"\"http://www.simson.net/sbook/1.0/sbook.dtd\">\n";

    return [NSData dataWithUTF8String:type];
}


- (void)encodeWithXMLCoder:(XMLCoder *)aCoder
{
    [aCoder encodeXMLName:@"text"	stringValue:[self asciiString]];

    /* Store the XML for the text, so we can validate it on read */
    [aCoder encodeXMLName:@"textMD5"    binData:[self asciiMD5]];

    /* Don't put out the rtfd if the template needs to be applied */
    if([self hasRtfdData] &&
       [self queryFlag:ENTRY_NEEDS_TEMPLATE_APPLIED_FLAG]==NO){
	[aCoder encodeXMLName:@"rtfd"	bin64Data:[self base64RtfdData]];
    }

    /* Only put out the sort key if it is different from the default. */
    if([doc defaultSortKey]!=[self sortKey]){
	[aCoder encodeXMLName:@"sk"		unsignedIntValue:[self sortKey]];
    }
    
    /* Only put out flags if different from the default */
    if([doc defaultPersonFlags]!=[self flags]){
	[aCoder encodeXMLName:@"flags"	unsignedIntValue:[self flags]];
    }

    /* Only put out the ctime if it exists and if it is not the same as mtime */
    if(c_time && c_time!=mtime)	[aCoder encodeXMLName:@"ctime"	intValue:c_time];

    /* Only put out the mtime if it exists and is not the same as atime */
    if(mtime && mtime!=atime)	[aCoder encodeXMLName:@"atime"	intValue:mtime];

    /* Only put out the atime if it exists */
    if(atime)	[aCoder encodeXMLName:@"mtime"	intValue:atime];

    /* only put out the cusername if it is different from musername */
    if([cusername length]>0 &&
       [cusername isEqualToString:musername]==NO){
	[aCoder encodeXMLName:@"cuser" stringValue:cusername];
    }

    /* The default username stuff doesn't work in a multi-user environment;
     * always put out the musername.
     */
    if([musername length]>0 ){
	[aCoder encodeXMLName:@"muser" stringValue:musername];
    }

    /* Put out the sync source and syncTime if they are interesting */
    if(syncTime)  [aCoder encodeXMLName:@"synctime" intValue:syncTime];
    if(syncMtime) [aCoder encodeXMLName:@"syncmtime" intValue:syncMtime];
    if(syncSource && [syncSource length]>0) [aCoder encodeXMLName:@"syncsource" stringValue:syncSource];
    if(syncUID && [syncSource length]>0) [aCoder encodeXMLName:@"syncuid" stringValue:syncUID];
    if(syncMD5)   [aCoder encodeXMLName:@"syncmd5" binData:syncMD5];
}



- (int)sortKey			{ return sortKey; 		}
- (NXAtomList *)cellNames	{ return names;			}
- (NXAtomList *)metaphones	{ return metaphones;		}

- (NSString *)cellName
{
    if(cellNameLF && [[[NSUserDefaults standardUserDefaults] objectForKey:DEF_LAST_FIRST] intValue]){
	return cellNameLF;
    }
    return cellName;
}

- (NSString *)cellName:(BOOL)lastNameFirstFlag
{
    if(lastNameFirstFlag && cellNameLF) return cellNameLF;
    return cellName;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@",[super description],[self cellName]];
}

static inline uint min(uint a,uint b){return a<b?a:b;}

- (NSString *)vCard:(BOOL)withRTFD			// a vCard that corresponds to this Person
{
    char vcard[65536];

    const char  *as = [[self asciiString] UTF8String];

    parse_block_to_vcard(as,flags,vcard,sizeof(vcard));

    NSMutableString *str = [NSMutableString string];
    [str appendFormat:@"%s",vcard];
    [str appendFormat:@"UID:%@\n",[self gid]];
    if([self queryFlag:ENTRY_PRIVATE_FLAG]){
	[str appendString:@"CLASS:CONFIDENTIAL\n"];
    }
    if(withRTFD){
	SList *emptyList = [[[SList alloc] init] autorelease];

	/* Make an SList that contains just this person */
	[emptyList setNakedList:YES];	// don't encode other info
	[emptyList addPerson:self];

	[str appendString:@"X-IMAGE2:"];
	[str appendString:[[[XMLArchiver archiveXMLObject:emptyList] compress] base64]];
	[str appendString:@"\n"];
	//unsigned int pos = 0;
	//do {
	//unsigned int len = min([b64 length]-pos,64); 
	//[str appendString:[b64 substringWithRange:NSMakeRange(pos,len)]];
	//pos += len;
	//if(pos == [b64 length]){
	//[str appendString:@";\n"]; // terminate
	//}
	//else {
	//[str appendString:@"\n  "]; // don't terminate
	//}
	//} while(pos < [b64 length]);
    }
    [str appendString:@"END:VCARD\n"];
    return str;
}

- (BOOL)blankEntry
{
    NSString *str = [self asciiString];
    unsigned int  i;

    for(i=0;i<[str length];i++){
	if(isspace([str characterAtIndex:i])==0){
	    return NO;			// found a non-blank character
	}
    }
    return YES;
}

/* Note that this entry has changed */

/****************************************************************
  SORTING 
 ****************************************************************/


- (BOOL)isPerson
{
    return isPerson;
}


- setSortKey:(int)aKey
{
    sortKey = aKey;
    sortName = 0;			// figure it out again
    return self;
}

- (void)setSmartSortNameAndPersonFlag
{
    theSmartSortName = smartSortName([cellName UTF8String],flags,*names,&isPerson);
}

- (NXAtom)sortName
{
    if(sortName==0){
	if(sortKey==ENTRY_SMART_SORT_TAG){
	    sortName = theSmartSortName;
	}
	else {
	    int val = (sortKey>0) ? sortKey-1 : names->count() + sortKey;

	    if(val >= (int)names->count()) val = names->count()-1;
	    if(val<0) val=0;
	    sortName = (*names)[val];
	}
    }
    return sortName;
}


- (NSString *)lastName { return lastName ? lastName : @"";}
- (NSString *)firstName { return firstName ? firstName : @"";}

/* Undo/redo */
- (void)checkpointForUndo		// makes a copy of what we are
{
    NSUndoManager *undoManager = [doc undoManager];

    if(undoManager){
	NSData *archivedPerson = [NSArchiver archivedDataWithRootObject:self];

	[undoManager registerUndoWithTarget:self
		     selector:@selector(takeInstanceVariablesFromArchivedData:)
		     object:archivedPerson];
	[undoManager setActionName:[NSString stringWithFormat:@"changes to entry '%@'",[self cellName]]];
    }
}


-(void)setCellName:(NSString *)str
{
    //NSLog(@"enter");
    [cellName release];			// release old cell Name
    if(onlyBlankChars([str UTF8String])){
	cellName = @"--------------";
    }
    else{
	cellName = [str retain];		// worth keeping
    }

    sortName	= 0;
    /* Now find the names and the metaphone names */
    if(names){
	delete names;
    }
    names	= atomsForNames([cellName UTF8String]);
    if(metaphones){
	delete metaphones;
    }
    metaphones = metaphonesForNames([cellName UTF8String]);
    [self setSmartSortNameAndPersonFlag];			// determine the sort name


    /* Finally, if this is a person, and if we like to see lastname, firstname
     * See if we can change to that.
     */

    if(cellNameLF){
	[cellNameLF release];
	cellNameLF = 0;
    }
    if(firstName){
	[firstName release];
	firstName = 0;
    }
    if(lastName){
	[lastName release];
	lastName = 0;
    }
    if(isPerson){
	if(names->count()==0){
	    firstName = [@"" retain];
	    lastName  = [@"" retain];
	}
	if(names->count()==1){
	    lastName  = [cellName retain];
	    firstName = [@"" retain];
	}
	if(names->count()>1){
	    unsigned loc=0;

	    if(hasCommaBeforeSpace([str UTF8String],&loc)==NO){

		for(int i=[str indexOfLastPrintingCharacter]-2;i>0;i--){
		    
		    if(isspace([str characterAtIndex:i])){
			lastName  =  [[[str substringFromIndex:i+1] mutableCopy] chomp];
			firstName =  [[[str substringToIndex:i]     mutableCopy] chomp];

			cellNameLF = [[NSString stringWithFormat:@"%@, %@",lastName,firstName]
					 retain];
			break;
		    }
		}
	    }
	    else {
		/* Otherwise, and this is a hack, the last name is everything
		 * before the comma, and the first name is everything after it...
		 * (I should handle titles better.)
		 *
		 * This logic should be moved to libsbook.
		 */
		lastName  = [[str substringToIndex:loc] retain];
		firstName = [[str substringFromIndex:loc+1] retain];
	    }
	}
    }
}




/****************************************************************
 ** Parser support
 ****************************************************************/

-(void)releaseParsedData
{
    if(tp){
	[NSTextView freeParagraphs:tp];
	tp = 0;
    }
    [asciiLines release]; asciiLines = nil;
    if(results){
	free(results);
	results = 0;
    }
    parsed = NO;
}

- (void)parse
{
    [self releaseParsedData];

    /* Get the paragraphs and parse */
    [myText setString:[self asciiString]];
    tp = [myText getParagraphsWithEncoding:NSUTF8StringEncoding];

    results = (unsigned int *)calloc(tp->numLines,sizeof(int));
    parse_lines(tp->numLines,
		(const char **)tp->lines,
		0,
		tp->lineAttributes,
		results,[doc flags],[self flags]);

    /* Create the asciiLines */
    asciiLines = [[NSMutableArray array] retain];
    for(unsigned int i=0;i<tp->numLines;i++){
	[asciiLines addObject:[NSString stringWithUTF8String:tp->lines[i]]];
    }

    parsed = YES;
}

- (unsigned int)numAsciiLines
{
    if(!parsed) [self parse];
    return [asciiLines count];
}

- (NSString *)asciiLine:(unsigned int)n
{
    return [asciiLines objectAtIndex:n];
}

- (int)sbookTagForLine:(unsigned int)n
{
    if(!parsed) [self parse];
    if(!results) return 0;
    if(n >= tp->numLines) return 0;
    return results[n];
}

- (int)firstLineWithTag:(unsigned)tag	// returns first line that has the sbook tag "tag"
{
    if(!parsed) [self parse];
    for(unsigned int i=0;i<tp->numLines;i++){
	if((results[i]&P_BUT_MASK)==tag) return i;
    }
    return -1;
}

@end
