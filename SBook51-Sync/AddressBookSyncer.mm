/*
 * SList sync operations.
 * One of the problems with this is that the mtime in the Apple AddressBook entries
 * is the mod time of when the file was saved, not when the address book was updated.
 */

#import <AddressBook/AddressBook.h>
#import "ABPersonAdditions.h"
#import "DefaultSwitchSetter.h"
#import "AddressBookSyncer.h"
#import "SBookController.h"
#import "Person.h"
#import "SList.h"
#import "libsbook.h"
#import "tools.h"
#import "defines.h"
#import "SLC.h"

#include <regex.h>


NSString *defaultLabel = @"main";

/* our additions to ABPerson */

@interface NSString(Local)
-(NSString *)removeDuplicateLines;
@end

@implementation NSString(Local)
-(NSString *)removeDuplicateLines
{
    NSArray *ary = [self componentsSeparatedByString:@"\n"];
    NSMutableString *res = [NSMutableString string];
    unsigned int i;
    for(i=0;i<[ary count];i++){
	NSString *s1 = [ary objectAtIndex:i];
	NSString *s2 = (i<[ary count]-1 ? [ary objectAtIndex:i+1] : @"");
	if([s1 isEqualTo:s2]==NO){
	    [res appendString:s1];
	    [res appendString:@"\n"];
	}
    }
    return res;
}
@end



/****************************************************************/

@interface NSMutableString(RegExp)
-(void)replaceRegexp:(NSString *)regexp with:(NSString *)str;
@end

@implementation NSMutableString(RegExp)
-(void)replaceRegexp:(NSString *)regexp with:(NSString *)str
{
    regex_t r;
    regmatch_t pmatch[4];

    if(regcomp(&r,[regexp UTF8String],REG_EXTENDED)){
	NSLog(@"regcomp failed on %@",regexp);
    }
    if(regexec(&r,[self UTF8String],1,pmatch,0)==0){
	[self replaceCharactersInRange:NSMakeRange(pmatch[0].rm_so,
						   pmatch[0].rm_eo - pmatch[0].rm_so)
	      withString:str];
    }
    regfree(&r);
}
@end


@implementation AddressBookSyncer

+ (void)initialize
{
    NSMutableDictionary *appDefs= [NSMutableDictionary dictionary];

    [appDefs setObject:@"0" forKey:DEF_SBOOK_DELETES_ABADDRESSBOOK];
    [appDefs setObject:@"0" forKey:DEF_SBOOK_AUTOSYNC];
    [defaults registerDefaults:appDefs];
}

- init
{
    [super init];
    ab  = [ABAddressBook sharedAddressBook];
    sbc = (SBookController *)[NSApp delegate];
    [self setMyAddressBookName];
    return self;
}

- (void)dealloc
{
    [ab		release];
    [myAddressBookName release];
    [super	dealloc];
}


- (void)setMyAddressBookName
{
    /* Compute my addressBookName */
    [myAddressBookName release];
    myAddressBookName = [[@"AddressBook" mutableCopy] retain];
    id myUid = [[ab me] uniqueId];
    if(myUid){
	[myAddressBookName appendString:myUid];
    }
}


/****************************************************************
 */




/* copyFromABPerson:toPerson:
 * Actually copy an ABPerson entry into a Person entry
 */

-(void)copyFromABPerson:(ABPerson *)abperson toPerson:(Person *)pnew
{
    //NSLog(@"AddressBook->SBook %@ --> %@ ",[abperson printableName],pnew);

    NSString *res = [abperson stringWithDefaultLabel:defaultLabel];
    time_t now	 = time(0);
    time_t abperson_mtime = [abperson mtime];
    time_t mtime = abperson_mtime;

    res = [res removeDuplicateLines];	// if a line is duplicated, remove it.

    /* fix impossible times */
    if(mtime > now) mtime = now;

    /* And write everything in */

    [pnew checkpointForUndo];
    [pnew setMtime:mtime];
    [pnew setSyncTime:now];
    [pnew setAsciiData:[res dataUsingEncoding:NSUTF8StringEncoding
			    allowLossyConversion:YES]
	  releaseRtfdData:YES
	  andUpdateMtime:NO ];
    [pnew setSyncMtime:abperson_mtime];
    [pnew setFlag:ENTRY_ME_FLAG toValue:[[ab me] isEqualTo:abperson]];
}


-(bool)check:(Person *)per
	  at:(unsigned int)line
forCityState:(NSMutableDictionary *)tia
{
    char *city=0;
    char *state=0;
    char *zip=0;
    const char *lastLine = [[per asciiLine:line] UTF8String];
    bool took=false;
    
    [sbc find:lastLine city:&city state:&state zip:&zip];
    
    if(city && state){
	[tia setObject:[NSString stringWithUTF8String:city]
	     forKey:kABAddressCityKey];
	[tia setObject:[NSString stringWithUTF8String:state]
	     forKey:kABAddressStateKey];
	took = true;
	if(zip){
	    [tia setObject:[NSString stringWithUTF8String:zip]
		 forKey:kABAddressZIPKey];
	}
    }
    if(city) free(city);
    if(state) free(state);
    if(zip) free(zip);
    return took;
}

/* fix_label():
 * return a label that works better with AddressBook
 */
NSString *fix_label(NSString *label)
{
    if([label caseInsensitiveCompare:@"Work"]==NSOrderedSame) return @"_$!<Work>!$_";
    if([label caseInsensitiveCompare:@"Home"]==NSOrderedSame) return @"_$!<Home>!$_";
    if([label caseInsensitiveCompare:@"Cell"]==NSOrderedSame) return @"_$!<Mobile>!$_";
    if([label caseInsensitiveCompare:@"Mobile"]==NSOrderedSame) return @"_$!<Mobile>!$_";
    if([label caseInsensitiveCompare:@"Other"]==NSOrderedSame) return @"_$!<Other>!$_";
    if([label isEqualTo:@""]){
	//NSLog(@"*** empty label; using 'other' ***");
	return @"_$!<Other>!$_";
    }
    return label;
}

/* copyFromPerson:toABP:
 * Actually copy an SBook entry to the AddressBook
 * SBook --> AddressBook
 */

struct fixarray {
    NSString *was;
    NSString *label;
};

struct fixarray tofix[] = {
    {@"(H)",@"Home"},
    {@"(Home)",@"Home"},
    {@"(M)",@"Mobile"},
    {@"(Mobile)",@"Mobile"},
    {@"(C)",@"Mobile"},
    {@"(Cell)",@"Mobile"},
    {@"Cell",@"Mobile"},
    {@"(W)",@"Work"},
    {@"(work)",@"Work"},
    {@"(Office)",@"Work"},
    {@"Office",@"Work"},
    {@"(Fax)",@"Work Fax"},
    {@"Fax",@"Work Fax"},
    {0,0}
};
    
- (ABPerson *)copyFromPerson:(Person *)per toABP:(ABPerson *)abp
{
    time_t now = time(0);

    NSLog(@"new code");
    NSLog(@"SBook->AddressBook %@ --> %@ ",per,[abp printableName]);

    [per parse];

    unsigned int numLines = [per numAsciiLines];

    /* Decision #1: erase some of the fields, but not all of them */
    NSString *wipe[] = {@"Organization",
			@"First",
			@"HomePage",
			@"Middle",
			@"Last",
			@"Note",
			@"JobTitle",
			@"Suffix",
			@"Email",
			@"Address",
			@"Phone",0};
    
    for(int i=0;wipe[i];i++){
	[abp removeValueForProperty:wipe[i]];
    }

    /* Copy over the key data */

    [abp setMtime:[per mtime]];
    [abp setCtime:[per ctime]];

    if([sbc debug] >2){
	for(unsigned z = 0;z<numLines;z++){
	    NSLog(@"tag for line %d is %x (%@)",z,[per sbookTagForLine:z],
		  [per asciiLine:z]);
	}
    }


    if(numLines>0){
	bool takenLine[numLines];
	memset(takenLine,0,sizeof(takenLine));

	/* FIRST LINE HANDLING.
	 * If the first line is a name, set a name. Otherwise, set a company
	 */
	unsigned int line = 0;
	int l0 = [per sbookTagForLine:0] & P_BUT_MASK;
	
	if(l0 == P_BUT_COMPANY){
	    [abp setValue:[per cellName] forProperty:kABOrganizationProperty];
	    takenLine[line] = true;
	    line++;
	}
	else {
	    /* The first line is a person! Find the last name... */
	    [abp setValue:[per firstName] forProperty:kABFirstNameProperty];
	    [abp setValue:[per lastName] forProperty:kABLastNameProperty];
	    takenLine[line] = true;
	    line++;
	    if(numLines==line) goto out; // end

	    /* See if the next line is a title... */
	    if([sbc identifyLine:[[per asciiLine:line] UTF8String]] & P_TITLE){

		[abp setValue:[per asciiLine:line] forProperty:kABJobTitleProperty];

		takenLine[line] = true; 
		if([per sbookTagForLine:line] & P_BUT_MASK == P_BUT_ADDRESS){
		    takenLine[line] = false; // don't take if this is also an address
		}
		line++;
		if(line==numLines) goto out; // end
	    }

	    /* See if the next line is a company name...
	     * But not a phone number or address or email...
	     */
	    NSString *s2 = [per asciiLine:line];
	    const char *s2_utf8 = [s2 UTF8String];
	    int tag = ([per sbookTagForLine:line] & P_BUT_MASK);

	    if(tag!=P_BUT_TELEPHONE &&
	       tag!=P_BUT_EMAIL &&
	       [sbc parse_company:s2_utf8] &&
	       ![sbc parse_telephone:s2_utf8 arg:0] &&
	       isdigit([s2 characterAtIndex:0])==NO ){

	      [abp setValue:[per asciiLine:line]
		   forProperty:kABOrganizationProperty];
	      takenLine[line] = true;
	      if(tag == P_BUT_ADDRESS){
		takenLine[line] = false; // don't take if this is also an address
	      }
	      line++;
	      if(line==numLines) goto out; // end
	    }
	}

	/* If this a person, set the flag */
	int flags = [per isPerson] ? kABShowAsPerson : kABShowAsCompany;
	[abp setValue:[NSNumber numberWithInt:flags] forProperty:kABPersonFlags];

	/* Now scan all of the remaining lines and add the appropriate multi-values or links */
	bool addedURL = false;
	NSString *currentLabel = defaultLabel;
	ABMutableMultiValue *tel_mv = [[ABMutableMultiValue alloc] init]; // telephone mv
	ABMutableMultiValue *email_mv = [[ABMutableMultiValue alloc] init]; // email mv
	ABMutableMultiValue *addr_mv = [[ABMutableMultiValue alloc] init]; // address
	ABMutableMultiValue *aim_mv = [[ABMutableMultiValue alloc] init]; 
	ABMutableMultiValue *icq_mv = [[ABMutableMultiValue alloc] init]; 
	ABMutableMultiValue *jabber_mv = [[ABMutableMultiValue alloc] init]; 
	ABMutableMultiValue *msn_mv = [[ABMutableMultiValue alloc] init]; 
	ABMutableMultiValue *yahoo_mv = [[ABMutableMultiValue alloc] init]; 

	for(unsigned int i=1;i< numLines;i++){
	    int tag = [per sbookTagForLine:i];

	    if([sbc debug]>3) NSLog(@"processing line %d tag %x",i,tag);

	    NSMutableString *line = [[per asciiLine:i] mutableCopy];
	    bool set_label = false;
	    bool set_data  = false;

	    if(tag & P_FOUND_LABEL){
		const char *line_str = [line UTF8String];
		int  line_len = strlen(line_str);
		char *buf = (char *)calloc(line_len+64,1);

		[sbc extractLabel:line_str toBuf:buf];
		currentLabel = fix_label([NSString stringWithUTF8String:buf]);
		free(buf);

		set_label = true;

		line = [line substringFromCharacter:':'];	// just added
		while([line length]>0 && isspace([line characterAtIndex:0])){
		    line = [line substringFromIndex:1];	// remove leading spaces
		}
		if([line length]==0){
		    takenLine[i] = true; // whole line is label
		}
	    }

	    NSString *labelForLine = currentLabel;
	    if((tag & P_BUT_MASK)==P_BUT_TELEPHONE ||
	       (tag & P_BUT_MASK)==P_BUT_EMAIL){
		for(unsigned int k=0;tofix[k].was;k++){
		    if([line containsSubstringi:tofix[k].was]){
			labelForLine = fix_label(tofix[k].label);
			/* Check to see if line is the wrong class... */
			if(![line isMemberOfClass:[NSMutableString class]]){
			    line = [line mutableCopy];
			}
			[line replaceString:tofix[k].was withString:@"" global:NO];
			[line chompLeadingWhitespace];
			[line chomp];
			break;
		    }
		}
	    }


	    if(takenLine[i]==false){
		switch(tag & P_BUT_MASK){
		case P_BUT_LINK:
		    if(addedURL==false){
			[abp setValue:line forProperty:kABHomePageProperty];
			takenLine[i] = true;
			addedURL = true;
			set_data = true;
		    }
		    break;
		case P_BUT_TELEPHONE:
		    [tel_mv addValue:line withLabel:labelForLine];
		    takenLine[i] = true;
		    set_data = true;
		    break;
		case P_BUT_EMAIL:
		    {
			NSMutableString *editedLine = [line mutableCopy];
			[editedLine replaceRegexp:@"^([^ ]+):" with:@""];
			[editedLine replaceRegexp:@"\\([a-zA-Z]+\\)" with:@""];
			
			/* Bug with MacOS 10.4: labelForLine for email can't be Mobile... */
			NSString *emailLabelForLine = labelForLine;
			if([emailLabelForLine isEqualTo:@"_$!<Mobile>!$_"]){
			    emailLabelForLine = @"Mobile";
			}

			[email_mv addValue:editedLine withLabel:emailLabelForLine];
			takenLine[i] = true;
			set_data = true;

			/* Special case --- check for P_IM_AM as well on this line
			 * for this MAC.COM accounts...
			 */
			unsigned int a2;
			a2 = 0;
			[sbc parse_telephone:[line UTF8String] arg:&a2];
			if(a2==P_IM_AIM){
			    [aim_mv addValue:editedLine withLabel:currentLabel];
			}
		    }
		    
		    
		    break;
		    // found a line within an address (may have missed start)

		case P_BUT_IM:
		    {
			// get the IM brand
			NSMutableString *editedLine = [line mutableCopy];
			[editedLine replaceRegexp:@"^([^ ]+):" with:@""];
			[editedLine replaceRegexp:@"\\([a-zA-Z]+\\)" with:@""];

			unsigned int arg=0;
			[sbc parse_telephone:[line UTF8String] arg:&arg];
			if(arg==0){
			    NSMutableString *l2 = [currentLabel mutableCopy];
			    [l2 appendString:@":"]; // add a colon
			    [sbc parse_telephone:[l2 UTF8String] arg:&arg];
			}
			switch(arg){
			case P_IM_AIM:
			    [aim_mv addValue:editedLine withLabel:labelForLine];
			    break;
			case P_IM_ICQ:
			    [icq_mv addValue:editedLine withLabel:labelForLine];
			    break;
			case P_IM_Jabber:
			    [jabber_mv addValue:editedLine withLabel:labelForLine];
			    break;
			case P_IM_MSN:
			    [msn_mv addValue:editedLine withLabel:labelForLine];
			    break;
			case P_IM_Yahoo:
			    [yahoo_mv addValue:editedLine withLabel:labelForLine];
			    break;
			}
			takenLine[i] = true;
			set_data = true;
		    }
		    break;

		case P_BUT_ADDRESS:
		    unsigned int j = i+1;
		    while(j<numLines){
			if([per sbookTagForLine:j-1] & P_FOUND_AEND) break;
			j++;
		    }
		    unsigned int alast = j; // one more than needed
		    /* Create a multivalue for this address */
		    NSMutableDictionary *tia = [NSMutableDictionary dictionary];

		    /* If we can find a city, state and zip on the last line or second to last line, then
		     * use that information and kill the last line.
		     * Otherwise, just put in in as a buffer
		     */
		    if([self check:per at:alast-1 forCityState:tia]){
			takenLine[alast-1]=true;
		    }
		    else if([self check:per at:alast-2 forCityState:tia]){
			[tia setObject:[per asciiLine:alast-1]  forKey:kABAddressCountryKey];
			takenLine[alast-2]=true;
			takenLine[alast-1]=true;
		    }

		    /* Now get all of the lines that are not blank*/
		    NSMutableString *street = [NSMutableString string];
		    for( ; i<alast; i++){
			if(takenLine[i]==false){
			    takenLine[i] = true;
			    NSMutableString *line  = [[per asciiLine:i] mutableCopy];
			    [line chomp];
			    [line chompLeadingWhitespace];
			    if([line length]>0){
				[street appendString:line];
				[street appendString:@"\n"];
			    }
			}
		    }
		    if([street length]>2){
			[street deleteCharactersInRange:NSMakeRange([street length]-1,1)];
			[tia setObject:street forKey:kABAddressStreetKey];
		    }
		    if([tia count]>0){
			[addr_mv addValue:tia withLabel:labelForLine];
		    }
		    i--;		// because it will be incremented again
		}
	    }

	    if(set_data && set_label){
		currentLabel = defaultLabel; // these labels are only used on one line
	    }
	}

	/* In an attempt to disgnose the problems with iSync 2.0, I have turned off the email sync below. */


	if([tel_mv count]>0)   [abp setValue:tel_mv forProperty:kABPhoneProperty];
	if([email_mv count]>0) [abp setValue:email_mv forProperty:kABEmailProperty];
	if([addr_mv count]>0)  [abp setValue:addr_mv forProperty:kABAddressProperty];
	if([aim_mv count]>0) [abp setValue:aim_mv forProperty:kABAIMInstantProperty];
	if([jabber_mv count]>0)   [abp setValue:jabber_mv forProperty:kABJabberInstantProperty];
	if([msn_mv count]>0)   [abp setValue:msn_mv forProperty:kABMSNInstantProperty];
	if([icq_mv count]>0)   [abp setValue:icq_mv forProperty:kABICQInstantProperty];
	if([yahoo_mv count]>0)   [abp setValue:yahoo_mv forProperty:kABYahooInstantProperty];


	/* now grab the note; start over at line 1;
	 * Omit the lines we have taken in whole.
	 * in the future, deal with that.
	 */
	NSMutableString *newNote = [NSMutableString string];
	for(line=1;line< numLines;line++){
	    if(takenLine[line]==false){
		[newNote appendString:[per asciiLine:line]];
		[newNote appendString:@"\n"];
		takenLine[line] = true;
	    }
	}
	[newNote chompLeadingWhitespace];
	[newNote chomp];
	[newNote appendString:@"\n"];

	[abp setValue:newNote forProperty:kABNoteProperty];

	/* At this point, see if we have work but not home or home but not work.
	 * If so, then change "main" to either work or home
	 */

	[tel_mv release];
	[email_mv release];
	[addr_mv release];
	[aim_mv release];
	[icq_mv release];
	[jabber_mv release];
	[msn_mv release];
	[yahoo_mv release];
    }

 out:

    if([per queryFlag:ENTRY_ME_FLAG]){
	[ab setMe:abp];
    }

    // Finally, set the times */
    [abp setMtime:[per mtime]];	// set the modify time to be the original modify time

    [per setSyncMtime:[abp mtime]]; 
    [per setSyncMD5:[[abp stringWithDefaultLabel:defaultLabel] md5]]; // set the MD5 of per to the current MD5
    [per setSyncTime:now];

    //time_t t = [per syncMtime];
    //NSLog(@"set %@'s syncMtime to:%s",per,ctime(&t));

    [sbookRecordsCopied increment];
    [justCopied addObject:per];		// remember that we just copied this
    return abp;
}



/* syncABPerson:
 * ABAddressBook --> SList
 */

- (Person *)syncABPerson:(ABPerson *)abp 
{
    NSString *uid       = [abp uniqueId];

    if([sbc debug]){
	NSLog(@"\n\nsyncABPerson: %@ uid=%@",[abp cellName],uid);
    }

    /* First, get the Person for the abperson's uid */
    Person *per = [doc personWithSyncUID:uid];

    if(per){				// see if this object is okay
	/* There is an entry in the SList with this UID. */

	if([sbc debug]){
	    NSLog(@"Exists in slist. per=%@", per);
	}



	/* We don't need to sync at all if the mtime in the abperson is the
	 * same as the mtime for the one in the slist
	 */

	if([sbc debug]>1){
	    time_t n = time(0);

	    NSLog(@"           now=%10d (%s)",n,ctime(&n));
	    n = [per mtime];
	    NSLog(@"    per.mtime=%10d (%s)",n,ctime(&n));

	    n = [abp mtime];
	    NSLog(@"abperson.mtime=%10d (%s)",n,ctime(&n));

	    n = [per syncTime];
	    NSLog(@" per.syncTime=%10d (%s)",n,ctime(&n));

	    n = [per syncMtime];
	    NSLog(@"per.syncMtime=%10d (%s)",n,ctime(&n));

	    NSLog(@" personModifiedAfterSync=%d",[self personModifiedAfterSync:per]);
	}

	/* If the two mtimes are the same, no reason to sync */
	if([per mtime]==[abp mtime]){
	    [abRecordsSkipped increment];
	    return per;
	}

	/* If the abperson has not been modified since the last sync,
	 * there is no need to sync again
	 */
	if([abp mtime] <= [per syncMtime] ||
	   [abp mtime] <= [per syncTime]){
	    [abRecordsSkipped increment];
	    return per;
	}

	/* If the abperson's MD5 is the same as it was when we wrote it out, we don't
	 * need to suck it in again...
	 */
	NSData *perMD5 = [per syncMD5];
	NSData *abMD5 = [[abp stringWithDefaultLabel:defaultLabel] md5];
	if([perMD5 isEqualTo:abMD5]){
	    NSLog(@">>>>times say that it changed, but it didn't change");
	    [abRecordsSkipped increment];
	    return per;
	}

	/* If ours has been modified after last sync, we need to fork... */
	if([self personModifiedAfterSync:per]){
	    /* See if the MD5 for ABPerson's content has changed. */

	    NSLog(@"%@ modified in both AddressBook and SBook after last sync. Forking", per);
	    [per setSyncSource:nil];	// we are no longer from this source
	    [per setSyncUID:nil];	// break our local copy
	    per = nil;			// and make a new one
	}
    }

    /* If we don't have a person,
     * then we are going to create one from the AddressBook entry
     */
    if(!per){
	/* First see if this person was deleted... */
	time_t whenDeleted = [doc whenDeleted:[abp valueForProperty:kABUIDProperty]];
	if(whenDeleted){
	    /* If it was deleted after it was modified, not copy over */
	    time_t mtime = [abp mtime];
	    NSLog(@"whenDeleted=%d mtime=%d",whenDeleted,mtime);
	    if(mtime < whenDeleted)
		return nil;		// no need to copy it over
	}
	

	NSLog(@"Creating new SBook entry for %@",[abp cellName]);
	per = [[[[sbc PersonClass] alloc] init] autorelease];
	[per setDoc:doc];
	[per setSyncSource:myAddressBookName];
	[per setSyncUID:uid];
	[per setCtime:[[abp valueForProperty:@"Creation"] time_t]];
	[doc addPerson:per];
    }

    /* At this point, we know that the information in the ABPerson needs to be
     * copied into the person
     */

    [self copyFromABPerson:abp toPerson:per];
    [abRecordsCopied increment];
    return per;
}

/* Does a search without raising an exception */
- (ABRecord *)recordForGid:(NSString *)uid
{
    ABSearchElement *uidSearch = [ABPerson searchElementForProperty:kABUIDProperty
					   label:nil
					   key:nil
					   value:uid
					   comparison:kABEqual];
    NSArray  *match     = [ab recordsMatchingSearchElement:uidSearch];
    return ([match count] > 0) ? [match objectAtIndex:0] : nil;
}

- (ABPerson *)abpersonForPerson:(Person *)per
{
    NSString *uid  = [per syncUID];	// get the syncUID

    /* First, get the ABPerson with the same UID */
    ABSearchElement *uidSearch = [ABPerson searchElementForProperty:kABUIDProperty
					   label:nil
					   key:nil
					   value:uid
					   comparison:kABEqual];
    NSArray  *match     = [ab recordsMatchingSearchElement:uidSearch];
    if([match count]==0){
	return nil;
    }

    ABPerson *abperson  = [match objectAtIndex:0];
    return abperson;
}

/*
 * Person --> ABPerson
 * Check to see if we should copy a person to an AddressBook person.
 * If so, then do the copy.
 */
- (ABPerson *)syncPerson:(Person *)per flag:(int)flag
{
    int forceFlag = flag & SYNC_FORCE_FLAG;
    ABPerson *abperson = [self abpersonForPerson:per];

    if(abperson && forceFlag==0){
	/* There is an entry in the AddressBook with this UID */
       
	/* We don't need to sync at all if the mtime in the abperson is the same 
	 * as the mtime for the one in the slist
	 */
	if([abperson mtime]==[per mtime]){
	    [sbookRecordsSkipped increment];
	    return abperson;
	}

	/* If the person was modified before the last sync, there is no need to sync again */
	if([per mtime] <= [per syncTime]){
	    [sbookRecordsSkipped increment];
	    return abperson;
	}

	/* If the abperson was modified after the last sync, we are just going to override it for now... */
	if([abperson mtime] > [per syncMtime]){
	    NSLog(@"Person %@ modified in address book after last sync. Tough Noogies. ",per);
#if 0
	    [per setSyncSource:nil];
	    [per setSyncUID:nil];
	    if(1 || [sbc debug]){
		NSLog(@"Person %@ modified in address book after last sync. Forking. ",per);
		long t = [abperson mtime];
		NSLog(@"abperson mtime=%s",ctime(&t));
		t = [per syncMtime];
		NSLog(@"per syncMtime=%s",ctime(&t));
		NSLog(@"abperson=%@",abperson);
	    }
	    abperson = nil;
#endif
	}
    }
    
    /* If we don't have an ABPerson, then we are going to create one from the Person
     * and link them...
     */

    if(abperson==nil){
	/* Create a new one! */
	NSLog(@"Creating new person in address book for %@...",per);
	abperson = [[[ABPerson alloc] init] autorelease];
	
	[per setSyncSource:myAddressBookName];
	[per setSyncUID:[abperson uniqueId]];
	[ab addRecord:abperson];
    }

    /* Now this is the real hard part: copy the relevant fields from the person to the abp */
    id res = [self copyFromPerson:per toABP:abperson];
    if(flag & SYNC_AB_SAVE_FLAG) [ab save];
    return res;
}

- (BOOL)abpModifiedAfterSync:abp
{
    return ([abp mtime] > [abp syncTime]);
}

- (int)syncSourceCount
{
    return [[ab people] count];
}



/*
 * Procedure to Sync with ABAddressBook:
 * 1. Make a list of all people in database from this address book.
 * 2. Scan entire address book.
      - new entries: create
      - old entries: If not modified after sync, resync, otherwise fork.
                    - (probably we don't want to both resyncing if the modtime hasn't changed...)
 * 3. For all that were in the address book that were not in the address book,
 - If it was not modified after sync, delete it.
 * 4. Next, for all of the entries that are in the SBook, copy them into ABAddressBook 
*/

/****************************************************************
 *** ABAddressBook -> SList
 ****************************************************************/

- (void)syncSourceToSBook
{
    NSMutableArray *peopleToDeleteList = [[doc peopleWithSyncSource:myAddressBookName] mutableCopy];
    NSEnumerator *en= [[ab people] objectEnumerator];
    ABPerson *abp;
    while((abp = [en nextObject]) && !userQuit){
	Person *pnew = [self syncABPerson:abp ];

	if(pnew) [peopleToDeleteList removeObject:pnew];
	[ab_to_sbook incrementBy:1.0];
	[self checkForQuit];
    }
    
    /* Now, process deletions...
     * Do not allow "private" entries to be deleted.
     */
    [sbook_cleaner setMaxValue:[peopleToDeleteList count]];
    en = [peopleToDeleteList objectEnumerator];
    Person *per; 
    while((per = [en nextObject]) && !userQuit){
	if([self personModifiedAfterSync:per]==NO &&
	   [per queryFlag:ENTRY_PRIVATE_FLAG]==NO ){
	    [doc removePerson:per];
	    [sbookRecordsRemoved increment];
	}
	[sbook_cleaner incrementBy:1.0];
	[self checkForQuit];
    }
}

/****************************************************************
 *** SList --> ABAddressBook
 ****************************************************************/

/* Fast Sync:
 * Copy over the entries that have been modified since the last sync.
 * Delete AddressBook entries that have been deleted since last sync.
 */
- (void)syncSBookToSource:(int)flag
{
    BOOL sbookDeletesAddressbook = [[NSUserDefaults standardUserDefaults]
				       integerForKey:DEF_SBOOK_DELETES_ABADDRESSBOOK];
    
    int guiFlag = flag & SYNC_GUI_FLAG;
    if(forceTag==TAG_EXPORT_SBOOK_TO_ABOOK){
	guiFlag = YES;
    }

    NSLog(@"Starting syncSBookToSource:");

    /* Go through the SBook and copy those that have changed since they were synched */
    NSEnumerator *en = [doc personEnumerator];
    Person *per;
    time_t mostRecentSync=0;		// find the most recent syncTime

    while( (per = [en nextObject]) && !userQuit){
	if(guiFlag){
	    [self checkForQuit];
	    [sbook_to_abook incrementBy:1.0];
	}

	if([per queryFlag:ENTRY_PRIVATE_FLAG]){
	    [sbookRecordsSkipped increment];
	    continue; // don't sync private entries
	}
	if([per syncTime] > mostRecentSync){ // figure out when the most recent sync was
	    mostRecentSync = [per syncTime];
	}
	// was this record modified after it synched? (or are we forcing?)
	if([per mtime] < [per syncTime] && forceTag!=TAG_EXPORT_SBOOK_TO_ABOOK){
	    [sbookRecordsSkipped increment];
	    NSLog(@"Skipping %@; mtime=%d synctime=%d",per,[per mtime],[per syncTime]);
	    continue; // don't sync private entries
	}
	[self syncPerson:per flag:guiFlag | SYNC_FORCE_FLAG]; // nope; force it. 
    }
    
    NSLog(@"...Scanning for deletions");
    /* Now delete the entries that were deleted after mostRecentSync */
    if(sbookDeletesAddressbook){
	NSString *gid;
	NSMutableDictionary *deletedGIDs = [doc deletedGIDs];


	if(guiFlag) [abook_cleaner setMaxValue:[deletedGIDs count]];

	en = [deletedGIDs keyEnumerator];
	while(gid = [en nextObject]){
	    time_t whenDeleted = [[deletedGIDs valueForKey:gid] intValue];

	    if(whenDeleted > mostRecentSync){
		ABRecord *r = [self recordForGid:gid];
		if(r){
		    [ab removeRecord:r];
		    if(guiFlag) [abRecordsRemoved increment];
		}
	    }
	    if(guiFlag) [abook_cleaner incrementBy:1.0];
	}
    }
    NSLog(@"...Saving addressBook");
    [ab save];
    NSLog(@"Ended syncSBookToSource:");
}

#if 0
/* This does a slow-sync:
 * It goes through every entry in the SList and tries to sync them
 * to the AddressBook.
 */
- (void)syncSBookToSource
{
    BOOL sbookDeletesAddressbook = [[NSUserDefaults standardUserDefaults]
				       integerForKey:DEF_SBOOK_DELETES_ABADDRESSBOOK];
    NSMutableDictionary *convertedABPeople = [NSMutableDictionary dictionary];
    NSMutableArray	*abpersonList = [[ab people] mutableCopy];
    NSEnumerator *en = [doc personEnumerator];
    Person *per;
    ABPerson *abp;
    while((per = [en nextObject]) && !userQuit){
	[sbook_to_abook incrementBy:1.0];

	/* Skip if the entry is private or if we just copied it */
	if([justCopied containsObject:per] || [per queryFlag:ENTRY_PRIVATE_FLAG]){
	    [abRecordsSkipped increment];
	    continue;
	}

	abp = [self syncPerson:per flag:0];
	[convertedABPeople setObject:per forKey:abp];
	
	[abpersonList removeObject:abp]; // remove person who was processed
	[self checkForQuit];
    }

    /* Now, process deletions.
     * These are, by definition, AddressBookEntries that are not in the SList...
     */
    [abook_cleaner setMaxValue:[abpersonList count]];
    en = [abpersonList objectEnumerator];
    while((abp = [en nextObject]) && !userQuit){
	if([self abpModifiedAfterSync:abp]==NO ||
	   ([doc whenDeleted:[abp uniqueId]]
	    && sbookDeletesAddressbook)){
	    [ab removeRecord:abp];
	    [abRecordsRemoved increment];
	}
	[abook_cleaner incrementBy:1.0];
	[self checkForQuit];
    }
    [ab save];

    /* Finally, due to a bug in the Apple AddressBook,
     * go through the SList and get the current syncMTime for every entry.
     */
    en = [convertedABPeople keyEnumerator];
    while((abp = [en nextObject]) && !userQuit){
	per = [convertedABPeople objectForKey:abp];
	
	[per setSyncMtime:[abp mtime]];
	[self checkForQuit];
    }
}
#endif

-(void)runWithSLC:(SLC *)slc_ flag:(int)tag
{
    [self setMyAddressBookName];
    [super runWithSLC:slc_ flag:tag];
}


@end


