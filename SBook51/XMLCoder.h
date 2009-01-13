/*
 * (C) Copyright 2001 by Simson L. Garfinkel
 *
 */

#import <Cocoa/Cocoa.h>

/* XMLCoder.h:
 *
 * A quick-and-dirty XML coder
 */

@interface XMLCoder : NSObject 
{
    BOOL useSpaces;			// do we archive with spaces?
}
- (void)setUseSpaces:(BOOL)flag;
- (void)encodeXMLObject:(id)anObject;
- (void)encodeXMLName:(NSString *)aName object:(id)anObject;
- (void)encodeXMLName:(NSString *)aName intValue:(int)anInt;
- (void)encodeXMLName:(NSString *)aName unsignedIntValue:(unsigned int)anUnsignedInt;
- (void)encodeXMLName:(NSString *)aName stringValue:(NSString *)aValue;
- (void)encodeXMLName:(NSString *)aName binData:(NSData *)aValue; // code an NSData as base64
- (void)encodeXMLName:(NSString *)aName bin64Data:(NSData *)aValue; // aValue is already base64
- (void)encodeXMLName:(NSString *)aName rect:(NSRect)aValue;
- (void)encodeXMLName:(NSString *)aName subName:(NSString *)subName dictionary:(NSDictionary *)aValue;
@end


