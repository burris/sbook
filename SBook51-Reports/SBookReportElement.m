#import "SBookReportElement.h"

@implementation SBookReportElement

- initPerson:(Person *)aPerson panel:(AbstractReportPanel *)aPanel view:(AbstractReportView *)aView
{
    [super initPanel:aPanel view:aView];
    person= [aPerson retain];
    return self;
}

- (void)dealloc
{
    [person release];
    [super dealloc];
}

- (void)setPerson:aPerson
{
    [person release];
    person=[aPerson retain];
}

- (Person *)person 	{ return person; 	}
@end
