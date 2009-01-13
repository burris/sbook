/* tools.m */

struct TextParagraphs {
    const char *buf;
    const char * const* lines;			// the actual lines
    unsigned int *lineAttributes;		// attributes for each line
    unsigned int numLines;
};

#ifndef P_ATTRIB_BOLD
#define P_ATTRIB_BOLD	          0x0001
#define P_ATTRIB_ITALIC	          0x0002
#endif


#ifdef  __cplusplus
extern "C" {
#endif
#ifdef NEVER_DEFINED
}
#endif

void printRect(char *str,NSRect r);
NSData *dataForB64Data(NSData *str);
NSData *dataForB64String(NSString *str);
double	unitsMultiplier(NSString *);

#ifdef  __cplusplus
}
#endif


#define FORWARD(x) if([super respondsToSelector:@selector(x)]) [super x];

@interface NSCalendarDate(Simson)
-(time_t)time_t;
@end



@interface NSData(Simson)
+ (NSData *)dataWithUTF8String:(const char *)cString;
- (NSData *)fixLineEndings;
- (void)dump;
- (NSString *)commonStringWithUTF8Encoding;
- (NSString *)stringWithUTF8Encoding;
- (NSData *)convertFromEncoding:(NSStringEncoding)source toEncoding:(NSStringEncoding)dest;
- (NSData *)md5;			// returns the MD5 of an NSData
- (NSString *)base64;			// returns as base64 representation
- (NSData *)compress;			// returns a compressed object
- (NSData *)uncompress;			// uncompresses; returns 0 if it can't.
@end


@interface NSString(Simson)
+ (NSString *)fileChangeString:(NSString *)filename; // mtime + length, to detect file changes
+ (NSString *)stringWithFirstLineOfFile:(NSString *)filename;
+ (NSString *)stringWithUTF8String:(const char *)bytes length:(unsigned)length;
- (NSString *)substringToCharacter:(unichar)ch;	// not including character
- (NSString *)substringFromCharacter:(unichar)ch;	// not including character
- (BOOL)directoryExists;		// does path specify a valid directory
- (unsigned)indexOfLastPrintingCharacter;
- (BOOL)containsSubstring:(NSString *)str;
- (BOOL)containsSubstringi:(NSString *)str; // case insensetive
- (unsigned)lastChar;			// 0 if there is none
- (NSData *)md5;			// returns the MD5 of an NSString
//- (NSData *)unbase64;			// reverse the base64
- (BOOL)hasCharacter:(unichar)ch;
@end


@interface NSObject(Simson)
    - (void)awakeFromNib;
@end


@interface NSMenu(Simson)
    - (NSMenuItem *)addMenuItemTitle:(NSString *)title
			       image:(NSImage *)image
			      target:(id)target
			      action:(SEL)action
				 tag:(int)tag;
@end


@interface NSMutableString(Simson)
- (void)appendBytes:(const char *)str length:(unsigned int)length;
- (void)appendStringAndNL:(NSString *)str; // append a string and a \n if string exists
- (void)removeFromString:(unichar)ch;	// remove all occurances of the character 
- (void)replaceString:(NSString *)a withString:(NSString *)b global:(BOOL)flag;
- chompLeadingWhitespace;
- chomp;				// removes trailing whitepsace; returns the string */
- (void)stripSuffix:(NSString *)suffix;	// removes str from string if present
- (void)prependString:(NSString *)str;
@end

@interface NSMutableData(Simson)
- (void)appendChar:(char)ch;
- (void)appendCString:(const char *)str;
- (void)appendStringWithUTF8Encoding:(NSString *)str;
@end


@interface NSMatrix(Simson)
- (void)removeRows;
@end

/* this needs to be an NSObject so it works with both views and cells */
NSString *titleString(NSString*title,time_t aDate,NSString *aPerson);


@interface NSDictionary(Simson)
- (int)intForKey:(id)aKey;
- (float)floatForKey:(id)aKey;
@end

@interface NSMutableDictionary(Simson)
- (void)setInt:(int)anInt forKey:(id)aKey;
- (void)setFloat:(float)aFloat forKey:(id)aKey;
@end

@interface NSPopUpButton(simson)
- (int)tagOfTitle;
- (BOOL)selectItemWithTag:(int)tag;
@end

@interface NSTextView(Simson)
+ (void)freeParagraphs:(struct TextParagraphs *)tp;
- (void)selectFirstLine;
- (unsigned int)length;
- (NSRange)secondLineToEnd;
- (void)selectSecondLineToEnd;
- (NSRange)getParagraphRange:(int)num;
- (NSString *)getParagraph:(int)num;	// does not return trailing \n
- (struct TextParagraphs *)getParagraphsWithEncoding:(NSStringEncoding)aStringEncoding;
- (NSRectArray)getLayoutRectsWithCount:(unsigned *)rectCount;	
- (NSData *)UTF8Data;
- (NSData *)rtfData;
- (NSData *)rtfdData;
- (void)setRtfData:(NSData *)theData;
- (void)setRtfdData:(NSData *)theData;
- (void)appendString:(NSString *)aString;
- (void)appendRTFD:(NSData *)theData;
- (void)removeHighlight;
- (void)highlightRange:(NSRange)aRange;
@end


@interface NSMutableArray(Simson)
- (NSString *)stringWithPrefix:(NSString *)prefix removeFromArray:(BOOL)rfArray removePrefix:(BOOL)rPrefix;
- (void)stripSuffixFromAllStrings:(NSString *)suffix;
-(void) addUniqueObjects:(NSArray *)a2;
-(void) removeObjectsNotInArray:(NSArray *)a2;
@end

@interface NSArray(Simson)
-(NSString *)encodeAsPropertyList;
@end

@interface NSProgressIndicator(Local)
-(void)setToFull;
@end

@interface NSFormCell(Local)
-(void)increment;
@end

@interface NSFont(Simson)
-(BOOL)isBold;
-(BOOL)isItalic;
@end

@interface NSSplitView(Simson)
    - (float)position;
- (void)setPosition:(float)position;
@end

// Local Variables:
// mode:ObjC
// End:
