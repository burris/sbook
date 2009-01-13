/*
 * (C) Copyright 1992,2002 by Simson Garfinkel and Associates, Inc.
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law.
 *
 */

#import "DialerPanel.h"
#import "DialerBundleClass.h"
#import "SBookController.h"
#import "DefaultSwitchSetter.h"

#include <sys/types.h>
#include <sys/uio.h>
#include <sys/time.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>

@implementation DialerPanel

DialerPanel *sharedDialerPanel=nil;

+(void)initialize
{
}

+ (DialerPanel *)sharedDialerPanel
{
    return sharedDialerPanel;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)awakeFromNib
{
    sharedDialerPanel = [self retain];	// only one of us is ever loaded
    portfd = -1;
    modemSendFormat = [[modemSend stringValue] retain];
    dialingTitle    = [[dialingTitleField stringValue] retain];
    [modemSend setStringValue:@""];		// erase what's here
    [dialedNumber setStringValue:@"Opening Modem"];
}

- (void)toggleDTR:(int)msec
{
    struct termios tty, old;

    tcgetattr(portfd, &tty);
    tcgetattr(portfd, &old);
    cfsetospeed(&tty, B0);
    cfsetispeed(&tty, B0);
    tcsetattr(portfd, TCSANOW, &tty);
    usleep(msec * 1000);
    tcsetattr(portfd, TCSANOW, &old);
}

- (void)toggleDTR
{
    [self toggleDTR:300];
}

/*
 * modemSend:
 * Send a string to the mdoem.
 * ^ - control character prefix.
 * ~ - delay. 300 msec.
 */
-(void)modemSend:(NSString *)str_ addCR:(BOOL)flag
{
    NSMutableString *displayStr = [NSMutableString stringWithFormat:modemSendFormat,str_];
    NSMutableString *str = [NSMutableString stringWithString:str_];
    NSMutableData   *sendData = [NSMutableData dataWithCapacity:0];
    const char *s;

    [fromModem setString:@""];
    [modemSend setStringValue:displayStr];

    if(flag){
	[str appendString:@"\r"];
    }

    s = [str UTF8String];

    /* And now actually do it */
    while(*s) {
	char c = *s;
  	if (*s == '^' && (*(s + 1))) {
	    s++;
	    c = (*s) & 31;
	}
	if(c == '~'){
	    //usleep(300 * 1000);
	}
	else{
	    [sendData appendBytes:&c length:1];
	}
  	s++;
    }
    [fileHandle writeData:sendData];
}


- (void)gotData:(NSNotification *)not
{
    NSData *data;
    NSString *str;

    data = [[not userInfo] objectForKey:NSFileHandleNotificationDataItem];
    str  = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];

    if(!fromModem){
	fromModem = [[NSMutableString alloc] init];
    }
    [fromModem appendString:str];

    [fromModem replaceOccurrencesOfString:@"\r" withString:@""
	       options:0
	       range:NSMakeRange(0,[fromModem length])];

    [fromModem replaceOccurrencesOfString:@"\n" withString:@"" options:0
	       range:NSMakeRange(0,[fromModem length])];



    if([fromModem length]>0){
	[modemSend setStringValue:
		       [NSString stringWithFormat:@"Modem returned '%@'",fromModem]];
    }
    
    /* And register to get the notification again */
    [fileHandle readInBackgroundAndNotify];
}


/* Open the modem.
 * Returns true if the window was displayed.
 * orderOutFlag is used if the modem is being grabbed on startup
 */

- (BOOL)openModemForWindow:(NSWindow *)aWindow andOrderOut:(BOOL)orderOutFlag
{
    BOOL displayed=NO;
    NSString *device  = [defaults objectForKey:DEF_MODEM_DEVICE];
    NSString *dialing = [dialingField stringValue];
    
    if(portfd>0) return NO;		// already open

    [dialingField setStringValue:@""];
    [dialedNumber setStringValue:@"Opening Modem..."];

    if(aWindow==nil){			// no window specified, so be sure the window is out
	[self center];
	if(orderOutFlag){
	    [self orderOut:nil]; // only visible if allowed
	    displayed = NO;
	}
	else{
	    [self orderFront:nil];
	    displayed = YES;
	}
    }
    else {
	[self runAsSheet:aWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
	displayed = YES;
    }
    
    portfd = open([device UTF8String], O_RDWR); // "/dev/cu.modem"

    [dialingField setStringValue:dialing]; // put back 'Dialing...'

    if (portfd < 0) {
	NSRunAlertPanel(@"SBook",@"Cannot open modem port %@: %s",nil,nil,nil,
			device,strerror(errno));
	return displayed;
    }
    fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:portfd closeOnDealloc:NO];

    [[NSNotificationCenter defaultCenter] addObserver:self 
					  selector:@selector(gotData:) 
					  name:NSFileHandleReadCompletionNotification
					  object:fileHandle];

    [fileHandle readInBackgroundAndNotify];
    return displayed;
}

- (BOOL)modemInUse
{
    return portfd>0;
}

- (void)setDialingTitle:(NSString *)str
{
    [dialingTitleField setStringValue:[NSString stringWithFormat:dialingTitle,str]];
}

/* Hang up modem by sending a carriage return.
 * Be sure to put away the window.
 */
- (void)hangup
{
    [self modemSend:@"" addCR:YES];
    [self orderOut:nil];
}

- (void)releaseModem
{
    NSLog(@"release modem");
    if(retreatTimer){
	[self cancel:self];
    }
    if(releaseTimer){
	[releaseTimer release];
	releaseTimer = 0;
    }
    if(portfd>0){
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[fileHandle release];
	close(portfd);
	portfd = -1;
	[dialedNumber setStringValue:@"Opening Modem"];
    }
    [self orderOut:self];		// make sure window is ordered out
}

/*
 * dial:forWindow:
 * Actually dial the string.
 */

- (void)dial:(NSString *)str  forWindow:aWindow
{
    NSMutableString *sendStr = [NSMutableString string];
    float defDropSeconds = [[defaults objectForKey:DEF_DROP_PHONE_SECONDS] floatValue];
    BOOL displayed = NO;

    /* First make sure the modem is open */
    displayed = [self openModemForWindow:aWindow andOrderOut:NO];

    /* Calculate the strings */
    [dialedNumber setStringValue:str];
    if([[defaults objectForKey:DEF_USE_TOUCHTONE] intValue]){
	[sendStr appendString:@"ATDT"];
    }
    else{
	[sendStr appendString:@"ATDP"];
    }
    [sendStr	appendString:str];

    if(aWindow && displayed==NO){
	/* Display as a sheet if it hasn't been displayed */
	[self runAsSheet:aWindow modalDelegate:self
	      didEndSelector:nil contextInfo:nil];
    }

    [self	modemSend:sendStr addCR:YES];

    retreatTimer = [[NSTimer scheduledTimerWithTimeInterval: defDropSeconds
			     target:self
			     selector:@selector(proceed:)
			     userInfo:nil
			     repeats:NO] retain];
    if(releaseTimer){
	[releaseTimer release];
	releaseTimer = 0;
    }

    if([[defaults objectForKey:DEF_KEEP_MODEM_AFTER_DIALING] intValue]==0){
	float releaseSeconds = [[defaults objectForKey:DEF_HOLD_MODEM_MINUTES]
				   floatValue] * 60.0;
	    
	NSLog(@"releaseSeconds=%f",releaseSeconds);
	if(releaseSeconds<30) releaseSeconds=30; // minimum
	releaseTimer = [[NSTimer scheduledTimerWithTimeInterval: releaseSeconds
				 target:self
				 selector:@selector(releaseModem)
				 userInfo:nil
				 repeats:NO] retain];
    }


}

/****************************************************************/

-(IBAction)cancel:(id)sender
{
    [retreatTimer release];
    [retreatTimer invalidate];
    retreatTimer = 0;
    [self hangup];
    [super cancel:sender];
}

/* Only called from timer */
-(IBAction)proceed:(id)sender
{
    [retreatTimer release];
    retreatTimer = 0;
    [self	hangup];
    [super	proceed:sender];
}

- (IBAction)releaseModem:sender
{
    [self releaseModem];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)item
{
    SEL action = [item action];

    if(action == @selector(releaseModem:)){
	return [self modemInUse];
    }
    return NO;
}


@end
