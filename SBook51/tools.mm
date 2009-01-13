/*
 * tools.M:
 * 
 * Tools for OSX
 */
 
#import <Cocoa/Cocoa.h>
#import "tools.h"
#import "base64.h"
#import "md5.h"
#import "zlib.h"

#import <sys/types.h>
#import <sys/stat.h>

void printRect(char *str,NSRect r)
{
    printf("%s = (%g,%g) - (%g,%g)\n",str,
	   r.origin.x,
	   r.origin.y,
	   r.size.width,
	   r.size.height);
}

NSData *dataForB64Data(NSData *str)
{
    int	decode_len         = [str length]+16;
    NSMutableData *b64Data = [NSMutableData dataWithLength:decode_len];
    int  datasize;
	    
    datasize = b64_pton_slg((const char *)[str bytes],
			    [str length],
			    (unsigned char *)[b64Data mutableBytes],
			    [b64Data length]);

    if(datasize<0){
	NSLog(@"dataForB64String: failed. [str length]=%d ",[str length]);
	return nil;
    }
    [b64Data setLength:datasize];
    return b64Data;
}

NSData *dataForB64String(NSString *str)
{
    return dataForB64Data([str dataUsingEncoding:NSUTF8StringEncoding]);
}


double	unitsMultiplier(NSString *name)
{
	if(!name) return 1.0;
	if([name isEqualToString:@"points"]) 	return 1.0;
	if([name isEqualToString:@"picas"])   return 12.0;
	if([name isEqualToString:@"inches"]) 	return 72.0;
	if([name isEqualToString:@"centimeters"]) return 72.0 / 2.54;
	return 1.0;
}


@implementation NSCalendarDate(Simson)
     -(time_t)time_t
{
    struct tm tm;
    time_t t;

    memset(&tm,0,sizeof(tm));
    tm.tm_year = [self yearOfCommonEra] - 1900;
    tm.tm_mon  = [self monthOfYear] - 1;
    tm.tm_mday = [self dayOfMonth];
    tm.tm_hour = [self hourOfDay];
    tm.tm_min  = [self minuteOfHour];
    tm.tm_sec  = [self secondOfMinute];
    tm.tm_isdst= -1;			// you figure it out.
    t = mktime(&tm);
    //NSLog(@"time_t (%@) = %d (%s)\n",self,t,ctime(&t));
    return t;
}
@end

@implementation NSObject(Simson)
- (void)awakeFromNib
{
}
@end

@implementation NSData(Simson)
+ (NSData *)dataWithUTF8String:(const char *)str
{
    NSString *str8 = [[[NSString alloc] initWithUTF8String:str] autorelease];

    return [str8 dataUsingEncoding:NSUTF8StringEncoding];
}


/* Turns all \r\n -> \n's
 * All \r -> \n's
 * Leaves all \n's as \n's.
 */
- (NSData *)fixLineEndings
{
    unsigned len = [self length];
    const char *buf = (const char *)[self bytes];
    const char *cc;
    int found = 0;
    for(cc=buf;cc<buf+len && !found;cc++){
	if(*cc == '\r') found = 1;
    }
    if(!found) return self;		// no \r's, so I'm okay

    char *nbuf = (char *)malloc(len);
    char *dd = nbuf;
    unsigned nlen = len;
    cc = buf;
    while(cc < buf+len){
	if(*cc != '\r'){		// not a \r
	    *dd++ = *cc++;
	    continue;
	}
	if((cc != buf+len-1) &&		// it's a \r\n
	   cc[1] == '\n'){
	    *dd++ = '\n';
	    cc+=2;
	    nlen--;
	    continue;
	}
	else {
	    /* It's a lone \r */
	    *dd++ = '\n';
	    cc++;
	    continue;
	}
    }
    return [NSData dataWithBytesNoCopy:nbuf length:nlen freeWhenDone:YES];
}
    

-(void)dump
{
    unsigned int i;
    const unsigned char *bytes = (const unsigned char *)[self bytes];

    for(i=0;i<[self length];i++){
	unsigned char ch = bytes[i];

	printf("data[%d] = %d ('%c')\n",i,ch,ch);
    }
}

- (NSString *)stringWithUTF8Encoding
{
    return [[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding] autorelease];
}

static NSMutableDictionary *factor = [[NSMutableDictionary dictionary] retain];
- (NSString *)commonStringWithUTF8Encoding
{
    NSString *str = [self stringWithUTF8Encoding];
    NSString *res = [factor objectForKey:str];
    if(res) return res;
    [factor setObject:str forKey:str];
    return str;
}


- (NSData *)convertFromEncoding:(NSStringEncoding)source toEncoding:(NSStringEncoding)dest
{
    return [[[[NSString alloc] initWithData:self encoding:source] autorelease] dataUsingEncoding:dest];
}

- (NSData *)md5
{
    NSMutableData *md5 = [NSMutableData dataWithLength:16];
    MD5FromBuffer((unsigned char *)[self bytes],
		  [self length],
		  (unsigned char *)[md5 mutableBytes]);
    return md5;
}

- (NSString *)base64
{
    int targsize = [self length]*2+64;
    char *b64    = (char *)malloc(targsize);	// big enough to hold
    NSString *ret;
    if(!b64){
	NSLog(@"Malloc failed for %d bytes in encodeXMLName",targsize);
	return nil;
    }
    b64_ntop((const unsigned char *)[self bytes],[self length],b64,targsize);
    ret = [NSString stringWithCString:b64];
    free(b64);
    return ret;
}

/* 16 byte header - C#### with size */
- (NSData *)compress			// returns a compressed object
{
    NSMutableData *res = [NSMutableData data];
    uLongf retlen=[self length]+12;

    [res setLength:[self length]+12+16];
    
    sprintf((char *)[res mutableBytes],"C%ud\n",[self length]); // remember the length
    int ret = compress((Bytef *)[res mutableBytes]+16,&retlen,
		       (const Bytef *)[self bytes],[self length]);
    if(ret==Z_OK){
	[res setLength:retlen+16];		// set the length
	return res;
    }
    return nil;				// can't get it compressed
}

- (NSData *)uncompress			// uncompresses; returns 0 if it can't.
{
    if([self length]<16){
	return nil;			// can't be right
    }

    /* First recover the original length */
    const char *bytes = (const char *)[self bytes];
    if(bytes[0]!='C'){
	return nil;			// doesn't have the correct header
    }

    uLongf origLen = 0;
    if(sscanf(bytes+1,"%lu",&origLen)!=1){
	return nil;			// can't recover it
    }

    NSLog(@"original length=%d\n",origLen);

    NSMutableData *res = [NSMutableData data];
    [res setLength:origLen];

    int ret = uncompress((Bytef *)[res mutableBytes],&origLen,
			 (const Bytef *)[self bytes]+16,[self length]-16);
    if(ret==Z_OK){
	return res;
    }
    return nil;				// can't get it compressed

}


@end

@implementation NSString(Simson)
+ (NSString *)fileChangeString:(NSString *)fileName // mtime + length, to detect file changes
{
    struct stat sb;
    if(stat([fileName UTF8String],&sb)){
	return 0;			// cannot read filename
    }
    return [NSString stringWithFormat:@"%d-%d",sb.st_mtime,sb.st_size];
}


+ (NSString *)stringWithUTF8String:(const char *)bytes length:(unsigned) length
{
    return [[[NSString alloc] initWithData:[NSData dataWithBytes:bytes length:length]
			      encoding:NSUTF8StringEncoding] autorelease];
}


+ (NSString *)stringWithFirstLineOfFile:(NSString *)filename
{
    NSRange r;
    unsigned int r1;

    NSString *fileContents = [NSString stringWithContentsOfFile:filename];
    if(!fileContents) return nil;
    
    r = [fileContents rangeOfString:@"\n"];
    if(r.length != 1){
	return nil;
    }
    r1 = r.location;

    /* See if there is a \r before the \n */
    r = [fileContents rangeOfString:@"\r"];
    if(r.length == 1){			// looks like I found it...
	if(r.location < r1){
	    r1 = r.location;
	}
    }

    return [fileContents substringToIndex:r1];
}

- (NSString *)substringToCharacter:(unichar)ch;	// not including character
{
    NSRange r = [self rangeOfString:[NSString stringWithCharacters:&ch length:1]];
    
    if(r.location == NSNotFound){
	return nil;			// character not in string
    }
    r.length = r.location-1;
    r.location = 0;
    return [self substringWithRange:r];
}

- (NSString *)substringFromCharacter:(unichar)ch;	// not including character
{
    NSRange r = [self rangeOfString:[NSString stringWithCharacters:&ch length:1]];
    
    if(r.location == NSNotFound){
	return nil;			// character not in string
    }
    r.location++;
    r.length = [self length] - r.location;
    return [self substringWithRange:r];
}

- (BOOL)directoryExists
{
    struct stat sb;
    if(stat([self UTF8String],&sb)){
	return NO;			// cannot read filename
    }
    if(S_ISDIR(sb.st_mode)) return YES;
    return NO;
}

- (unsigned)indexOfLastPrintingCharacter
{
    unsigned int i;
    for(i=[self length]-1; i>0; i--){
	if(isspace([self characterAtIndex:i])==0) return i;
    }
    return 0;
}

- (BOOL)containsSubstring:(NSString *)str
{
    NSRange r = [self rangeOfString:str];
    unsigned     str_length = [str length];

    return str_length>0 && r.length==str_length;
}

- (BOOL)containsSubstringi:(NSString *)str
{
    NSRange r = [self rangeOfString:str options:NSCaseInsensitiveSearch];
    unsigned     str_length = [str length];

    return str_length>0 && r.length==str_length;
}

- (BOOL)hasCharacter:(unichar)ch
{
    unsigned int i;
    for(i=[self length]-1;i>0;i--){
	if([self characterAtIndex:i]==ch) return YES;
    }
    return NO;
}


- (unsigned)lastChar
{
    if([self length]==0) return 0;
    return [self characterAtIndex:[self length]-1];
}


- (NSData *)md5
{
    return [[self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]
	       md5];
}
@end


@implementation NSMutableString(Simson)
- (void)appendBytes:(const char *)str length:(unsigned)length
{
    NSData *theData = [NSData dataWithBytes:str length:length];
    NSString *s2 = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];
    [self appendString:s2];
    [s2 dealloc];
}

- (void)appendStringAndNL:(NSString *)str // append a string and a \n if string exists
{
    if(str){
	[self appendString:str];
	[self appendString:@"\n"];
    }
}

- (void)removeFromString:(unichar)ch
{
    int i = 0;

    /* Remove any \r's */
    for(i=[self length]-1;i>=0;i--){
	if([self characterAtIndex:i]=='\r'){
	    [self deleteCharactersInRange:NSMakeRange(i,1)];
	}
    }
}
    


- (void)replaceString:(NSString *)a withString:(NSString *)b global:(BOOL)flag
{
    unsigned int i;
    unsigned int lena  = [a length];
    unsigned int count = [self length];
    unsigned int lenb  = [b length];

    if(lena ==0) return;                // need to replace something
    if(lena > [self length]) return;	// impossible
    for(i=0;i<[self length]-lena+1;i++){
	NSRange r = NSMakeRange(i,lena);

	if([[self substringWithRange:r] isEqualToString:a]){
	    if(lenb==0){
		[self deleteCharactersInRange:r];
	    }
	    else{
		[self replaceCharactersInRange:r withString:b];
	    }
	    if(flag==NO) return;
	    i += [b length] - 1;
	}
	if(count-- < 0) return; /* safety */
    }
}

- chompLeadingWhitespace
{
    unsigned int i = 0;
    while(i<[self length] && isspace([self characterAtIndex:i])){
	i++;
    }
    if(i>0) [self replaceCharactersInRange:NSMakeRange(0,i) withString:@""];
    return self;
}

/* Remove trailing whitespace */
- chomp
{
    unsigned int len = 0;
    do {
	unichar ch;

	len = [self length];
	if(len==0) break;		// end of the string
	ch = [self characterAtIndex:len-1];
	switch(ch){
	case ' ':
	case '\t':
	case '\n':
	case '\r':
	    [self replaceCharactersInRange:NSMakeRange(len-1,1) withString:@""];
	    break;
	default:
	    return self;			// no more whitespace
	}
    } while(len>0);
    return self;
}

- (void)stripSuffix:(NSString *)suffix	// removes str from string if present
{
    if([self hasSuffix:suffix]){
	[self replaceCharactersInRange:NSMakeRange([self length]-[suffix length],[suffix length])
	      withString:@""];
    }
}


- (void)prependString:(NSString *)str
{
    [self insertString:str atIndex:0];
}


@end

@implementation NSMutableData(Simson)
- (void)appendChar:(char)ch
{
    [self appendBytes:&ch length:1];
}

- (void)appendCString:(const char *)str
{
    [self appendBytes:str length:strlen(str)];
}

- (void)appendStringWithUTF8Encoding:(NSString *)str
{
    [self appendData:[str dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
}

@end


@implementation NSMatrix(Simson)
- (void) removeRows
{
    int i;
    for(i=[self numberOfRows]-1;i>=0;i--){
	[self removeRow:i];
    }
}

- (void)selectAndScrollToVisible:(id)aCell
{
    int i;
    int j;
    for(j=[self numberOfColumns]-1;j>=0;j--){
	for(i=[self numberOfRows]-1;i>=0;i--){
	    if([self cellAtRow:i column:j] == aCell){
		[self selectCellAtRow:i column:j];
		[self scrollCellToVisibleAtRow:i column:j];
		return;
	    }
	}
    }
}
@end


NSString *titleString(NSString*title,time_t aDate,NSString *aPerson)
{
    NSMutableString *str = [NSMutableString string];
    if(aDate){
	char buf[64];
	const char *by   = ([aPerson length]>0) ? " by " : "";

	[str appendString:title];

	strcpy(buf,ctime(&aDate)+4);
	buf[20] = '\000'; /* Remove \n at end */
	buf[12]=' '; /* change : to ' ' */
	memmove(buf+13,buf+16,5); 

	[str appendString:[NSString stringWithFormat:@"%s%s%@",buf,by,aPerson]];
    }
    return str;
}


@implementation NSDictionary(Simson)
- (int)intForKey:(id)aKey
{
    return [[self objectForKey:aKey] intValue];
}


- (float)floatForKey:(id)aKey
{
    return [[self objectForKey:aKey] floatValue];

}
@end


@implementation NSMutableDictionary(Simson)
- (void)setInt:(int)anInt forKey:(id)aKey
{
    [self setObject:[NSNumber numberWithInt:anInt] forKey:aKey];
}

- (void)setFloat:(float)aFloat forKey:(id)aKey
{
    [self setObject:[NSNumber numberWithFloat:aFloat] forKey:aKey];
}
@end


@implementation NSPopUpButton(simson)
- (int)tagOfTitle
{
    return [[self itemWithTitle:[self title]] tag];
}

- (BOOL)selectItemWithTag:(int)tag
{
    int index = [self indexOfItemWithTag:tag];

    if(index>=0){
	[self selectItemAtIndex:index];
	return YES;
    }
    return NO;
}


@end


@implementation NSTextView(Simson)
/****************************************************************
 ** ACCESSORS APPLE SHOULD HAVE PUT IN
 ****************************************************************/

- (unsigned int)length
{
    return [[self textStorage] length];
}

/****************************************************************
 ** SBook-specific things for first and second lines
 ****************************************************************/

- (void)selectFirstLine
{
    NSRange aRange  = [[self string] rangeOfString:@"\n"];	// find location of string

    aRange.length = aRange.location;
    aRange.location = 0;
    [self    setSelectedRange:aRange];
}

- (NSRange)secondLineToEnd
{
    NSRange r  = [[self string] rangeOfString:@"\n"];	// find location of string

    r.location++;
    r.length = [self length] - r.location;
    return r;
}

- (void)selectSecondLineToEnd
{
    [self setSelectedRange:[self secondLineToEnd]];
}

/****************************************************************
 ** Paragraph-based accessor functions.
 ****************************************************************/

/* Get the range of the given paragraph */
- (NSRange)getParagraphRange:(int)num
{
    //NSString *str = [self string];	
    NSString *str = [[self textStorage] mutableString];// this should be a little faster
    int length = [str length];
    int i;
    int start = -1;
    int end   = -1;

    for(i=0;i<length && end == -1;i++){
	unichar c = [str characterAtIndex:i];

	/* If there are no lines to go, this is the first character of the line */
	if(num==0 && start==-1) start = i;

	/* If this is a newline, count down */
	if(c == '\n'){
	    num--;
	}

	/* If we hit the end of the line, note it */
	if(num==-1 && end==-1 ) end = i;
    }

    /* See if we have the start of the string */
    if(start == -1) return NSMakeRange(0,0);		// no string

    /* If end is not set, it is length */
    if(end==-1 ) end = length;

    return NSMakeRange(start,end-start);
}

/* Gets a given paragraph number */
- (NSString *)getParagraph:(int)num
{
    NSRange paragraphRange = [self getParagraphRange:num];
    NSString *str = [[self textStorage] mutableString];

    /* And return the substring */
    return [str substringWithRange:paragraphRange];
}

+ (void)freeParagraphs:(struct TextParagraphs *)tp
{
    u_int i;
    char **lines = (char **)tp->lines;

    for(i=0;i<tp->numLines;i++){
	free(lines[i]);
	lines[i] = 0;
    }
    if(lines) free(lines);
    if(tp && tp->lineAttributes) free(tp->lineAttributes);
    if(tp) free(tp);
}


- (struct TextParagraphs *)getParagraphsWithEncoding:(NSStringEncoding)anEncoding
{
    struct TextParagraphs *tp;
    unsigned int  i;
    NSTextStorage *as;
    NSString *st;
    char **lines;

    tp = (TextParagraphs *)calloc(sizeof(*tp),1);
    lines = (char **)malloc(0);
    tp->lineAttributes = (unsigned int *)malloc(0);
    tp->numLines = 0;

    as = [self textStorage];
    st = [as string];

    i = 0;
    while(i<[st length]){
	u_int oldI = i;
	NSRange r = [st lineRangeForRange:NSMakeRange(i,1)]; // find the whole line
	NSString *str =[st substringWithRange:r];
	NSData *strData = [str dataUsingEncoding:anEncoding allowLossyConversion:YES];
	NSDictionary *attr = [as attributesAtIndex:r.location effectiveRange:0];
	NSFont *ft = [attr objectForKey:@"NSFont"];
	char *cstr = 0;
	int len = [strData length];

	lines = (char **)realloc((void *)lines,sizeof(char **)*(tp->numLines+1));
	tp->lineAttributes = (unsigned int *)realloc(tp->lineAttributes,
						     sizeof(int *)*(tp->numLines+1));
	cstr = (char *)malloc(len+1);
	memcpy(cstr,[strData bytes],len);
	cstr[len] = 0; // null-terminate
	
	/* Now remove the newline stuff */
	while(len>0 && (cstr[len-1]=='\n' || cstr[len-1]=='\r')){
	    cstr[len-1] = 0;
	    len--;
	}
	lines[tp->numLines] = cstr;
	tp->lineAttributes[tp->numLines] =
	    ([ft isBold] ? P_ATTRIB_BOLD : 0) |
	    ([ft isItalic] ? P_ATTRIB_ITALIC  : 0);
	    
	tp->numLines++;
	i = r.location + r.length;	// get to next position
	if(oldI == i) break;
    }

    tp->lines = (const char * const *)lines;
    return tp;
}


- (NSRectArray)getLayoutRectsWithCount:(unsigned *)rectCount
{
    int len = [self length];
    NSRectArray ret=(NSRectArray)malloc(0);
    int i;
    NSRange currentParagraph = NSMakeRange(0,0);
    int paragraphNum=0;
    NSLayoutManager *layout = [self layoutManager];
    NSTextContainer *container = [self textContainer];
    
    NSString *str = [[self textStorage] mutableString];

    for(i=0;i<len;i++){
	if([str characterAtIndex:i]=='\n' || i==len-1){
	    /* Found a paragraph end. Process */

	    currentParagraph.length = i-currentParagraph.location;

	    ret = (NSRectArray)realloc(ret,sizeof(NSRect)*(paragraphNum+1));
	    ret[paragraphNum] = [layout boundingRectForGlyphRange:currentParagraph
					inTextContainer:container];
	    currentParagraph.location = i+1; // start at next position
	    paragraphNum++;
	}
    }

    *rectCount = paragraphNum;
    return ret;
}


/****************************************************************
 ** RTF/RTFD routines that Apple should have put in
 ****************************************************************/

- (NSData *)UTF8Data
{
    return [[self string] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
}

- (NSData *)rtfdData
{
    NSRange allRange = NSMakeRange(0,[[self textStorage] length]);
    return [self RTFDFromRange:allRange];
}

- (NSData *)rtfData
{
    NSRange allRange = NSMakeRange(0,[[self textStorage] length]);
    return [self RTFFromRange:allRange];
}

- (void)setRtfData:(NSData *)theData
{
    NSRange allRange = NSMakeRange(0,[[self textStorage] length]);
    [self replaceCharactersInRange:allRange withRTF:theData];
}

- (void)setRtfdData:(NSData *)theData
{
    NSRange allRange;

    if(theData==nil){
	NSLog(@"setRtfdData: theData==nil!");
    }
    allRange = NSMakeRange(0,[[self textStorage] length]);
    [self replaceCharactersInRange:allRange withRTFD:theData];
}

- (void)appendString:(NSString *)aString
{
    int len = [[self textStorage] length];
    [self replaceCharactersInRange:NSMakeRange(len,0)
	       withString:aString];
}

- (void)appendRTFD:(NSData *)theData
{
    int len = [[self textStorage] length];
    [self replaceCharactersInRange:NSMakeRange(len,0)
	  withRTFD:theData];
}

- (void)removeHighlight
{
    NSLayoutManager *lm = [self layoutManager];
    int len = [[self textStorage] length];
    [lm removeTemporaryAttribute:NSBackgroundColorAttributeName
	forCharacterRange:NSMakeRange(0,len)];
}

- (void)highlightRange:(NSRange)aRange
{
    NSLayoutManager *lm = [self layoutManager];
    [lm setTemporaryAttributes:
	    [NSDictionary
		dictionaryWithObjectsAndKeys:[NSColor cyanColor],NSBackgroundColorAttributeName,
		nil,nil]
	forCharacterRange:aRange];
}

@end


@implementation NSMutableArray(Simson)
- (NSString *)stringWithPrefix:(NSString *)prefix
	       removeFromArray:(BOOL)rfArray
		  removePrefix:(BOOL)rPrefix
{
    NSEnumerator *en = [self objectEnumerator];
    NSString *str;

    while(str = [en nextObject]){
	if([str hasPrefix:prefix]){
	    if(rfArray){
		[self removeObject:str];
	    }
	    if(rPrefix){
		str = [str substringFromIndex:[prefix length]];
	    }
	    return str;
	}
    }
    return nil;
}

- (void)stripSuffixFromAllStrings:(NSString *)suffix;
{
    NSEnumerator *en = [self objectEnumerator];
    NSString *str;

    while(str = [en nextObject]){
	if([str hasSuffix:suffix]){
	    [self replaceObjectAtIndex:[self indexOfObject:str]
		  withObject:[str substringToIndex:[str length]-[suffix length]]];
	}
    }
}

-(void) addUniqueObjects:(NSArray *)a2
{
    NSEnumerator *en = [a2 objectEnumerator];
    NSObject *obj;
    while(obj = [en nextObject]){
	if([self containsObject:obj]==NO){
	    [self addObject:obj];
	}
    }
}


-(void) removeObjectsNotInArray:(NSArray *)a2;
{
    NSEnumerator *en = [self objectEnumerator];
    NSObject *obj;
    while(obj = [en nextObject]){
	if([a2 containsObject:obj]==NO){
	    [self removeObject:obj];
	}
    }
}

@end


@implementation NSArray(Simson)
-(NSString *)encodeAsPropertyList
{
    NSMutableString *str = [NSMutableString string];
    NSEnumerator *en = [self objectEnumerator];
    id obj;

    [str appendString:@"<!DOCTYPE plist SYSTEM \"file://localhost/System/Library/DTDs/PropertyList.dtd\">\n<plist version=\"0.9\">\n<array>\n"];
    while(obj = [en nextObject]){
	[str appendString:@"<string>"];
	[str appendString:obj];
	[str appendString:@"</string>\n"];
    }
    [str appendString:@"</array>\n</plist>"];
    return str;
}
@end

@implementation NSProgressIndicator(Local)
-(void)setToFull
{
    [self setMinValue:0.0];
    [self setMaxValue:1.0];
    [self setDoubleValue:1.0];
}
@end

@implementation NSFormCell(Local)
-(void)increment {[self setIntValue:[self intValue]+1];}
@end

@implementation NSFont(Simson)
-(BOOL)isBold
{
    return [[self fontName] containsSubstring:@"Bold"];
}

-(BOOL)isItalic
{
    NSString *name = [self fontName];

    return [name containsSubstring:@"Oblique"] ||
	[name containsSubstring:@"Italic"] ||
	[self italicAngle]>0;
}

@end


@implementation NSSplitView(Simson)
- (float)position
{
    return [[[self subviews] objectAtIndex: 1] frame].size.height;
}

- (void)setPosition:(float)position
{
    NSArray*subViews = [self subviews];
    NSRect newBounds;

    NSView *viewZero = [subViews objectAtIndex: 0];
    NSView *viewOne =  [subViews objectAtIndex: 1];
    float topSize;

    /* make sure position is in bounds */
    if(NSHeight([self frame])<20) return; // not enough room
    if(position<10) position = 10;
    if(position>NSHeight([self frame])-10) position = NSHeight([self frame])-10;

    topSize = [self frame].size.height - [self dividerThickness] - position;
 
    newBounds	= [viewZero frame];     
    newBounds.size.height = topSize;
    newBounds.origin.y = 0;
    [viewZero setFrame: newBounds];
 
    newBounds = [viewOne frame];
    newBounds.size.height = position;
    newBounds.origin.y = topSize + position;
    [viewOne setFrame: newBounds];

    [self setNeedsDisplay:YES];
}
@end


@implementation NSMenu(Simson)
- (NSMenuItem *)addMenuItemTitle:(NSString *)title image:(NSImage *)image
			  target:(id)target action:(SEL)action
			     tag:(int)tag
{
    NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];

    [self addItem:item];
    if(title) [item setTitle:title];
    if(image) [item setImage:image];
    if(target) [item setTarget:target];
    if(action) [item setAction:action];
    if(tag) [item setTag:tag];
    return item;
}
@end
