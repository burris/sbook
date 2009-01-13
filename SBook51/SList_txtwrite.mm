/*
 * SList_txtwrite.m:
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

/****************************************************************
 **
 ** FILE WRITING
 **
 ****************************************************************/

NSTextView *exportText = nil;

/*
 * Return an NSData of the nth icon, with a \n.
 */
NSData *find_nth(struct TextParagraphs *tp,unsigned int *results,int iconFlag,int nth)
{
    unsigned int i;
    for(i=0;i<tp->numLines;i++){
	if(results[i] & iconFlag){
	    if(nth-- < 0){
		NSMutableData *m = [NSMutableData dataWithBytes:tp->lines[i] length:strlen(tp->lines[i])];
		[m appendChar:'\t'];
		return m;
	    }
	}
    }
    return nil;				// not found
}

@implementation SList(txtwrite)

- (NSData *)txtWriteWithExportInfo:(NSDictionary *)fmt
{
    NSString *recordDelimString = [fmt objectForKey:FMT_RECORD_DELIM];
    NSString *lineDelimString = [fmt objectForKey:FMT_LINE_DELIM];
    NSData *lineDelimData;
    NSData *recordDelimData;
    NSMutableData *ret  = nil;
    int  tag		= [[fmt objectForKey:FMT_DOC_TYPE_TAG] intValue];
    NSArray *exportArray = [fmt objectForKey:EXPORT_ARRAY];
    
    if(exportArray==nil){
	exportArray = people;		// use this list
    }


    /* Special code for each export tag type */
    switch(tag){
    case TAG_SBOOK_XML:
	/* This is frightening; set people to be the exportArray for the purpose of XML generation */
	NSArray *oldPeople;
	oldPeople = people;
	people = exportArray;
	NSData *theData;
	theData = [XMLArchiver archiveXMLObject:self];
	people = oldPeople;
	return theData;

    case TAG_TAB_DELIMITED_SMART:
    case TAG_TAB_DELIMITED:    
	if(exportText==nil){
	    exportText = [[NSTextView alloc] init]; // make a disembodied text
	}
	recordDelimString = @"\n";	// for now
    }

    /* If no export record delim was set, then grab the old record delim.
     * If that is not set, use \n
     */
    if([recordDelimString length]==0){
	recordDelimString = @"\n";
    }

    /* If no export line delim was set, then grab the old line delim.
     * If that is not set, use \n
     */
    if([lineDelimString length]==0){
	lineDelimString = @"\n";
    }

    /* Now get the record and line delimiters */
    recordDelimData = [recordDelimString
			  dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    lineDelimData = [lineDelimString
			dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];

    ret = [NSMutableData data];	// what will be returned

    /* Now loop for each entry in the database */
    Person *person;
    NSEnumerator *en = [exportArray objectEnumerator];
    while(person = [en nextObject]){

	NSData *asciiData=nil;
	const unsigned char *bytes = 0;
	unsigned int len=0;
	unsigned int j=0;
	struct TextParagraphs *tp=0;		// paragraphs that were found
	unsigned int *results=0;

	/* non-smart export */
	switch(tag){
	default:
	    asciiData = [[person asciiString]
			    dataUsingEncoding:NSUTF8StringEncoding
			    allowLossyConversion:YES];
	    bytes = (const unsigned char *)[asciiData bytes];
	    len   = [asciiData length];

	    for(j=0;j<len;j++){
		char ch = bytes[j];
		if(ch=='\n'){
		    [ret appendData:lineDelimData];
		}
		else{
		    [ret appendBytes:&ch length:1];
		}
	    }
	    [ret appendData:recordDelimData];
	    break;

	case TAG_TAB_DELIMITED_SMART:
	case TAG_TAB_DELIMITED:
	    [exportText setString:[person asciiString]];
	    tp = [exportText getParagraphsWithEncoding:NSUTF8StringEncoding];	// learn about the paragraphs
	    results = (unsigned int *)malloc(tp->numLines*sizeof(int));

	    if(tag==TAG_TAB_DELIMITED){
		for(j=0;j<tp->numLines;j++){
		    [ret appendCString:tp->lines[j]];
		    if(j != tp->numLines-1){
			[ret appendChar:'\t'];
		    }
		}
		[ret appendData:recordDelimData];
		break;
	    }

	    /* Smart */
	    parse_lines(tp->numLines,tp->lines,0,0,results,0,0); // parse this entry

	    [ret appendCString:tp->lines[0]]; // put the first line first
	    [ret appendChar:'\t'];

	    [ret appendData:find_nth(tp,results,P_BUT_TELEPHONE,0)];
	    [ret appendData:find_nth(tp,results,P_BUT_TELEPHONE,1)];
	    [ret appendData:find_nth(tp,results,P_BUT_TELEPHONE,2)];
	    [ret appendData:find_nth(tp,results,P_BUT_TELEPHONE,3)];


	    free(results);
	    [NSTextView freeParagraphs:tp];	// give back what you got
	    [ret appendData:recordDelimData];
	    break;
	}
    }
    return ret;
}
@end

 
