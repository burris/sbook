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

#import "Person.h"
#import "LabelView.h"
#import "LabelMakerPanel.h"
#import "LabelElement.h"
#import "SList.h"
#import "SLC.h"
#import "SBookController.h"
#import "ZoomScrollView.h"

#include <sys/types.h>
#include <regex.h>

@implementation LabelMakerPanel

- (void)dealloc
{
    [super dealloc];
}

- (AbstractReportElement *)newElementForPerson:(Person *)aPerson
{
    id elem = [[LabelElement alloc] initPerson:aPerson
				    labelView:(LabelView *)preview];

    if(aPerson){
	[elem addLine:[aPerson cellName:[self displayLastnameFirst]]
	      tag:[aPerson sbookTagForLine:0] & P_BUT_MASK];
    }
    return [elem autorelease];
}


- (BOOL)showEntryLabels
{
    return NO;
}




int	compar(const void *v1,const void *v2)
{
    LabelElement	*label1 = *(id *)v1;
    LabelElement	*label2 = *(id *)v2;
    int sortByZip = 0;

    if(sortByZip){
	NSString *zip1 = [label1 zip];
	NSString *zip2 = [label2 zip];

	if(zip1==0) return -1;
	if(zip2==0) return 1;
	return [zip1 caseInsensitiveCompare:zip2];
    }
    else{
	Person	*per1 = [label1 person];
	Person	*per2 = [label2 person];

	return [per1 compareTo:per2];
    }

}


/****************************************************************
 *** Report generation
 ****************************************************************/

- (BOOL)shouldStartNewEntry:(int)tag lastTag:(int)lastTag
{
    if([entireEntryOnLabelCell intValue]) return NO;
    return [super shouldStartNewEntry:tag lastTag:lastTag];
}

- (IBAction)changedSelectionCriteria:sender
{
    if(oneLabel){ return;    }
    [super changedSelectionCriteria:sender];
}

- (void)prepareForReport
{
    [zoomScrollView setScaleFactor:0.50]; // it's nice
    [super prepareForReport];
}

- (void)generateReportForPeople:(NSArray *)peopleArray
{
    oneLabel = NO;
    [super generateReportForPeople:peopleArray];
}

- (void)generateLabelForString:(NSString *)str
{
    LabelElement *lab = [[[LabelElement alloc] initPerson:nil
					       labelView:(LabelView *)preview] autorelease];


    [self prepareForReport];
    oneLabel = YES;
    [lab	addLine:str tag:P_BUT_ADDRESS];			// add the text
    [preview	addReportElement:lab];
    [preview	setNumPages:1];
    [preview	changedLayoutInformation:nil];
    
    /* Bring up the panel */
    [self	runAsSheet:[slc window]
		modalDelegate:self
		didEndSelector:@selector(reportFinished:)
		contextInfo:nil ];

    /* Ugly hack, but it seems to be needed */
    [NSTimer scheduledTimerWithTimeInterval:0.0
	     target:preview
	     selector:@selector(changedLayoutInformation:) userInfo:nil repeats:NO];


}

- (IBAction)printMailingLabels2:(NSArray *)selected
{
    [self generateReportForPeople:selected];
}


@end
