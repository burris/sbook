/*
 * (C) Copyright 1992,2002 by Simson Garfinkel and Associates, Inc.
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law..
 *
 */

#import "Emailer.h"
#import "Person.h"
#import "defines.h"
#import "tools.h"


#if 0
static void quotedAppend(NSMutableString *str,NSString *field,NSString *value)
{
    unsigned int i;
    
    [str appendString:field];
    for(i=0;i<[value length];i++){

	unichar ch = [value characterAtIndex:i];
	switch(ch){
	case ' ':
	    [str appendString:@"+"];
	    break;
	case '<':
	    [str appendString:@"&lt;"];
	    break;
	case '>':
	    [str appendString:@"&gt;"];
	    break;
	default:
	    [str appendString:[NSString stringWithCharacters:&ch length:1]];
	    break;
	}
    }
}
#endif


static void append3(NSMutableString *str,NSString *field,NSString *value,NSString *v3)
{
    [str appendString:field];
    [str appendString:value];
    [str appendString:v3];
}

static NSString *quote(NSString *s)
{
    unsigned int i;
    NSMutableString *r = [[s mutableCopy] autorelease];
    for(i=0;i<[r length];i++){
	if([r characterAtIndex:i]==' '){
	    [r replaceCharactersInRange:NSMakeRange(i,1) withString:@"%20"];
	}
    }
    return r;
}


@implementation Emailer

+ (void)sendMailTo:(NSString *)to cc:(NSString *)cc subject:(NSString *)subject
 	body:(NSString*)body
{
    NSMutableString *url = [NSMutableString stringWithFormat:@"mailto:%@",to];
    
    int lsubject = [subject length];
    int lbody    = [body length];
    int lcc      = [cc length];

    subject = quote(subject);
    body    = quote(body);
    cc      = quote(cc);

    if(lsubject || lbody || lcc){
	[url appendString:@"?"];

	if([subject length])	append3(url,@"subject=",subject,@"&");
	if([body length])	append3(url,@"body=",body,@"&");
	if([cc length])		append3(url,@"cc=",cc,@"&");
    }
    
    NSLog(@"url=%@",url);

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

@end
