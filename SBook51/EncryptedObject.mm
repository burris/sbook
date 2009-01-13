/*
 * EncryptedObjectt.h
 */

#import "EncryptedObject.h"
#import "XMLCoder.h"
#import "XMLArchiver.h"
#import "md5.h"
#import "blowfish.h"

@implementation EncryptedObject 

+ (NSData *)plaintext:(NSData *)plaintext andKey:(NSData *)aKey;
{
    NSMutableData *edata = [NSMutableData dataWithData:plaintext];
    int	pad;
    BF_KEY bfkey;
    unsigned char iv[256];		// initialization vector
    NSMutableData *md5 = [NSMutableData dataWithLength:16];

    /* Calculate the MD5 */
    MD5FromBuffer((unsigned char *)[plaintext bytes],
		  [plaintext length],
		  (unsigned char *)[md5 mutableBytes]);
    

    /* Determine how many pad bytes are needed */
    pad = 16 - [edata length] & 0x000f;
    pad = pad % 16;
    
    /* Pad it out with spaces */
    [edata appendBytes:"                " length:pad];

    /* Set the key and the IV */
    BF_set_key(&bfkey,[aKey length],(unsigned char *)[aKey bytes]);
    memset(iv,0,sizeof(iv));

    /* And encrypt the data in place */
    BF_cbc_encrypt((const unsigned char *)[edata mutableBytes],
		   (unsigned char *)[edata mutableBytes],
		   [edata length],
		   &bfkey,iv,1);
    
    /* Create the object we will return */

    return [[[EncryptedObject alloc]
		initWithEncryptedData:edata plaintextLen:[plaintext length] plaintextMD5:md5]
		autorelease];
}

- initWithEncryptedData:(NSData *)aData plaintextLen:(int)len plaintextMD5:(NSData *)md5
{
    [super init];
    
    theEncryptedData = [aData retain];
    plaintextLen = len;
    plaintextMD5 = [md5 retain];
    return self;
}

- (NSString *)xmlAttributes
{
    return nil;
}



- (void)dealloc
{
    [theEncryptedData release];
    [plaintextMD5 release];
    [super dealloc];
}

- (void)setEncryptedData:(NSData *)aData
{
    theEncryptedData = [aData retain];
}
    
- (void)setLen:(int)len
{
    plaintextLen = len;
}
    
- (void)setMD5:(NSData *)md5
{
    plaintextMD5 = [md5 retain];
}


- (NSString *)xmlName
{
    return @"EncryptedObject";
}

- (NSData *)xmlDocType
{
    char *type = "<!DOCTYPE entries PUBLIC \"-//Simson L. Garfinkel// DTD SBook5 //EN//XML\" "
	"\"http://www.simson.net/sbook/1.0/EncryptedObject.dtd\">\n";

    return [NSData dataWithBytes:type length:strlen(type)];
}

- (void)encodeWithXMLCoder:(XMLCoder *)aCoder
{
    [aCoder setUseSpaces:NO];
    [aCoder encodeXMLName:@"edata"	binData:theEncryptedData];
    [aCoder encodeXMLName:@"length"	intValue:plaintextLen];
    [aCoder encodeXMLName:@"md5"	binData:plaintextMD5];
}

- (NSData *)decryptWithKey:(NSData *)aKey
{
    BF_KEY bfkey;
    unsigned char iv[256];			// initialization vector
    NSMutableData *plaintext;
    NSMutableData *md52 = [NSMutableData dataWithLength:16];

    if(plaintextLen > [theEncryptedData length]){
	return nil;			// something is wrong here
    }
    plaintext = [NSMutableData dataWithLength:[theEncryptedData length]];

    /* Create the key */
    BF_set_key(&bfkey,[aKey length],(unsigned char *)[aKey bytes]);
    memset(iv,0,sizeof(iv));

    /* Decrypt into the new location */
    BF_cbc_encrypt((unsigned char *)[theEncryptedData bytes],
		   (unsigned char *)[plaintext mutableBytes],
		   [theEncryptedData length],
		   &bfkey,iv,0);

    /* Set the length */
    [plaintext setLength:plaintextLen];

    /* Now validate the MD5 */
    MD5FromBuffer((unsigned char *)[plaintext bytes],
		  [plaintext length],
		  (unsigned char *)[md52 mutableBytes]);

    if([plaintextMD5 isEqualToData:md52]){
	return plaintext;
    }
    return nil;				// not implemented yet
}
@end
