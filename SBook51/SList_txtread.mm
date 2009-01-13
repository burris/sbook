/*
 * SList_txtread.m:
 *
 * Reads a text file. Returns an Autorelease SList.
 */

#import <Cocoa/Cocoa.h>
#import "SList.h"
#import "Person.h"
#import "XMLArchiver.h"
#import "defines.h"
#import "tools.h" 
#import "ImportingTabAlertPanel.h"
#import "SBookController.h"

/* Find every occurance of more than two \n's in a row and make them just
 * two \n's...
 */
void removeDoubleBlanks(NSMutableData *data)
{
    int  len = [data length];
    char *bytes = (char *)[data mutableBytes];
    int  from,to;

    /* Prime the pump */
    for(from=3,to=3;from<len;from++){
	if(bytes[from]=='\n' &&
	   bytes[from-1]=='\n' &&
	   bytes[from-2]=='\n'){
	    continue;
	}
	bytes[to++] = bytes[from];
    }
    [data setLength:to];		// shorten
}

NSString *SList_tag_name(int tag)
{
    switch(tag){
    case TAG_SBOOK_XML:    return @"SBook XML";
    case TAG_SBOOK_ASCII:  return @"SBook ASCII";
    case TAG_INFOGENIE:    return @"InfoGenie";
    case TAG_IDATA:        return @"iDATA";
    case TAG_TAB_DELIMITED:return @"Tab Delimited";
    case TAG_TAB_DELIMITED_SMART: return @"Tab Delimited (smart)";
    case TAG_CSV_DELIMITED: return @"CSV";
    case TAG_BLANK_LINE_DELIMITED: return @"Blank line delimited";
    }
    return @"TAG_UNKNOWN";
}

/*
 * identify: attempt to figure out what type of file this is
 * Returns an Import Info dictionary
 */

NSDictionary *SList_txt_identify(NSData *d)
{
    unsigned int len = [d length];
    unsigned int i;
    int firstEOL = -1;
    int histogram[256];			// letter frequency histogram
    int los[256];			// line of symbols histogram - 
    BOOL lineStart=NO;
    int firstChar = -1;
    int max;
    const char *data = (const char *)[d bytes];
    NSMutableDictionary *ii = [NSMutableDictionary dictionary];
    

    /* Check to see if it is an XML file */
    if(len>5 && strncmp(data,"<?xml",5)==0){
	[ii setObject:[NSNumber numberWithInt:TAG_SBOOK_XML] forKey:FMT_DOC_TYPE_TAG];
	return ii;
    }

    /* See if it is an RTF file. */
    if(len>5 && strncmp((const char *)data,"{\\rtf",5)==0){
	[ii setObject:[NSNumber numberWithInt:TAG_RTF] forKey:FMT_DOC_TYPE_TAG];
	return ii;
    }

    /* Make a quick histogram of the letter frequency
     * and find where the first line ends.
     */
    memset(histogram,0,sizeof(histogram));
    memset(los,0,sizeof(los));
    int chars_on_line = 0;
    for(i=0;i<len;i++){
	char ch = data[i];

	histogram[(unsigned int)ch]++;
	if(ch=='\r' || ch=='\n'){
	  // We had a line of all unique chars? 
	    if(firstChar != -1 && firstChar>=0 && firstChar<=256 && chars_on_line>2){
		los[firstChar]++;
	    }
	    lineStart = YES;
	    if(firstEOL==-1){
		firstEOL = i;
	    }
	    chars_on_line = 0;	/* reset the count */
	    continue;
	}
	if(lineStart){			// if we started a line, remember the first char
	    lineStart = NO;
	    firstChar = ch;
	}
	if(ch != firstChar){		// if this character is different from the first,
	    firstChar = -1;		// reset firstChar
	}
    }
    
    /* InfoGenie/iData uses ^f to delim records. If we have a ^f and more
     * ^fs than ^es and ^gs, then it is probably an IG file and not a binary file.
     */
    if(histogram[6]>1 && (histogram[5]+histogram[7])<histogram[6]){
	[ii setObject:[NSNumber numberWithInt:TAG_INFOGENIE] forKey:FMT_DOC_TYPE_TAG];
	[ii setObject:@"\006" forKey:FMT_RECORD_DELIM];
	[ii setObject:@"\r" forKey:FMT_LINE_DELIM];
	return ii;
    }

    /* Figure out the first line. If there isn't one, we can't figure out the file type */
    if(firstEOL == -1){			// could not find?
	return nil;
    }

    /* If there are many more tabs than carriage returns or linefeeds,
     * the text is probably tab-delimited.
     */
    if(histogram[9] > histogram[10]+histogram[13]){
	ImportingTabAlertPanel *ipan = [AppDelegate importingTabAlertPanel];

	if([ipan run]==NO){
	    return nil;			// aborted
	}

	[ii setObject:[NSNumber numberWithInt:[ipan ignoreFirstLine]] forKey:FMT_IGNORE_FIRST_LINE];
	[ii setObject:[NSNumber numberWithInt:[ipan swapNames]] forKey:FMT_SWAP_NAMES];


	[ii setObject:[NSNumber numberWithInt:TAG_TAB_DELIMITED] forKey:FMT_DOC_TYPE_TAG];
	[ii setObject:@"\r\n" forKey:FMT_RECORD_DELIM]; // take cariage return or linefeed
	[ii setObject:@"\t\013" forKey:FMT_LINE_DELIM]; // \t^k, for Bambi  (filemaker uses ^k)

	/* ask our tab importing question */

	return ii;
    }
	
    /* If we had a lot of rows delimited with one kind of symbol,
     * it's SBook ASCII with that kind of delimiter
     */
    max = 0;
    for(i=0;i<255;i++){
	if(los[i] > los[max]){
	    max = i;
	}
    }
    if(los[max]>1){
	char ch = max;
	NSMutableString *exportDelim = [NSMutableString string];

	[ii setObject:[NSNumber numberWithInt:TAG_SBOOK_ASCII]   forKey:FMT_DOC_TYPE_TAG];
	[ii setObject:[NSString stringWithCString:&ch length:1]  forKey:FMT_RECORD_DELIM]; 
	for(i=0;i<64;i++){
	    [exportDelim appendString:[NSString stringWithCString:&ch length:1]];
	}
	[exportDelim appendString:@"\n"];
	[ii setObject:exportDelim forKey:FMT_RECORD_DELIM];
	return ii;
    }

    /* Hm. Perhaps it is comma-delimited?
     * If so, that's a pain, because I need to do quoting.
     */
    int commaChar = ',';
    if(histogram[commaChar] > histogram[10] + histogram[13]){
	[ii setObject:[NSNumber numberWithInt:TAG_CSV_DELIMITED] forKey:FMT_DOC_TYPE_TAG];
	[ii setObject:@"\r\n" forKey:FMT_RECORD_DELIM]; // take cariage return or linefeed
	[ii setObject:@"," forKey:FMT_LINE_DELIM];
	return ii;
    }

    /* Jeez. Assume it is blank-line delimited */
    /* If there are only carriage returns and no newlines, then it is a Mac-formatted file */

    [ii setObject:[NSNumber numberWithInt:TAG_BLANK_LINE_DELIMITED] forKey:FMT_DOC_TYPE_TAG];
    [ii setObject:@"\r\n" forKey:FMT_LINE_DELIM];
    return ii;
}

/*
 * SList_infoGenieRead:
 * Read an ASCII file in which the entries are delimited by a single character
 */

SList *SList_delimitedRead(NSData *d,NSDictionary *ii)
{
    SList *doc = [[[SList alloc] init] autorelease];
    int   i;
    int	  entryStart = 0;
    int   len = [d length];
    const char *data = (const char *)[d bytes];
    int tag = [[ii objectForKey:FMT_DOC_TYPE_TAG] intValue];
    NSString *recordDelimString = [ii objectForKey:FMT_RECORD_DELIM];
    NSString *lineDelimString = [ii objectForKey:FMT_LINE_DELIM];
    int	sortFlagHold = 0;
    BOOL	swapNames       = [[ii objectForKey:FMT_SWAP_NAMES] intValue];
    BOOL	ignoreFirstLine = [[ii objectForKey:FMT_IGNORE_FIRST_LINE] intValue];

    int		recordDelim1 = [recordDelimString characterAtIndex:0];
    int		recordDelim2 = 0;
    int		lineDelim1    = 0;
    int		lineDelim2    = 0;
    //int	blankLine = (tag==TAG_BLANK_LINE_DELIMITED);
    
    if([recordDelimString length]>1){
	recordDelim2 = [recordDelimString characterAtIndex:1];
    }

    if([lineDelimString length]>0){
	lineDelim1 = [lineDelimString characterAtIndex:0];
	if([lineDelimString length]>1){
	    lineDelim2 = [lineDelimString characterAtIndex:1];
	}
	    
    }

    /* Loop through the data, find each delim, make substrings, set up people, add them */
    sortFlagHold = [doc queryFlag:SLIST_SORT_FLAG];
    [doc setFlag:SLIST_SORT_FLAG toValue:0];
    for(i=0;i<len;i++){
      int process = 0;

	if(data[i]==recordDelim1 || data[i]==recordDelim2 || i==len-1){
	  process = 1;
	}
	if((tag==TAG_BLANK_LINE_DELIMITED) &&
	   ((data[i]=='\n' && data[i+1]=='\n') ||
	    (data[i]=='\r' && data[i+1]=='\r') ||
	    (data[i]=='\r' && data[i+1]=='\n' && data[i+2]=='\r' && data[i+3]=='\n'))){
	  process=1;
	}

	if(process){

	    Person *per = [[[Person alloc] init] autorelease];
	    int	recordLen = i-entryStart;
	    char *recordData   = (char *)(data+entryStart); // the data that we are adding
	    char *mallocedData = 0;
	    BOOL  justDate=YES;
	    int  j;
	    NSMutableData *newData;

	    /* This should be rewritten just to use an NSMutableData or NSMutableString.*/

	    /* If there is a line delimiter, make a copy and change all the delims to lines */
	    if(lineDelim1){
		int k;

		mallocedData = (char *)malloc(recordLen+16);
		memcpy(mallocedData,recordData,recordLen);
		recordData = mallocedData;
		for(j=0;j<recordLen;j++){
		    if(recordData[j]==lineDelim1||
		       recordData[j]==lineDelim2){
			recordData[j] = '\n';
		    }
		}

		/* Remove quoted lines */
		for(j=0,k=0;
		    j<recordLen;
		    j++){

		    /* See if we should eat a quote */
		    if(recordData[j]=='"' && 
		       ((j==0) ||
			(j>0 && recordData[j-1]=='\n') ||
			(j<recordLen-2 && recordData[j+1]=='\n') ||
			(j==recordLen-1)
			)
		       ){
			continue;
		    }
		    recordData[k++] = recordData[j]; // copy it over if we are not supposed to skip
		}
		recordData[k] = '\000';	// null-terminate
		recordLen = k;		// new length

		/* Finally, look for "city\nstate\nzip"
		 * and change to city state zip... (needs to put in space..)
		 */
		for(j=0;j<recordLen-9;j++){
		    if(recordData[j]=='\n' &&
		       isupper(recordData[j+1]) &&
		       isupper(recordData[j+2]) &&
		       recordData[j+3]=='\n' &&
		       isdigit(recordData[j+4]) &&
		       isdigit(recordData[j+5]) &&
		       isdigit(recordData[j+6]) &&
		       isdigit(recordData[j+7]) &&
		       isdigit(recordData[j+8]) &&
		       (recordData[j+9]=='\n' ||
			(j<recordLen-15 &&
			 recordData[j+9]=='-' &&
			 isdigit(recordData[j+10]) &&
			 isdigit(recordData[j+11]) &&
			 isdigit(recordData[j+12]) &&
			 isdigit(recordData[j+13]) &&
			 recordData[j+14]=='\n'))){

			recordLen += 1;
			recordData = (char *)realloc(recordData,recordLen); // allocate new space
			memmove(recordData+j+1,recordData+j,recordLen-j); // insert a space
			recordData[j] = ',';
			recordData[j+1] = ' ';
			recordData[j+4] = ' ';
		    }
		}

	    }

	    /* Special hack for Apple. If the first line is just a date, make it the last line */
	    for(j=0;j<recordLen && recordData[j]!='\n' && recordData[j]!='\r';j++){
		if(recordData[j]!='/' && !isdigit(recordData[j])){
		    justDate=NO;
		}
	    }
	    /* Make a copy of the data if I'll need it */
	    if(justDate || swapNames){
		if(mallocedData==0){
		    mallocedData = (char *)malloc(recordLen+16);
		    memcpy(mallocedData,recordData,recordLen);
		    recordData = mallocedData;
		}
	    }

	    if(justDate){
		/* j is where the end of the line ends */
		while(j<recordLen && (recordData[j]=='\n'||recordData[j]=='\r')){
		    j++;
		}
		mallocedData = (char *)realloc(mallocedData,recordLen+j+32);
		mallocedData[recordLen] = '\n';
		memmove(mallocedData+recordLen+1,mallocedData,j);
		recordData = mallocedData+j;
	    }

	    /* Another hack for Apple. If swap names is in effect, remove the first two lines
	     * and swap them around
	     */
	    if(swapNames){
		char *cc1=0;		// find the first \n
		char *cc2=0;		// find the second \n

		cc1 = strchr(recordData,'\n');
		if(cc1){
		    cc2 = strchr(cc1+1,'\n');
		    if(cc2){
			int	l1 = cc1-recordData;
			int	l2 = cc2-cc1;
			char *buf = (char *)malloc(l1+l2+32);
			
			memcpy(buf,cc1+1,l2);
			buf[l2-1] = ' ';	// change \n to space
			memcpy(buf+l2,recordData,l1);
			memcpy(recordData,buf,l1+l2); // put it back
		    }
		}
	    }

	    if(recordLen){
		/* Turn the data that I am going to be adding into an NSMutableData */
		newData = [NSMutableData dataWithBytes:recordData length:recordLen];
		
		removeDoubleBlanks(newData);
		
		/* Append a null and see if this is all blanks. If it is, then don't add */
		[newData appendBytes:"\000" length:1];
		if(onlyBlankChars((const char *)[newData bytes]) == NO){
		    
		    [newData setLength:[newData length]-1]; // remove that byte
		    [per setAsciiData:newData releaseRtfdData:YES andUpdateMtime:NO];
		    
		    if(!ignoreFirstLine){
			[doc addPerson:per];	// without sorting
		    }
		    ignoreFirstLine = NO;	// if we were ignoring, we are not ignoring anymore
		}
	    }
		
	    if(mallocedData){
		free(mallocedData);
	    }
	    entryStart = i+1;
	}
    }
    [doc setFlag:SLIST_SORT_FLAG toValue:sortFlagHold];
    return doc;
}

/*
 * SList_sbookAsciiRead:
 * Read a file in which the records are delimited by a line which consists solely
 * of the delieter character
 */

SList *SList_sbookAsciiRead(NSData *d,NSDictionary *ii)
{
    SList *doc = [[[SList alloc] init] autorelease];
    int   i;
    int	  entryStart = 0;
    int   len = [d length];
    const char *data = (char *)[d bytes];
    int   prevLineStart = 0;		// where the previous line started
    int   firstChar =0;
    BOOL  lineStart = NO;
    NSString *recordDelimString = [ii objectForKey:FMT_RECORD_DELIM];
    int		recordDelim1 = [recordDelimString characterAtIndex:0];
    int	sortFlagHold = 0;

    /* Loop through the data, find each delim, make substrings, set up people, add them */
    sortFlagHold = [doc queryFlag:SLIST_SORT_FLAG];
    [doc setFlag:SLIST_SORT_FLAG toValue:0];
    for(i=0;i<len;i++){
	unsigned char ch = data[i];

	if(ch=='\r' || ch=='\n' || i==len-1){
	    if(firstChar == recordDelim1){	// found the end of the record!
		Person *per = [[[Person alloc] init] autorelease];

		int  entryLen = prevLineStart-entryStart;
		
		if(entryLen > 0){
		    char *recordData = (char *)(data+entryStart);

		    /* this was a dataWithBytesNoCopy, but it generated malloc errors */
		    [per setAsciiData:[NSData dataWithBytes:recordData length:entryLen]
			 releaseRtfdData:YES
			 andUpdateMtime:NO];
		    [doc addPerson:per]; // without sorting
		}
		    
		/* Now set up for the start of the next entry. It starts
		 * at the next character, unless that is a \n, in which case
		 * it starts at the one after that.
		 */
		entryStart = i+1;
		if(entryStart+1 < len &&
		   data[entryStart]=='\n'){
		    entryStart++;
		}
	    }
	    lineStart = YES;
	    continue;
	}
	if(lineStart){
	    lineStart = NO;
	    firstChar = ch;
	    prevLineStart = i;		// remember where this line started
	}
	if(ch != firstChar){
	    firstChar = -1;
	}
    }
    [doc setFlag:SLIST_SORT_FLAG toValue:sortFlagHold];
    return doc;
}

SList *SList_txtread(NSData *d)
{
    NSDictionary *ii;
    NSTextView   *text;

    if(d==nil) return nil;

    /* First attempt to identify what kind of file it is */
    
    ii = SList_txt_identify(d);

    if(ii==nil) return nil;		// import was canceled

    int tag = [[ii objectForKey:FMT_DOC_TYPE_TAG] intValue];

    switch(tag){
    case TAG_SBOOK_XML:
	return SList_xmlread(d,nil);	// an XML file with the wrong extension.
    case TAG_SBOOK_ASCII:
	return SList_sbookAsciiRead(d,ii);
    case TAG_INFOGENIE:
    case TAG_TAB_DELIMITED:
    case TAG_IDATA:
    case TAG_BLANK_LINE_DELIMITED:
	return SList_delimitedRead(d,ii);
    case TAG_RTF:
	/* For RTF, turn it into text and call ourselves recursively */
	text = [[NSTextView alloc] init];
	[text setRtfData:d];
	d = [[text string] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];;
	[text release];
	return SList_txtread(d);
    default:
	NSLog(@"SList_txtread: whoops! Didn't handle case %d",tag);
    }
    return nil;				// unrecognized type
}


