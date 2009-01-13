#import "PassphrasePanel.h"
#import "md5.h"

@implementation PassphrasePanel

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter]
	addObserver:self
	selector:@selector(textDidChange:)
	name:NSControlTextDidChangeNotification
	object:phrase1];

    [[NSNotificationCenter defaultCenter]
	addObserver:self
	selector:@selector(textDidChange:)
	name:NSControlTextDidChangeNotification
	object:phrase2];

}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (int)run
{
    [okayButton setEnabled:NO];
    [phrase1 setStringValue:@""];
    [phrase2 setStringValue:@""];
    return [super run];
}

- (void)textDidChange:(NSNotification *)notification
{
    NSString *str1 = [phrase1 stringValue];

    if([str1 length]==0){
	[okayButton setEnabled:NO];
    }

    if(phrase2){
	NSString *str2 = [phrase2 stringValue];
	if([str1 isEqualToString:str2]==NO){
	    [okayButton setEnabled:NO];
	    return;
	}
    }

    [okayButton setEnabled:YES];
}

- (NSData *)key
{
    NSMutableString *str2 = [NSMutableString stringWithString:[phrase1 stringValue]];
    const char *cstr;
    NSMutableData *newKey = [NSMutableData dataWithLength:16];

    [str2 appendString:@"SBookSalt"];	// make it a bit bigger
    
    cstr = [str2 UTF8String];
    MD5FromBuffer((unsigned char *)cstr,strlen(cstr),(unsigned char *)[newKey mutableBytes]);
    return newKey;
}

@end
