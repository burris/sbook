#import "XMLCoder.h"

@implementation XMLCoder
- init
{
    return [super init];
}

- (void)setUseSpaces:(BOOL)flag
{
    useSpaces = flag;
}


- (void)encodeXMLObject:(id)anObject {}
- (void)encodeXMLName:(NSString *)aName object:(id)anObject {}
- (void)encodeXMLName:(NSString *)aName intValue:(int)anInt {}
- (void)encodeXMLName:(NSString *)aName unsignedIntValue:(unsigned int)anInt {}
- (void)encodeXMLName:(NSString *)aName stringValue:(NSString *)aValue {}
- (void)encodeXMLName:(NSString *)aName binData:(NSData *)aValue {}
- (void)encodeXMLName:(NSString *)aName bin64Data:(NSData *)aValue {}
- (void)encodeXMLName:(NSString *)aName rect:(NSRect)aValue {}
- (void)encodeXMLName:(NSString *)aName subName:(NSString *)subName dictionary:(NSDictionary *)aDictionary {}

@end
