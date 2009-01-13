/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law.
 *
 */

#import <Cocoa/Cocoa.h>

@interface Emailer:NSObject
{
}

+ (void)sendMailTo:(NSString *)to cc:(NSString *)cc subject:(NSString *)subject body:(NSString *)body;
#if 0
+ sendEmail:text paragraph:(int)graph forPerson:person;
+ (char *)emailAddressForBuf:(NSString *)inbuf;
+ (char *)emailAddressForUsername:(NSString *)username realname:(NSString *)realname;
#endif
@end
