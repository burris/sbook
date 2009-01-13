//
//  ABPersonAdditions.m
//  SyncBundle
//
//  Created by Simson Garfinkel on Wed Dec 31 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ABPersonAdditions.h"
#import "tools.h"


@implementation ABPerson(Additions)
-(time_t)mtime
{
    return [[self valueForProperty:kABModificationDateProperty] time_t];
}

-(void)setMtime:(time_t)mtime
{
    struct tm *tm = localtime(&mtime);
    [self setValue:[NSCalendarDate dateWithYear:tm->tm_year+1900
				   month:tm->tm_mon+1
				   day:tm->tm_mday
				   hour:tm->tm_hour
				   minute:tm->tm_min
				   second:tm->tm_sec
				   timeZone:[NSTimeZone systemTimeZone]]
	  forProperty:kABModificationDateProperty];
}

-(void)setCtime:(time_t)ctime
{
    struct tm  *tm = localtime(&ctime);
    [self setValue:[NSCalendarDate dateWithYear:tm->tm_year+1900
				   month:tm->tm_mon+1
				   day:tm->tm_mday
				   hour:tm->tm_hour
				   minute:tm->tm_min
				   second:tm->tm_sec
				   timeZone:[NSTimeZone systemTimeZone]]
	  forProperty:kABCreationDateProperty];
}

-(time_t)syncTime
{
    NSCalendarDate *syncTime = [self valueForProperty:@"syncTime"];
    if(syncTime) return [syncTime time_t];
    return 0;				// no syncTime was recorded...
}

/****************************************************************
 ** Label management
 ****************************************************************/

-(void)addLabelsForProperty:(NSString *)propertyName toArray:(NSMutableArray *)array
{
    id property = [self valueForProperty:propertyName];
    unsigned int i;
    for(i=0;i<[property count];i++){
	NSString *str = [property labelAtIndex:i];
	if([array containsObject:str]==NO){
	    [array addObject:str];
	}
    }
}

-(BOOL)hasLabel:(NSString *)aLabel
{
    NSMutableArray *array = [NSMutableArray array];
    [self addLabelsForProperty:@"Address" toArray:array];
    [self addLabelsForProperty:@"Phone" toArray:array];
    [self addLabelsForProperty:@"Email" toArray:array];
    [self addLabelsForProperty:@"AIMInstant" toArray:array];
    [self addLabelsForProperty:@"ICQInstant" toArray:array];
    [self addLabelsForProperty:@"JabberInstant" toArray:array];
    [self addLabelsForProperty:@"MSNInstant" toArray:array];
    return [array containsObject:aLabel];
}




void take(NSMutableString *ret,NSMutableDictionary *dict,NSString *key,NSString *append)
{
    NSString *val = [dict valueForKey:key];
    if(val){
	[ret appendString:val];
	if(append) [ret appendString:append];
	[dict removeObjectForKey:key];
    }
}

NSString *unprefixedLabel(NSString *label)
{
    if([label hasPrefix:@"_$!<"] && [label hasSuffix:@">!$_"]){
	label = [label substringWithRange:NSMakeRange(4,[label length]-8)];
    }
    return label;
}

NSString *stringValueForLabel(id person,NSString *propertyName,NSString *label)
{
    id property = [person valueForProperty:propertyName];
    unsigned int i=0;
    for(i=0;i<[property count];i++){
	if([label isEqualToString:[property labelAtIndex:i]]){
	    id ret = [property valueAtIndex:i];

	    /* If it is a string, just return it */
	    if([ret respondsToSelector:@selector(length)]){
		return ret;
	    }
	    
	    /* If it is a dictionary, get out the stuff we know how to get out,
	     * then get out the rest
	     */
	    if([ret isKindOfClass:[NSDictionary class]]){
		NSMutableDictionary *dict = [ret mutableCopy];
		ret = [NSMutableString string];	// we are going to put it here
		take(ret,dict,@"Street",@"\n");
		take(ret,dict,@"City",@", ");
		take(ret,dict,@"State",@" ");
		take(ret,dict,@"ZIP",@"\n");
		take(ret,dict,@"Country",@"\n");

		NSEnumerator *en = [dict keyEnumerator];
		NSString *key;
		while(key = [en nextObject]){
		    take(ret,dict,key,nil);
		}
		return ret;
	    }
	    NSLog(@"don't know how to convert %@",ret);
	    return [ret description];
	}
    }
    return nil;
}


void appendIfKey(NSMutableString *res,id str,NSString *key,NSString *extra)
{
    NSString *s2 = [str valueForKey:key];
    if(s2){
	[res appendString:s2];
	[res appendString:extra];
    }
}

-(NSString *)stringWithDefaultLabel:(NSString *)defaultLabel
{
    NSMutableString *res = [NSMutableString string];
    NSMutableArray  *abpersonLabels = [NSMutableArray array];
    NSString *groups[]  = {@"Address",@"Phone",@"Email",@"AIMInstant",
			   @"ICQInstant",@"JabberInstant",@"MSNInstant",
			   0};
    const int AIM=3;
    const int ICQ=4;
    const int Jabber=5;
    const int MSN=6;
    int i;
    
    /* Find all the labels that are in the ABPerson.
     * We do this so that the same label from different groups
     * are put together.
     */
    for(i=0;groups[i];i++){
	[self addLabelsForProperty:groups[i] toArray:abpersonLabels];
    }

    NSEnumerator *en = 0;
    NSString *label = 0;
    NSString *note = [self valueForProperty:@"Note"];
    

    /* Create 'first last' as the first line if either are present */
    [res appendString:[self cellName]];
    [res chomp];
    if([res length]>0) [res appendString:@"\n"];

    /* Handle any singles.
     * For each one, don't put it the result if it is in the note,
     * as the note will be added.
     */
    NSString *jobTitle = [self valueForProperty:@"JobTitle"];
    if([jobTitle length] > 0 && [note containsSubstring:jobTitle]==NO){
	[res appendString:jobTitle];
	[res appendString:@"\n"];
    }

    NSString *organization = [self valueForProperty:@"Organization"];
    if([organization length] > 0 && [note containsSubstring:organization]==NO){
	[res appendString:organization];
	[res appendString:@"\n"];
    }

    /* Now handle the person labels.
     * For each one, add if it is not in the note.
     */
    en = [abpersonLabels objectEnumerator];
    while(label = [en nextObject]){
	BOOL addedLabel = NO;
	
	for(i=0;groups[i];i++){
	    NSMutableString *str = [[stringValueForLabel(self,groups[i],label) mutableCopy]
				       autorelease];

	    if(!str) continue;
	    if([str length]>0 && [note containsSubstring:str]==NO){
		/* Do we need to add the label? */
		if(addedLabel==NO){
		    if([label compare:defaultLabel] != 0){ // don't prefix with default label
			[res appendString:@"\n"];
			[res appendString:unprefixedLabel(label)];

			switch(i){
			case 0:  [res appendString:@":\n"];break;
			default: [res appendString:@": "];break;
			}
			addedLabel = YES;
		    }
		    
		    if(addedLabel == NO && i==3){
			[res appendString:@" AIM: "];
			addedLabel = YES;
		    }
		}
		/* Add the entry */
		[res appendString:str];

		/* Add IM stuff */
		switch(i){
		case AIM:  [res appendString:@" (AIM)"];break;
		case ICQ:  [res appendString:@" (ICQ)"];break;
		case Jabber:  [res appendString:@" (Jabber)"];break;
		case MSN:  [res appendString:@" (MSN)"];break;
		}

		if([str lastChar]!='\n') [res appendString:@"\n"];
	    }
	}
    }
    
    /* Get the HomePage */
    NSString *single = [self valueForProperty:@"HomePage"];
    if([single length]>0 && [note containsSubstring:single]==NO){
	[res appendString:single];
	[res appendString:@"\n"];
    }

    /* Finally, add the note */
    /* See if there is a note; add it if there is */

    if(note && [note length]>0){
	[res appendString:@"\n"];
	[res appendString:note ];
	if([note lastChar]!='\n') [res appendString:@"\n"];
    }
    return res;
}


- (NSString *)cellName
{
    NSString *first = [self valueForProperty:kABFirstNameProperty];
    NSString *last  = [self valueForProperty:kABLastNameProperty];
    NSMutableString *res = [NSMutableString string];

    if([first length]>0) [res appendString:first];
    if([first length]>0 && [last length]>0) [res appendString:@" "];
    if([last length]>0) [res appendString:last];

    return res;
}

- (NSString *)printableName
{
    NSString *str = [self cellName];
    if([str length]) return str;
    str = [self valueForProperty:kABOrganizationProperty];
    if([str length]) return str;
    return @"(no name)";
}

@end
