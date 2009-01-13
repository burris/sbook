#import <Cocoa/Cocoa.h>
#import "XMLCoder.h"

@protocol XMLArchivableObject
- (NSString *)xmlName;
- (NSData *)xmlDocType;
- (void)encodeWithXMLCoder:(XMLCoder *)anArchiver;
- (NSString *)xmlAttributes;
@end

@interface XMLArchiver : XMLCoder 
{
    NSMutableData *buf;
    NSData *docType;
    int depth;
}
+ (NSData *)xml10;			// header with ?xml
+ (NSData *)archiveXMLObject:(id <XMLArchivableObject>)rootObject;
- (void)setDocType:(NSData *)aType;
- (id)init;
- (NSData *)data;
@end


