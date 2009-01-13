/*
 * EncryptedObject.h
 */

#import <Cocoa/Cocoa.h>
#import "XMLArchiver.h"

@interface EncryptedObject : NSObject <XMLArchivableObject>
{
    /* These values are archived */
    NSData	*theEncryptedData;
    unsigned int plaintextLen;
    NSData	*plaintextMD5;			// the MD5 of the unencrypted; verifies decryption
}

/* Create an encrypted object */
+ (NSData *)plaintext:(NSData *)plaintext andKey:(NSData *)aKey;
- initWithEncryptedData:(NSData *)aData plaintextLen:(int)len plaintextMD5:(NSData *)md5;
- (void)setEncryptedData:(NSData *)aData;
- (void)setLen:(int)len;
- (void)setMD5:(NSData *)md5;
- (NSData *)decryptWithKey:(NSData *)aKey;	
@end
