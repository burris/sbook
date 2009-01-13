#import "USDialRulesBundleClass.h"

#import "../SBook51-Dialer/DialerPanel.h"

#import <PlugInController.h>
#import <DefaultSwitchSetter.h>
#import <SBookController.h>


@implementation USDialRulesBundleClass

+ (void) initialize
{
    NSMutableDictionary *appDefs= [NSMutableDictionary dictionary];

    /* Dialing */
    [appDefs setObject:@"617"  forKey:DEF_DEF_AREACODE];
    [appDefs setObject:@"1"    forKey:DEF_YOUR_COUNTRY_CODE];

    [appDefs setObject:@"617"  forKey:DEF_LOCAL_AREACODES];
    [appDefs setObject:@""     forKey:DEF_LOCAL_DIALING_PREFIX];
    [appDefs setObject:@"1"    forKey:DEF_REQUIRE_10_DIGIT_DIALING];

    [appDefs setObject:@"1"   forKey:DEF_LONG_DISTANCE_DIALING_PREFIX];
    [appDefs setObject:@"011" forKey:DEF_INTERNATIONAL_DIALING_PREFIX];

    [appDefs setObject:@"0"  forKey:DEF_ENABLE_SPECIAL_EXCHANGE_PROCESSING];
    [appDefs setObject:@""  forKey:DEF_SPECIAL_TELEPHONE_EXCHANGES];
    [appDefs setObject:@""  forKey:DEF_SPECIAL_EXCHANGE_DIALING_PREFIX];

    [defaults registerDefaults:appDefs];
}



- (void)startup:(PlugInController *)owner 
{
    [owner installPreference:@"US Dialing" view:usDialRulesPrefPanel];
    sbc = [NSApp delegate];
    
    [sbc setLocalizedDialer:self];
}


-(void)awakeFromNib
{
    setDefault(dialing_defaultAreaCode,DEF_DEF_AREACODE);
    setDefault(dialing_localAreaCodes,DEF_LOCAL_AREACODES);
    setDefault(dialing_localDialingPrefix,DEF_LOCAL_DIALING_PREFIX);
    setDefault(dialing_yourCountryCode,DEF_YOUR_COUNTRY_CODE);

    setDefault(dialing_phoneCompanyRequires10Digit,DEF_REQUIRE_10_DIGIT_DIALING);
    setDefault(dialing_longDistanceDialingPrefix,DEF_LONG_DISTANCE_DIALING_PREFIX);
    setDefault(dialing_internationalDialingPrefix,DEF_INTERNATIONAL_DIALING_PREFIX);

    setDefault(dialing_enableSpecialExchangeProcessing,DEF_ENABLE_SPECIAL_EXCHANGE_PROCESSING);
    setDefault(dialing_specialExchanges,DEF_SPECIAL_TELEPHONE_EXCHANGES);
    setDefault(dialing_specialDialingPrefix,DEF_SPECIAL_EXCHANGE_DIALING_PREFIX);

    setAutoEnable(dialing_enableSpecialExchangeProcessing,dialing_specialExchanges);
    setAutoEnable(dialing_enableSpecialExchangeProcessing,dialing_specialDialingPrefix);
}

/****************************************************************
 ***
 *** Need: Exchange in list.
 ***/


BOOL inSet(NSString *set_,NSString *code3_)
{
    NSRange r;

    NSMutableString *set = [set_ mutableCopy];
    NSMutableString *code3 = [code3_ mutableCopy];
    [set insertString:@" " atIndex:0];
    [set appendString:@" "];

    [code3 insertString:@" " atIndex:0];

    r = [set rangeOfString:code3];
    return r.length > 0;
}


/* Calculate the dialing code. A "D" in the prefix means delete a character
 * from the phone number. And @ means that the phone number gets inserted there.
 * Otherwise, the phone number gets inserted at the end.
 */
-(NSMutableString *)applyPrefix:(NSString *)prefix_ toString:(NSString *)digits_
{
    int ats = 0;
    NSMutableString *digits = [NSMutableString stringWithString:digits_];
    NSMutableString *prefix = [NSMutableString stringWithString:prefix_];
    NSMutableString *buf    = [NSMutableString string];
    unsigned int i;

    for(i=0;i<[prefix length];i++){
	unichar ch = [prefix characterAtIndex:i];

	if(ch=='d' || ch=='D') [digits deleteCharactersInRange:NSMakeRange(0,1)];
	if(ch=='@') ats++;
    }
	
    for(i=0;i<[prefix length];i++){
	unichar ch = [prefix characterAtIndex:i];
	if(ch=='D' || ch=='d') continue;
	if(ch=='@'){
	    [buf appendString:digits];
	}
	else{
	    [buf appendString:[NSString stringWithCharacters:&ch length:1]];
	}
    }
    if(ats==0){
	[buf appendString:digits];
    }
    return buf;
}



-(void)dialLocalNumber:(NSString *)digits_ extension:(NSString *)extension forWindow:(NSWindow *)aWindow
{
    NSString *specialTelephoneExchanges       = [defaults objectForKey:DEF_SPECIAL_TELEPHONE_EXCHANGES];
    NSString *enableSpecialExchangeProcessing = [defaults objectForKey:DEF_ENABLE_SPECIAL_EXCHANGE_PROCESSING];
    NSString *specialExchangeDialingPrefix    = [defaults objectForKey:DEF_SPECIAL_EXCHANGE_DIALING_PREFIX];
    NSMutableString *digits      = [digits_ mutableCopy];
    NSString *localDialingPrefix = [defaults objectForKey:DEF_LOCAL_DIALING_PREFIX];
    BOOL doSpecial = NO;
    DialerPanel *dialer = [sbc dialerPanel];

    /* Check for special exchange processing */
    if([enableSpecialExchangeProcessing intValue]){
	/* This is a local number that I'm allowed to dial with 7-digits.
	 * See if it is a special exchange.
	 */
	if([digits length]==7 && 
	   inSet(specialTelephoneExchanges,[digits substringWithRange:NSMakeRange(0,3)])){
	    doSpecial = YES;
	}
	
	if([digits length]==10 && 
	   inSet(specialTelephoneExchanges,[digits substringWithRange:NSMakeRange(3,3)])){
	    doSpecial = YES;
	    [digits replaceCharactersInRange:NSMakeRange(0,3)
		    withString:@""];
	}
    }

    if(doSpecial){
	/* add the special prefix */
	[dialer setDialingTitle:@"Special Exchange"];
	digits = [self applyPrefix:specialExchangeDialingPrefix toString:digits];
    }
    else {
	[dialer setDialingTitle:@"Local Exchange"];
	digits = [self applyPrefix:localDialingPrefix toString:digits];
    }

    /* Now dial */
    [digits appendString:extension]; // add the string again
    [dialer dial:digits forWindow:aWindow];	// dial it;
    return;
}


/*
 * Dial the string with a sheet. But this is a funny sheet. The dialing happens
 * immediately and the sheet displays the status and gives the user a chance to 
 * cancel mid-flight.
 */

-(void)dial:(NSString *)str withLocalRules:(BOOL)applyRules forWindow:(NSWindow *)aWindow
{
    unsigned int i;
    NSString *defaultAreaCode	= [defaults objectForKey:DEF_DEF_AREACODE];
    NSString *localAreaCodes    = [defaults objectForKey:DEF_LOCAL_AREACODES];
    NSString *countryCode       = [defaults objectForKey:DEF_YOUR_COUNTRY_CODE];
    NSString *require10DigitDialing = [defaults objectForKey:DEF_REQUIRE_10_DIGIT_DIALING];
    NSString *longDistanceDialingPrefix= [defaults objectForKey:DEF_LONG_DISTANCE_DIALING_PREFIX];
    NSString *internationalDialingPrefix= [defaults objectForKey:DEF_INTERNATIONAL_DIALING_PREFIX];
    NSString *localDialingPrefix= [defaults objectForKey:DEF_LOCAL_DIALING_PREFIX];

    NSMutableString *digits	= [NSMutableString string];
    NSString *extension	= @"";
    NSRange comma;
    BOOL intl = NO;

    DialerPanel *dialer = [sbc dialerPanel];



    /* First just pull the digits out of the string */
    for(i=0;i<[str length];i++){
	unichar ch = [str characterAtIndex:i];
	if(isdigit(ch) || ch==',' || ch=='#' || ch=='*'){
	    [digits appendString:[NSString stringWithCharacters:&ch length:1]];
	}
	if(ch=='+' && [digits length]==0) intl=YES;
    }
    
    /* "digits" is now a list of the digits and dialable symbols */

    if(applyRules==false){
	[dialer setDialingTitle:@"Literal Number"];
	[dialer dial:str forWindow:aWindow];
	return;
    }

    /* Check if "international" number is in the current country code... */
    if(intl && [countryCode length]>0 && [digits hasPrefix:countryCode]){
	intl = NO;
	[digits replaceCharactersInRange:NSMakeRange(0,1)
		withString:@""];
    }

    if(intl){
	/* International phone number --- provided that the country
	 * code doesn't match...
	 */
	digits = [self applyPrefix:internationalDialingPrefix toString:digits];
	[dialer setDialingTitle:@"International Number"];
	[dialer dial:digits forWindow:aWindow];
	return;
    }

    /* Check for an extension in a phone number less than 7 digits long */
    comma = [digits rangeOfString:@","]; // this marks the end
    if(comma.location != NSNotFound){
	extension = [digits substringFromIndex:comma.location];
	digits    = [[digits substringToIndex:comma.location-1] mutableCopy];
    }

    /* If we're asked to dial less than 7 digits, just dial it */
    if([digits length]<7){
	digits = [self applyPrefix:localDialingPrefix toString:digits];
	[digits appendString:extension];

	[dialer setDialingTitle:@"Short Number"];
	[dialer dial:digits forWindow:aWindow];
	return;
    }

    /* If 10 digit dialing is not required...
     */
    if(([require10DigitDialing intValue]==0)){

	/* If the phone number is 7 digits,* and either:
	 *  - there is no default area code
	 *  - the default area code is in the local area code...
	 * Then just dial it...
	 */

	if(([digits length]==7)){
	    if([defaultAreaCode length]==0 || inSet(localAreaCodes,defaultAreaCode)){
		[self dialLocalNumber:digits extension:extension forWindow:aWindow];
		return;
	    }
	}
	
	/* If the phone number is 10 digits, and
	 * - the local area code is set
	 * - the local area code is 3 digits
	 * - the phone number matches the local area code...
	 * Then remove the area code and dial it...
	 */
	if(([digits length]==10) &&
	   ([localAreaCodes length]==3) &&
	   inSet(localAreaCodes,[digits substringWithRange:NSMakeRange(0,3)])){
	    [self dialLocalNumber:[digits substringFromIndex:3]
		  extension:extension
		  forWindow:aWindow];
	    return;
	}
    }

    /* If we are a 7-digit, just add the default exchange
     */
    if([digits length]==7){
	[digits insertString:defaultAreaCode atIndex:0];
    }

    /* Now, if this is a local area exchange, repeat the above code */
    if(inSet(localAreaCodes,[digits substringWithRange:NSMakeRange(0,3)])){
	[self dialLocalNumber:digits extension:extension forWindow:aWindow];
	return;
    }

    /* Must be a long-distance number */
    digits = [self applyPrefix:longDistanceDialingPrefix toString:digits];
    [digits appendString:extension];
    [dialer setDialingTitle:@"Long Distance Number"];
    [dialer dial:digits forWindow:aWindow];
}


@end
