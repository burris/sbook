//
//  DialerBundleClass.m
//  DialerBundle
//
//  Created by Simson Garfinkel on Sat Jan 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "DialerBundleClass.h"
#import "DialerPanel.h"

#import <PlugInController.h>
#import <DefaultSwitchSetter.h>
#import <SBookController.h>

@implementation DialerBundleClass

+(void)initialize
{
    NSMutableDictionary *appDefs= [NSMutableDictionary dictionary];

    /* Modem */
    [appDefs setObject:[NSNumber numberWithBool:YES] forKey:DEF_USE_TOUCHTONE];
    [appDefs setObject:[NSNumber numberWithInt:1] forKey:DEF_KEEP_MODEM_AFTER_DIALING];
    [appDefs setObject:[NSNumber numberWithInt:5] forKey:DEF_HOLD_MODEM_MINUTES];
    [appDefs setObject:@"/dev/cu.modem" forKey:DEF_MODEM_DEVICE];
    [appDefs setObject:@"ATL2" forKey:DEF_MODEM_INIT_STRING];
    [appDefs setObject:@"9"  forKey:DEF_DROP_PHONE_SECONDS];
    [appDefs setObject:@"0"  forKey:DEF_GRAB_MODEM_ON_STARTUP];

    [defaults registerDefaults:appDefs];
}

-(void)startup:(PlugInController *)owner
{
    SBookController *sbc = [NSApp delegate];

    [owner installPreference:@"Modem" view:dialerPrefPanel];
    [sbc setDialerPanel:[DialerPanel sharedDialerPanel]];

    if([[defaults objectForKey:DEF_GRAB_MODEM_ON_STARTUP] intValue]){
	[[DialerPanel sharedDialerPanel] openModemForWindow:nil andOrderOut:YES];
    }

    /* Create the special menu options */

    [owner addActionToMenu:[owner menu:@"Special"]
	   title:@"Release Modem"
	   action:@selector(releaseModem:)
	   target:[DialerPanel sharedDialerPanel]];
}

-(void)awakeFromNib
{
    setDefault(modem_grabModem,DEF_GRAB_MODEM_ON_STARTUP);
    setDefault(modem_keepMatrix,DEF_KEEP_MODEM_AFTER_DIALING);
    setDefault(modem_holdModemMinutes,DEF_HOLD_MODEM_MINUTES);
    setDefault(modem_useTouchTone,DEF_USE_TOUCHTONE);
    setDefault(modem_device,DEF_MODEM_DEVICE);
    setDefault(modem_initString,DEF_MODEM_INIT_STRING);
    setDefault(modem_dropSeconds,DEF_DROP_PHONE_SECONDS);
}

- (void)modem_testModem:(id)sender
{
    DialerPanel *dp = [DialerPanel sharedDialerPanel];

    [dp setDialingTitle:@"International Number"];
    [dp dial:@"55" forWindow:[sender window]];
}



@end
