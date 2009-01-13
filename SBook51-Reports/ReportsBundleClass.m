//
//  ReportsBundleClass.m
//  ReportsBundle
//
//  Created by Simson Garfinkel on Sat Jan 10 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <RangePanel.h>
#import "AddressBookPanel.h"
#import "LabelMakerPanel.h"
#import "ReportsBundleClass.h"
#import "EnvelopePanel.h"
#import "DefaultSwitchSetter.h"
#import "SLC.h"



@implementation ReportsBundleClass

+ (void)initialize
{
    NSMutableDictionary *appDefs= [NSMutableDictionary dictionary];
    /* Printing */
    [appDefs setObject:@"0"  forKey:ENV_ICON_PRINTS_LABELS];
    [appDefs setObject:@"1"  forKey:ENV_ICON_PRINTS_RETURN_ADDRESS];

    [defaults registerDefaults:appDefs];
}


/* Print an envelope selection. To do this we need an envelopePanel.
 * If we have one, use it!
 */

-(void)printEnvelope:(Person *)aPerson
	     address:(NSString *)aString
	   forWindow:(NSWindow *)aWindow
{
    /* See if we need to load a panel */
    if(envelopePanel==nil){
	/* need to load it */
	[NSBundle loadNibNamed:@"EnvelopePanel" owner:self];
	NSAssert(envelopePanel!=nil,@"Could not load EnvelopePanel?");
    }

    /* Now use it */
    [envelopePanel setPerson:aPerson];
    [envelopePanel setAddress:aString];
    [envelopePanel runWithWindow:aWindow];
}


- (void)printEnvelopeFromSelection:sender
{
    id fr = [[NSApp keyWindow] firstResponder];
    NSString *str = @"";

    if([fr respondsToSelector:@selector(selectedRange)] &&
       [fr respondsToSelector:@selector(string)]){
	NSRange selRange = [fr selectedRange];

	str     = [[fr string] substringWithRange:selRange];
    }

    [self printEnvelope:[[[NSApp delegate] currentSLC] displayedPerson]
	  address:str
	  forWindow:[NSApp keyWindow]];

}

- (void)printAddressBook:sender
{
    SLC *slc = [[NSApp delegate] currentSLC]; // get the SLC

    addressBookPanel = [slc panelForKey:@"AddressBook"];

    if(!addressBookPanel){
	/* the SLC doesn't have an addressBookPanel; create one */
	[NSBundle loadNibNamed:@"AddressBookPanel" owner:self];
	[slc setPanel:addressBookPanel forKey:@"AddressBookPanel"];
	[addressBookPanel setSLC:slc];
    }
    [[slc rangePanel] 
	runAsSheet:[slc window]
	title:@"Address Book"
	slc:slc endTarget:addressBookPanel didEndSelector:@selector(printAddressBook2:)];
}

- (void)printMailingLabels:sender
{
    SLC *slc = [[NSApp delegate] currentSLC]; // get the SLC

    labelMakerPanel = [slc panelForKey:@"LabelMakerPanel"];

    if(!labelMakerPanel){
	/* the SLC doesn't have an mailingLabelsPanel; create one */
	[NSBundle loadNibNamed:@"LabelMakerPanel" owner:self];
	[slc setPanel:labelMakerPanel forKey:@"LabelMakerPanel"];
	[labelMakerPanel setSLC:slc];
    }
    [[slc rangePanel] 
	runAsSheet:[slc window]
	title:@"Mailing Labels"
	slc:slc endTarget:labelMakerPanel didEndSelector:@selector(printMailingLabels2:)];
}


- (void)startup:(PlugInController *)owner
{
    [owner addActionToMenu:[owner menu:@"File/Print"]
	   title:@"Mailing Labels"
	   action:@selector(printMailingLabels:)
	   target:self];
    
    [owner addActionToMenu:[owner menu:@"File/Print"]
	   title:@"Address Book"
	   action:@selector(printAddressBook:)
	   target:self];

    [owner addActionToMenu:[owner menu:@"File/Print"]
	   title:@"Envelope from Selection"
	   action:@selector(printEnvelopeFromSelection:)
	   target:self];

    [owner addActionToMenu:[owner menu:@"File/Print"]
	   title:@"Label from Selection"
	   action:@selector(printLabelFromSelection:)
	   target:self];

    [[NSApp delegate] setReportBundleClassInstance:self];

    /* Print/Mailing Labels */
    /* Print/Address Book */
    /* Print/Envelope from Selection */
    /* Print/Label from Selection */
}

@end
