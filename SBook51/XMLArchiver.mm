#import "XMLArchiver.h"
#import "SList.h"
#import "base64.h"
#import "tools.h"

static char space_buf[1024];		// a bunch of spaces

@implementation XMLArchiver
+ (void)initialize
{
    memset(space_buf,' ',sizeof(space_buf));
    space_buf[sizeof(space_buf)-1] = '\000';
    [super initialize];
}

+ (NSData *)archiveXMLObject:(id <XMLArchivableObject>)rootObject
{
    XMLArchiver *o = [[[XMLArchiver alloc] init] autorelease];

    [o setDocType:[rootObject xmlDocType]];
    [o encodeXMLObject:rootObject];
    return [o data];
}

+ (NSData *)xml10
{
    char *line1 = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    return [NSData dataWithUTF8String:line1];
}


- init
{
    self = [super init];
    depth = -1;
    return self;
}

- (void)dealloc
{
    [buf release];
    [super dealloc];
}

- (void)addSpaces:(int)n
{
    if(useSpaces){
	[buf appendBytes:space_buf length:n];
    }
}

- (NSData *)data
{
    return buf;
}

- (void)setDocType:(NSData *)aType
{
    docType = [aType retain];
}


- (void)encodeXMLObject:(id)anObject
{
    if(buf==nil){
	/* Create the BUF and put in the XML header */
	buf  = [[NSMutableData alloc] init];
    
	[buf appendData:[XMLArchiver xml10]];
	[buf appendData:docType];
    }

    if([anObject isKindOfClass:[NSArray class]]){
	id o2;
	NSEnumerator *en = [anObject objectEnumerator];
	while(o2 = [en nextObject]){
	    [self encodeXMLName:[o2 xmlName] object:o2];
	}
	return;
    }
    [self encodeXMLName:[anObject xmlName] object:anObject];
}
    
- (void)encodeXMLName:(NSString *)aName intValue:(int)anInt
{
    depth++;
    [self addSpaces:depth*4];
    [buf appendStringWithUTF8Encoding:
	     [NSString stringWithFormat:@"<%@>%d</%@>\n", aName,anInt,aName]];
    depth--;
}

- (void)encodeXMLName:(NSString *)aName unsignedIntValue:(unsigned int)anInt
{
    depth++;
    [self addSpaces:depth*4];
    [buf appendStringWithUTF8Encoding:[NSString stringWithFormat:@"<%@>%u</%@>\n",
				aName,anInt,aName]];
    depth--;
}

- (void)encodeXMLName:(NSString *)aName object:(id)object
{
    NSString *version = nil;
    NSString *attrs   = [object xmlAttributes];

    if([object respondsToSelector:@selector(version)]){
	version = [NSString stringWithFormat:@" version=\"%d\"",[object version]];
    }

    depth++;
    [self addSpaces:depth*4];
    [buf appendChar:'<'];
    [buf appendStringWithUTF8Encoding:aName];
    if(version) [buf appendStringWithUTF8Encoding:version];
    if(attrs){
	[buf appendChar:' '];
	[buf appendStringWithUTF8Encoding:attrs];
    }
    [buf appendChar:'>'];
    [buf appendChar:'\n'];
    [object encodeWithXMLCoder:self];
    [self addSpaces:depth*4];
    [buf appendChar:'<'];
    [buf appendChar:'/'];
    [buf appendStringWithUTF8Encoding:aName];
    [buf appendChar:'>'];
    [buf appendChar:'\n'];
    depth--;
}

- (void)encodeXMLName:(NSString *)aName rect:(NSRect)rect
{
    [self encodeXMLName:aName stringValue:NSStringFromRect(rect)];
}

- (void)encodeXMLName:(NSString *)aName bin64Data:(NSData *)theData
{
    /* Dump base64 that is already encoded */
    depth++;
    [self addSpaces:depth*4];
    [buf appendStringWithUTF8Encoding:[NSString stringWithFormat:@"<%@>", aName]];
    [buf appendData:theData];
    [buf appendStringWithUTF8Encoding:[NSString stringWithFormat:@"</%@>\n",aName]];
    depth--;
}


- (void)encodeXMLName:(NSString *)aName binData:(NSData *)theData
{
    /* Dump as base64 */
    depth++;
    [self addSpaces:depth*4];
    [buf appendStringWithUTF8Encoding:[NSString stringWithFormat:@"<%@>", aName]];
    [buf appendStringWithUTF8Encoding:[theData base64]];
    [buf appendStringWithUTF8Encoding:[NSString stringWithFormat:@"</%@>\n",aName]];

    depth--;
}

- (void)encodeXMLName:(NSString *)aName subName:(NSString *)subName
	   dictionary:(NSDictionary *)aDictionary
{
    NSEnumerator *en = [aDictionary keyEnumerator];;
    NSObject *key;
    [buf appendStringWithUTF8Encoding:
	     [NSString stringWithFormat:@"<%@>\n", aName]];
    while(key = [en nextObject]){
	[buf appendStringWithUTF8Encoding:
		 [NSString stringWithFormat:@"    <%@ key=\"%@\" value=\"%@\"/>\n",
			   subName, key, [aDictionary objectForKey:key] ]];
    }
    [buf appendStringWithUTF8Encoding:[NSString stringWithFormat:@"</%@>\n",aName]];
}



- (void)encodeXMLName:(NSString *)aName stringValue:(NSString *)theString
{
    const unsigned char  *cc;
    const unsigned char *bytes = (unsigned char *)[theString UTF8String];

    depth++;
    [self addSpaces:depth*4];
    [buf appendStringWithUTF8Encoding:[NSString stringWithFormat:@"<%@>", aName]];

    /* Now quote the string */
    for(cc=bytes;*cc;cc++){
	switch(*cc){
	case '&':
	    [buf appendCString:"&amp;"];
	    break;
	case '<':
	    [buf appendCString:"&lt;"];
	    break;
	case '>':
	    [buf appendCString:"&gt;"];
	    break;
	case '\n':
	    [buf appendCString:"\n"];
	    break;
	case '\t':			// preserve tabs
	    [buf appendCString:"\t"];
	    break;
	default:
	    if(*cc<32) break;		// don't put it in
	    [buf appendBytes:cc length:1];
	    break;
	}
    }
    [buf appendStringWithUTF8Encoding:[NSString stringWithFormat:@"</%@>\n",aName]];
    depth--;
}



@end
