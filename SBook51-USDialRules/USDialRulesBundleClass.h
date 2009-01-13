/* USDialRulesBundleClass */

#import <Cocoa/Cocoa.h>

#import <SBookController.h>

@class SBookController;
@interface USDialRulesBundleClass : NSObject <SBookLocalizedDialer>
{
    IBOutlet NSView *usDialRulesPrefPanel;

    /* Dialing */
    IBOutlet NSTextField *dialing_defaultAreaCode;

    IBOutlet NSTextField *dialing_localAreaCodes;
    IBOutlet NSTextField *dialing_localDialingPrefix;
    IBOutlet NSButton    *dialing_phoneCompanyRequires10Digit;

    IBOutlet NSTextField *dialing_yourCountryCode;
    IBOutlet NSTextField *dialing_longDistanceDialingPrefix;
    IBOutlet NSTextField *dialing_internationalDialingPrefix;

    IBOutlet NSButton *dialing_enableSpecialExchangeProcessing;
    IBOutlet NSTextField *dialing_specialExchanges;
    IBOutlet NSTextField *dialing_specialDialingPrefix;
    //IBOutlet id		dialing_special_label1;
    //IBOutlet id		dialing_special_label2;
    //IBOutlet id		dialing_special_label3;

    SBookController *sbc;

}
@end


/* Dialing Preferences */
#define DEF_DEF_AREACODE		@"DefaultAreaCode"
#define DEF_YOUR_COUNTRY_CODE		@"YourCountryCode"

#define DEF_LOCAL_AREACODES		@"LocalAreaCodes"
#define DEF_LOCAL_DIALING_PREFIX	@"LocalDialingPrefix"
#define DEF_REQUIRE_10_DIGIT_DIALING	@"Require10DigitDialing"

#define DEF_LONG_DISTANCE_DIALING_PREFIX @"LongDistanceDialingPrefix"
#define DEF_INTERNATIONAL_DIALING_PREFIX @"InternationalDialingPrefix"

#define DEF_ENABLE_SPECIAL_EXCHANGE_PROCESSING @"EnableSpecialExchangeProcessing"
#define DEF_SPECIAL_TELEPHONE_EXCHANGES		@"SpecialTelephoneExchanges"
#define DEF_SPECIAL_EXCHANGE_DIALING_PREFIX	@"SpecialDialingPrefix"
