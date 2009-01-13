/*
 * SList_xmlread.m:
 * Reads an SBookXML file using XPat.
 * Returns an AutoRelease SList 
 */

#import <Cocoa/Cocoa.h>

#import "xmlparse.h"
#import "SList.h"
#import "Person.h"
#import "XMLArchiver.h"
#import "EncryptedObject.h"
#import "base64.h"
#import "tools.h"
#import "PassphrasePanel.h"
#import "SBookController.h"
#import "DefaultSwitchSetter.h"

/* the data structure used for the reader */
struct SBookXML {
    SList	*list;			// list we are building
    Person	*person;		// person we are reading
    NSData	*person_text_MD5;	// the person_text_md5
    EncryptedObject *eobj;		// encrypted object we are consing
    NSMutableData *buf;			// buffer for data we just read
    NSMutableDictionary *refreshGids;	// all of the GIDs, when we are doing a refresh
    
    int depth;
    int list_flags;			// set at end to prevent sorting on each addition
    int process;			// do we want this element?

    SList	*refresh;		// are we refreshing another SList ?
    int v_major,v_minor,v_build;	// version numbers
    BOOL drop_ascii;			// do we need to drop ascii? Yes if input is before 5.1.006

};


/* These are the keys for the individual types */
static NXAtom sbookversion_;
static NXAtom entries_;
static NXAtom entrycount_;
static NXAtom frame_;
static NXAtom divider_;
static NXAtom flags_;
static NXAtom searchmode_;
static NXAtom template_;
static NXAtom rtftemplate_;
static NXAtom defaultsortkey_;
static NXAtom defaultpersonflags_;
static NXAtom defaultusername_;
static NXAtom searchentrymode_;
static NXAtom filecreationdate_;
static NXAtom columnOneMode_;
static NXAtom deletedpeople_;
static NXAtom delent_;			// entry within a hashtable

/* Entries */
static NXAtom entry_;
static NXAtom t_;			// depricated
static NXAtom text_;
static NXAtom textmd5_;			// ignored
static NXAtom textMD5_;			// the real ones
static NXAtom entrySN_;
static NXAtom rtfd_;
static NXAtom gid_;
static NXAtom sk_;
static NXAtom ctime_;
static NXAtom mtime_;
static NXAtom atime_;
static NXAtom spf_;
static NXAtom cuser_;
static NXAtom muser_;

static NXAtom EncryptedObject_;
static NXAtom edata_;
static NXAtom length_;
static NXAtom md5_;

static NXAtom syncsource_;
static NXAtom syncuid_;
static NXAtom synctime_;
static NXAtom syncmtime_;
static NXAtom syncmd5_;

#define isentry(x) (x[0]=='e' && x[1]=='n' && x[2]=='t' && x[3]=='r' && x[4]=='y' && x[5]=='\000')

/* catgory */
@interface NSData(XMLReader)
-(int)intValue;
-(float)floatValue;
@end



@implementation NSData(XMLReader)
-(int)intValue
{
    const char *buf = (const char *)[self bytes];
    int  len  = [self length];
    int  sum  = 0;
    int  i;

    for(i=0;i<len;i++){
	char c = buf[i];
	if(c>='0' && c<='9'){
	    sum = (sum*10) + buf[i]-'0';
	}
	else{
	    if(sum!=0) break;		// we had data and we don't know
	}
    }
    return sum;
}

-(float)floatValue
{
    return [[self stringWithUTF8Encoding] floatValue];
}

@end

static int initialized = 0;
void initialize_parser()
{
    if(initialized) return;

    sbookversion_ = NXUniqueString("sbookversion");
    entries_	= NXUniqueString("entries");
    entrycount_	= NXUniqueString("entrycount");
    frame_	= NXUniqueString("frame");
    columnOneMode_= NXUniqueString("columnonemode");
    deletedpeople_= NXUniqueString("deletedpeople");
    delent_= NXUniqueString("delent");
    divider_	= NXUniqueString("divider");
    flags_	= NXUniqueString("flags");
    searchmode_	= NXUniqueString("searchmode");
    template_	= NXUniqueString("template");
    rtftemplate_= NXUniqueString("rtftemplate");
    defaultsortkey_ = NXUniqueString("defaultsortkey");
    defaultpersonflags_ = NXUniqueString("defaultpersonflags");
    defaultusername_ = NXUniqueString("defaultusername");
    searchentrymode_ = NXUniqueString("searchentrymode");
    entrycount_ = NXUniqueString("entrycount");
    entry_	= NXUniqueString("entry");
    filecreationdate_ = NXUniqueString("filecreationdate");


    t_		= NXUniqueString("t");
    text_	= NXUniqueString("text");
    textmd5_	= NXUniqueString("textmd5");
    textMD5_	= NXUniqueString("textMD5");
    rtfd_	= NXUniqueString("rtfd");
    gid_	= NXUniqueString("gid");
    sk_		= NXUniqueString("sk");
    ctime_	= NXUniqueString("ctime");
    mtime_	= NXUniqueString("mtime");
    atime_	= NXUniqueString("atime");
    spf_	= NXUniqueString("spf");
    cuser_	= NXUniqueString("cuser");
    muser_	= NXUniqueString("muser");
    entrySN_	= NXUniqueString("entrysn");
    syncsource_ = NXUniqueString("syncsource");
    syncuid_    = NXUniqueString("syncuid");
    synctime_   = NXUniqueString("synctime");
    syncmtime_  = NXUniqueString("syncmtime");
    syncmd5_    = NXUniqueString("syncmd5");

    EncryptedObject_ = NXUniqueString("EncryptedObject");
    edata_	= NXUniqueString("edata");
    length_	= NXUniqueString("length");
    md5_	= NXUniqueString("md5");
    initialized=1;
}


void startDoc(void *userData,const XML_Char *doctypeName)
{
}

void endDoc(void *userData)
{
}

/* Handle the data between tags */
void characterDataHandler(void *userData,const XML_Char *s,int len)
{
    struct SBookXML *data = (struct SBookXML *)userData;

    if(data->buf==nil && data->process!=0){
	data->buf	= [[NSMutableData alloc] init];
    }
    if(data->buf){
	[data->buf appendBytes:s length:len];
    }
}

void startElement(void *userData, const char *name_, const char **atts)
{
    struct SBookXML *data = (struct SBookXML *)userData;
    SList *slist=data->list;
    const char *name=0;

    data->depth ++;
    if(data->buf){
	[data->buf release];
	data->buf   = 0;
    }
    data->process = 1;			// by default, do not ignore the element

    /* Special stuff that needs to be done at the beginning of an element */
    switch(data->depth){
    case 1:				// outermost
	name = NXUniqueString(name_);
	data->process   = 1;		// keep all top level elements
	if(name == entries_){
	    data->list = [[[SList alloc] init] autorelease]; // create a new list!
	    [data->list setFlags:0];	// reset all flags, we'll read them later
	    return;
	}
	if(name == EncryptedObject_){
	    data->eobj = [[[EncryptedObject alloc] init] autorelease];
	    return;
	}
	return;
    case 2:				// inside <entries>

	if(isentry(name_)){
	    NSString *gid=nil;		// gid for this person
	    unsigned int entrySN=0;		// sn for this person

	    /* Pick up the attributes */
	    while(*atts){
		if(!strcmp(atts[0],"gid")){
		    gid = [NSString stringWithUTF8String:atts[1]];
		}
		else if(!strcmp(atts[0],"entrysn")){
		    entrySN = atoi(atts[1]);
		}
		atts+=2;
	    }

	    /* If we are refreshing */
	    if(data->refresh){

		/* Get the person who matches who is being refreshed */
		Person *per = [data->refresh personWithGid:gid];

		/* Remove from the refreshGids */
		[data->refreshGids removeObjectForKey:gid];

		if(per){		// this person already exists
		    if([per entrySN]==entrySN){
			data->process = 0;	 // don't grab the data
			data->person  = nil; // don't remember the person
			return;
		    }
		    
		    /* Otherwise, turn on reading and set the person we are reading
		     * to be the person from the slist... (forget the text.)
		     */
		    data->process = 1;
		    data->person = per;
		    [data->person
			 setAsciiData:[NSData data]
			 releaseRtfdData:YES
			 andUpdateMtime:NO];
		    return;
		}
	    }
	    /* If we are not refreshing, or if we are refreshing and this is a newperson,
	     * just create this person and get ready to roll
	     */
	    data->person = [[[Person alloc] init] autorelease]; // create a new person!
	    [data->person setGid:gid];
	    [data->person setEntrySN:entrySN];

	    if(data->refresh){
		[data->refresh addPerson:data->person];
	    }
	    else{
		[slist addPerson:data->person]; // add to the list if we are not refreshing
	    }
	    return;
	}
	return;
    case 3:				// inside the <entry> or deletedpeople
	name = NXUniqueString(name_);
	if(name==delent_){
	    NSString *name=nil;
	    NSNumber *value=nil;
	    while(*atts){
		if(!strcmp(atts[0],"key")){
		    name  = [NSString stringWithUTF8String:atts[1]];
		}
		else if(!strcmp(atts[0],"value")){
		    value = [NSNumber numberWithInt:atoi(atts[1])];
		}
		atts+=2;
	    }
	    if(name && value){
		[[slist deletedGIDs] setObject:value forKey:name];
	    }

	    /* Handle the delent */
	    return;
	}
	if(data->person==0){
	    data->process=0;
	    return;	// we are not remembering the person, so don't remember
	}
	data->process=1;		// get the data
    default:				// default case
	break;
    }
}

void endElement(void *userData, const char *name_)
{
    struct SBookXML *data = (struct SBookXML *)userData;
    const char *name      = 0;
    SList *slist          = data->list;

    if(data->depth==1 && NXUniqueString(name_)==entries_){
	/* End of the <entries> */
	if(data->refresh){
	    /* If we are refreshing, remove entries that were not referenced */
	    NSEnumerator *en = [data->refreshGids keyEnumerator];
	    id obj;

	    while(obj = [en nextObject]){
		Person *person = [data->refresh personWithGid:obj];
		[person	setFlag:ENTRY_DELETED_FLAG toValue:YES]; // note that it was deleted
		[data->refresh removePerson:person];
	    }
	}
    }
    if(data->depth==2 && isentry(name_)){
	Person *person = data->person;

	/* If person got no asciiString and no rtfdData, this person is worthless. */
	if([person hasAsciiString]==NO and [person hasRtfdData]==NO){
	    NSLog(@"this person has no ASCII and no RTFD; discarding...");
	    [slist removePerson:person];
	    goto done;
	}

	/* End of Person <entry> --- clean up the entry */

	/* If musername is not set, it is defaultusername */
	if([person musername]==nil){
	    [person setMusername:[slist defaultUsername]];
	}

	/* If we have an musername but not a cusername, set the cusername to be the musername */
	if([person musername]!=nil && [person cusername]==nil){
	    [person setCusername:[person musername]];
	}

	/* If we do not have a sort key, set to the default */
	if([person sortKey]==0){
	    [person setSortKey:[slist defaultSortKey]];
	}

	/* If we do not have a flags, set to the default */
	if([person flags]==0){
	    [person setFlags:[slist defaultPersonFlags]];
	}

	/* If we have an atime but not mtime, set the mtime to be the atime */
	if([person atime]==0 && [person mtime]!=0){
	    [person setMtime:[person atime]];
	}

	/* If we have an mtime but not ctime, set the ctime to be mtime */
	if([person mtime]==0 && [person ctime]!=0){
	    [person setCtime:[person mtime]];
	}

	/* If we have a textmd5 and the textmd5 doesn't validate, throw away
	 * the rtfd, as the text was modified.
	 */
	if(data->person_text_MD5){

	    if([[person asciiMD5] isEqual:data->person_text_MD5]==NO){
		NSLog(@"SList_xmlread: Discarding RTFD for %@ as ASCII was modified",
		      person);
		[person discardRtfdData];
	    }

	    /* Finally, clear the text_md5 */
	    [data->person_text_MD5 release];
	}

	/* If we are an old version of SBook, drop the ASCII */
	if(data->drop_ascii && [person hasAsciiString] && [person hasRtfdData]){
	    [data->person discardAscii];
	    [data->person computeCellNameFromRTFDData];
	}

	data->person = nil;		// we are done with this person now
    }

    if([data->buf length]>0){		// if we got data
	switch(data->depth){
	case 2:

	    // if we are refreshing and in SList, ignore options
	    if(data->refresh && data->list) break;

	    // nothing to do for </entry>
	    if(isentry(name_)) break;	

	    name = NXUniqueString(name_);

	    /*****************************************************************
	     ** IN ENTRIES (SList)
	     ****************************************************************/
	    if(name == sbookversion_){
		sscanf([[data->buf stringWithUTF8Encoding] cString],
		       "%d.%d.%d",
		       &data->v_major,&data->v_minor,&data->v_build);
		NSLog(@"reading version %d.%d.%d",data->v_major,data->v_minor,data->v_build);
		if(data->v_major==5 && data->v_minor==1 && data->v_build>=6){
		    data->drop_ascii = NO;
		}
		break;
	    }

	    if(name == searchentrymode_ ||
	       name == entrycount_){
		break;			// we don't care about these
	    }

	    if(name == frame_){
		[slist setFrame:NSRectFromString([data->buf stringWithUTF8Encoding])];
		break;
	    }
	    if(name == columnOneMode_){
		[slist setColumnOneMode:[data->buf intValue]];
		break;
	    }
	    if(name == divider_){
		[slist setDivider:[data->buf floatValue]];
		break;
	    }
	    if(name == flags_){
		data->list_flags = [data->buf intValue];
		break;
	    }
	    if(name == searchmode_){
		[slist setSearchMode:[data->buf intValue]];
		break;
	    }

	    if(name==template_){
		[slist setAsciiTemplate:[data->buf stringWithUTF8Encoding]];
		break;
	    }
	    if(name==rtftemplate_){
		NSData *decodedData = dataForB64Data(data->buf);
		if(decodedData){
		    [slist setRTFTemplate:decodedData];
		}
		break;
	    }
	    if(name == defaultsortkey_){
		[slist setDefaultSortKey:[data->buf intValue]];
		break;
	    }
	    if(name == defaultpersonflags_){
		[slist setDefaultPersonFlags:[data->buf intValue]];
		break;
	    }
	    if(name == defaultusername_){
		[slist setDefaultUsername:[data->buf stringWithUTF8Encoding]];
		break;
	    }
		
	    if(name == filecreationdate_){
		break;			// ignored
	    }

	    if(name == deletedpeople_){
		break;			// I will handle
	    }

	    /****************************************************************
	     ** encrypted object
	     ****************************************************************/

	    if(name == edata_){
		[data->eobj setEncryptedData:dataForB64Data(data->buf)];
		break;
	    }

	    if(name == length_){
		[data->eobj setLen:[data->buf intValue]];
		break;
	    }

	    if(name == md5_ ){
		[data->eobj setMD5:dataForB64Data(data->buf)];
		break;
	    }

	    NSLog(@"unrecognized second-level XML tag: %s",name_);

	    break;

	case 3:				// within an entry
	    if(data->person == nil) break;	// we are not remembering this person; skip;
	    name = NXUniqueString(name_);
	    if(name==delent_) break;	// already handled in prologue

	    if(name==t_ || name==text_ ){
		[data->person
		     setAsciiData:data->buf
		     releaseRtfdData:NO
		     andUpdateMtime:NO];
		break;
	    }

	    if(name==textMD5_){
		data->person_text_MD5 = [dataForB64Data(data->buf) retain];
	    }

	    if(name==rtfd_ ){
		[data->person setB64RTFDData:data->buf];
		break;
	    }
	    if(name==gid_){
		[data->person setGid:[data->buf stringWithUTF8Encoding]];
		break;
	    }
	    if(name==entrySN_){
		[data->person setEntrySN:[data->buf intValue]];
		break;
	    }
	    if(name==sk_){
		[data->person setSortKey:[data->buf intValue]];
		break;
	    }
	    if(name==ctime_){
		[data->person setCtime:[data->buf intValue]];
		break;
	    }
	    if(name==atime_){
		[data->person setAtime:[data->buf intValue]];
		break;
	    }
	    if(name==mtime_){
		[data->person setMtime:[data->buf intValue]];
		break;
	    }
	    if(name==flags_){
		[data->person setFlags:[data->buf intValue]];
		break;
	    }
	    if(name==cuser_){
		[data->person setCusername:[data->buf commonStringWithUTF8Encoding]];
		break;
	    }
	    if(name==muser_){
		[data->person setMusername:[data->buf commonStringWithUTF8Encoding]];
		break;
	    }
	    
	    if(name==syncsource_){
		[data->person setSyncSource:[data->buf commonStringWithUTF8Encoding]];
		break;
	    }
	    if(name==syncuid_){
		[data->person setSyncUID:[data->buf stringWithUTF8Encoding]];
		break;
	    }
	    if(name==synctime_){
		[data->person setSyncTime:[data->buf intValue]];
		break;
	    }
	    if(name==syncmtime_){
		[data->person setSyncMtime:[data->buf intValue]];
		break;
	    }
	    if(name==syncmd5_){
		[data->person setSyncMD5:dataForB64Data(data->buf)];
		break;
	    }
	}
    }

 done:;
    if(data->buf){
	[data->buf release];
	data->buf = 0;			// will be automatically released
    }
    data->depth --;
}

SList *SList_xmlread(NSData *d,SList *refresh)
{
    XML_Parser parser = XML_ParserCreate(NULL);
    struct SBookXML data;

    d = [d fixLineEndings];		// fix \r's
    int len		= [d length];
    const char *buf	= (const char *)[d bytes];

    if(refresh){
	NSLog(@"commented out refresh.");
	XML_ParserFree(parser);
	return nil;
    }

    initialize_parser();

    /* Check for the broken XML that Alpha 9 produced */
    if(buf[154]=='-' && buf[155]=='-' && buf[156]=='>'){

	NSMutableData *data2 = [[NSMutableData alloc] initWithData:d];
	char *mutableBytes = (char *)[data2 mutableBytes];

	mutableBytes[109]='"';
	mutableBytes[110]=' ';
	mutableBytes[154]=' ';
	mutableBytes[155]=' ';
	buf = mutableBytes;		// use this one instead, please
	[data2 release];
    }


    /* Set up the parser */
    memset(&data,0,sizeof(data));
    data.drop_ascii = YES;		// due to weird errors
    data.refresh = refresh;
    if(refresh){			// if we are refreshing, get all the GIDs
	NSArray *array   = [refresh allPeopleGids];
	NSEnumerator *en = [array objectEnumerator];
	id obj;

	data.refreshGids = [NSMutableDictionary dictionary];

	while(obj = [en nextObject]){
	    [data.refreshGids setObject:obj forKey:obj]; // list of the GIds
	}
    }

    XML_SetUserData(parser, &data);
    XML_SetDoctypeDeclHandler(parser, startDoc, endDoc);
    XML_SetElementHandler(parser, startElement, endElement);
    XML_SetCharacterDataHandler(parser,characterDataHandler);

    if (!XML_Parse(parser, buf, len, 1)) {
	NSRunAlertPanel(@"xml expat",
			@"%s at line %d\n",
			nil,nil,nil,
			XML_ErrorString(XML_GetErrorCode(parser)),
			XML_GetCurrentLineNumber(parser));
	return nil;
    }
    XML_ParserFree(parser);

    //extern long nxatom_from_cache;
    //extern long nxatom_alloc;
    // printf("nxatom_from_cache = %ld  nxatom_alloc=%ld\n",nxatom_from_cache,nxatom_alloc);

    /* If we got an SList, set it up and return it */
    if(data.list){
	[data.list setFlags:data.list_flags]; // now set the flags; will sort if needed
	return data.list;
    }

    /* IF we got an encrypted object, try to decrypt it */
    while(data.eobj){
	NSData *plaintext=nil;
	NSData *key=nil;
	
	/* If we are refreshing, grab the key from the refresh */
	if(refresh){
	    key = [refresh encryptionKey];
	}
	else {
	    PassphrasePanel *pan = [AppDelegate passphraseEnterPanel];
	    if([pan run]){
		key = [pan key];
	    }
	    else{
		return nil;		// user gave up
	    }
	}
	
	/* See if we can decrypt */
	plaintext = [data.eobj decryptWithKey:key];
	if(plaintext){
	    /* We have a decrypted data. Remember the key and
	     * return the decrypted data.
	     */
	    SList *ret = SList_xmlread(plaintext,refresh);
	    if(ret){
		[ret setEncryptionKey:key];
		return ret;
	    }
	}
	
	/* Decrypt must have failed */
	/* Decrypt with the provided passphrase */
	NSRunAlertPanel(@"Decrypt Failed",
			@"I am sorry, that is not a valid passphrase.",
			nil,nil,nil);
	refresh = nil;			// don't try to use the refresh key
    }
    return nil;				// not sure what we got
}
