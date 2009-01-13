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

#import "AddressBookPanel.h"
#import "AddressBookView.h"
#import "AddressElement.h"
#import "Person.h"
#import "SList.h"
#import "SLC.h"
#import "SBookController.h"
#import "MultiPageView.h"
//#import "tools.h"
#import "FontWell.h"
#import "ZoomScrollView.h"

#import <stdlib.h>
#import <string.h>

@implementation AddressBookPanel

- (void)dealloc
{
    [super dealloc];
}

- (AbstractReportElement *)newElementForPerson:(Person *)aPerson
{
    id elem = [[AddressElement alloc] initPerson:aPerson panel:self view:preview];
    return [elem autorelease];
}

- (BOOL)showEntryLabels
{
    return YES;
}

/****************************************************************
 *** Report generation
 ****************************************************************/

- (void)prepareForReport
{
    [zoomScrollView setScaleFactor:0.50]; // it's nice
    [super prepareForReport];
}

- (IBAction)proceed:(id)sender
{
    [multiPageView print:sender];
    [super proceed:sender];
}


- (IBAction)printAddressBook2:(NSArray *)selected
{
    [self generateReportForPeople:selected];
}




@end
