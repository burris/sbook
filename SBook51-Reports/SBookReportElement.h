/* SBookReportElement */

#import <Cocoa/Cocoa.h>

@class Person;
@interface SBookReportElement : AbstractReportElement
{
    Person		*person;	// who we are pointing at
}
- initPerson:(Person *)aPerson panel:(AbstractReportPanel *)aPanel view:(AbstractReportView *)aView;
- (Person *)person;
- (void)setPerson:(Person *)aPerson;

@end
