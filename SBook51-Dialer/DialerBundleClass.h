//
//  DialerBundleClass.h
//  DialerBundle
//
//  Created by Simson Garfinkel on Sat Jan 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DialerBundleClass : NSObject
{
    IBOutlet NSPanel *dialerPanel;
    IBOutlet NSView  *dialerPrefPanel;

    /* Modem */
    IBOutlet NSButton *modem_grabModem;
    IBOutlet NSTextField *modem_dropSeconds;
    IBOutlet NSButton *modem_useTouchTone;
    IBOutlet NSTextField *modem_holdModemMinutes;
    IBOutlet NSTextField *modem_device;
    IBOutlet NSTextField *modem_initString;
    IBOutlet NSMatrix *modem_keepMatrix;
}

- (IBAction)modem_testModem:(id)sender;
@end

/* Preferences */
#define DEF_DROP_PHONE_SECONDS		@"DropPhoneSeconds"
#define DEF_GRAB_MODEM_ON_STARTUP	@"GrabModemOnStartup"
#define DEF_HOLD_MODEM_MINUTES		@"HoldModemMinutes"
#define DEF_KEEP_MODEM_AFTER_DIALING	@"KeepModemAfterDialing"
#define DEF_MODEM_DEVICE		@"ModemDevice"
#define DEF_MODEM_INIT_STRING		@"ModemInitString"
#define DEF_USE_TOUCHTONE               @"UseTouchtone"

