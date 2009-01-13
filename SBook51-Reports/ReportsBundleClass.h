//
//  ReportsBundleClass.h
//  ReportsBundle
//
//  Created by Simson Garfinkel on Sat Jan 10 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SBookController.h"

@class EnvelopePanel;
@class AddressBookPanel;
@class LabelMakerPanel;
@interface ReportsBundleClass : NSObject <ReportClassInstance>
{
    IBOutlet EnvelopePanel	*envelopePanel;
    IBOutlet AddressBookPanel	*addressBookPanel;
    IBOutlet LabelMakerPanel	*labelMakerPanel;
}

@end
