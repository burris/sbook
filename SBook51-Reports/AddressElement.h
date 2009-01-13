/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2002 by Simson L. Garfinkel
 *
 * All Rights Reserved.
 *
 * AddressElement is an element that can display a collection of lines.
 * It remembers the tag for each line and displays each line with the
 * appropriate font of its controlling view. 
 *
 * format:
 *
 * NAME
 * label:
 * address1		phone1
 * address2		phone2
 * address3		phone3
 */

#import "AbstractReportElement.h"

@class Person;
@class AddressElementLine;

@interface AddressElement:AbstractReportElement
{
    Person	*person;
    NSString	*personName;
    NSRect	personNameRect;
    BOOL 	displayPersonName;
    float	addressWidth;		
    float	phoneWidth;		
    float	phoneSpaceDown;
    NSMutableArray *lines;
    AbstractReportPanel *panel;
    AbstractReportView *view;
}

- initPerson:(Person *)aPerson panel:(AbstractReportPanel *)aPanel view:(AbstractReportView *)aView;
- (Person *)person;
- (void)addLine:(NSString *)buf tag:(int)tag;
- (void)setWidth:(float)aWidth phoneWidth:(float)phoneNumberWidth;
- (void)setDisplayPersonName:(BOOL)flag;
- (void)set;				// calculate the widths and heights
- (float)height;		
- (NSString *)personName;

#define ADDRESS_INDEX 0
#define PHONE_INDEX 1
#define PHONEWITHLABEL_INDEX 2

@end

  
