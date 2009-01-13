//
//  ABPersonAdditions.h
//  SyncBundle
//
//  Created by Simson Garfinkel on Wed Dec 31 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AddressBook/AddressBook.h>


@interface ABPerson(Additions)
-(time_t)mtime;
-(time_t)syncTime;
-(void)setMtime:(time_t)mtime;
-(void)setCtime:(time_t)ctime;
-(NSString *)stringWithDefaultLabel:(NSString *)aString;		// returns the string for the ABPerson
-(NSString *)cellName;			// "firstname lastname"
- (NSString *)printableName;		// name or company name
-(BOOL)hasLabel:(NSString *)aLabel;
-(void)addLabelsForProperty:(NSString *)propertyName toArray:(NSMutableArray *)array;
@end
