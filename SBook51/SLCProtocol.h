/*
 *  SLCProtocol.h
 *  SBook5
 *
 *  Created by Simson Garfinkel on Tue Dec 30 2003.
 *  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
 *
 */

@class Person;
@protocol SLCProtocol
- (void)addPersonToVisibleList:(Person *)aPerson;
- (void)setStatus:(NSString *)aStatusMessage;
- (void)removePersonFromVisibleList:(Person *)aPerson;
@end
