#import "SBookIcon.h"
#import "SBookIconView.h"
#import "SLC.h"
#import "Person.h"
#import "SList.h"
#import "Emailer.h"
#import "SBookController.h"

#import "tools.h"
#import "defines.h"

#include <stdio.h>
#include <sys/types.h>
#include <regex.h>

NSImage *addressImage = nil;
NSImage *telephoneImage = nil;
NSImage *emailImage = nil;
NSImage *linkImage = nil;
NSImage *companyImage = nil;
NSImage *personImage = nil;
NSImage *imImage = nil;

static	regex_t emailre;
static	regex_t phonere;

@implementation SBookIcon

+(void)initialize
{
    int r;
    addressImage   = [[NSImage imageNamed:@"envelope.tiff"] retain];
    telephoneImage = [[NSImage imageNamed:@"phone2.tif"] retain];
    emailImage     = [[NSImage imageNamed:@"email.tiff"] retain];
    linkImage      = [[NSImage imageNamed:@"world1.tif"] retain];
    personImage    = [[NSImage imageNamed:@"person1.tif"] retain];
    companyImage   = [[NSImage imageNamed:@"business1.tif"] retain];
    imImage        = [[NSImage imageNamed:@"IM.tif"] retain];
    if(regcomp(&emailre,"([-a-zA-Z_0-9#+=.]+@[-a-zA-Z_0-9#+=.]+)",REG_EXTENDED|REG_ICASE)){
	NSLog(@"regcomp failed in SBookIconView");
    }
    if(r=regcomp(&phonere,"([-0-9./ (),+][-0-9./ (),][-0-9./ (),]+)",REG_EXTENDED|REG_ICASE)){
	NSLog(@"regcomp2 failed in SBookIconView r=%d",r);
    }
}

+(NSImage *)imageForFlag:(int)i
{
    switch(i & P_BUT_MASK){
    case P_BUT_EMAIL:
	return(emailImage);
    case P_BUT_ADDRESS:
	if(i & P_FOUND_ASTART){
	    return(addressImage);
	}
	return nil;
    case P_BUT_TELEPHONE:
	return(telephoneImage);
    case P_BUT_LINK:
	return(linkImage);
    case P_BUT_COMPANY:
	return(companyImage);
    case P_BUT_PERSON:
	return(personImage);
    case P_BUT_IM:
	return(imImage);
    }
    return nil;
}


+ iconForOrigin:(NSPoint)pt_
	   flag:(int)flag_
	    slc:(SLC *)aSLC
	 person:(Person *)aPerson
	 inView:(SBookIconView *)iv_
	   line:(int)i
{
    NSImage *img_ = [SBookIcon imageForFlag:flag_];
    SBookIcon *icon;
    NSRect	loc_;

    if(!img_) return nil;		// do not return 

    loc_.size   = [img_ size];
    loc_.origin = pt_;
    
    loc_.origin.x -= [img_ size].width/2;

    icon = [[SBookIcon alloc] initWithFrame:loc_ flag:flag_
			      slc:aSLC person:aPerson inView:iv_ line:i ];
    return [icon autorelease];
}
	    
- (SBookIcon *)initWithFrame:(NSRect)frame_
			flag:(int)flag_
			 slc:(SLC *)slc_
		      person:(Person *)person_
		      inView:(SBookIconView *)iv_
			line:(int)line_
{
    [super initWithFrame:frame_];
    line = line_;
    flag = flag_;
    iv   = iv_;
    person = person_;
    slc = slc_;
    [iv addSubview:self];
    [self setFrame:frame_];		// make sure frame is set properly in parent view
    [self setNeedsDisplay:YES];
    return self;
}

- (void)dealloc
{
    [self removeFromSuperview];
    [super dealloc];
}

- (BOOL)isOpaque { return YES; }

- (void)drawRect:(NSRect)rect
{
    float frac = 1.0;

    //NSLog(@"drawRect flag=%d %@",flag,self);
    [[NSColor whiteColor] set];
    NSRectFill(rect);

    if([iv displayIcons]==NO){
	return;
    }

    if(selected) frac = 0.6;
    [[SBookIcon imageForFlag:flag] dissolveToPoint:NSMakePoint(0,0) fraction:frac];
}

/****************************************************************
 ** COPY
 ****************************************************************/

- (NSString *)stringForSelectedIconWithName:(BOOL)nameFlag
			      forPasteboard:(BOOL)forPasteboard
{
    NSMutableString *ret = nil;
    NSString *str = nil;
    NSRange start;
    BOOL addHttp = NO;
    unsigned int j;
    regmatch_t pmatch[4];
    const char	*lstr = [iv line:line];

    switch(flag & P_BUT_MASK){

    case P_BUT_EMAIL:
	ret = [NSMutableString string];

	memset(pmatch,0,sizeof(pmatch));
	if(regexec(&emailre,lstr,2,pmatch,0)){
	    return @"";			// can't find email
	}
	    
	[ret appendString:[[slc displayedPerson] cellName]];

	[ret appendString:@" <"];
	[ret appendString:[NSString stringWithUTF8String:lstr + pmatch[1].rm_so
				    length:pmatch[1].rm_eo - pmatch[1].rm_so ]];
	[ret appendString:@">"];

	if(!forPasteboard){
	    [ret replaceString:@" " withString:@"%20" global:YES];
	    [ret replaceString:@"<" withString:@"%3c" global:YES];
	    [ret replaceString:@">" withString:@"%3e" global:YES];
	}
	return ret;

    case P_BUT_TELEPHONE:
	memset(pmatch,0,sizeof(pmatch));
	if(regexec(&phonere,lstr,2,pmatch,0)){
	    return @"<no phone>";			// can't find email
	}
	str = [NSString stringWithUTF8String:lstr+pmatch[1].rm_so
			length:pmatch[1].rm_eo - pmatch[1].rm_so ];
	return str;

    case P_BUT_LINK:
	str = [NSString stringWithUTF8String:lstr];
	start = [str rangeOfString:@"http"];
	addHttp=NO;

	if(start.location==NSNotFound){
	    /* see if we can find a www */
	    start = [str rangeOfString:@"www."];
	    if(start.location==NSNotFound){
		return nil;		// not to be found
	    }
	    addHttp= YES;
	}

	str = [str substringFromIndex:start.location];

	for(j=0;j<[str length];j++){
	    unichar c = [str characterAtIndex:j];
	    if(c==' ' || c=='\t'){
		str = [str substringToIndex:j];
	    }
	}

	if(addHttp){
	    str = [NSString stringWithFormat:@"http://%@/",str];
	}
	return str;

    case P_BUT_ADDRESS:
	/* For address, we take the first line, the line with the button,
	 * and then scan down until we get a line that is not an address
	 */
	ret = [NSMutableString stringWithString:[[slc displayedPerson] cellName]];

	[ret appendString:@"\n"];
	for(j=line ; j < [iv numLines]; j++){
	    [ret appendString:[NSString stringWithUTF8String:[iv line:j]]];
	    [ret appendString:@"\n"];
	    if([iv results:j] & P_FOUND_AEND) break;
	}
	return ret;

    case P_BUT_IM:
	str = [NSString stringWithUTF8String:lstr];
	return str;

    case P_BUT_PERSON:
    case P_BUT_COMPANY:
	/* For the person or company, grab the entire entry */
	ret = [NSMutableString string];
	
	for(j=0;j < [iv numLines]; j++){
	    [ret appendString:[NSString stringWithUTF8String:[iv line:j]]];
	    [ret appendString:@"\n"];
	}
	return ret;
    }
    return @"<not implemented yet>";
}

- (void)copyToPasteboard:(NSPasteboard *)pb
{
    [pb declareTypes:[NSArray arrayWithObjects: NSStringPboardType, nil] owner:self];
    [pb setString:
	    [self stringForSelectedIconWithName:YES forPasteboard:YES ]
	forType:NSStringPboardType];
}



/*
 * mouseDown: higlight the button that the mouse when down in.
 *            If shift or option is down, then copy to pasteboard.
 *            If icons aren't being displayed, just bag it.
 */
- (void)mouseDown:(NSEvent *)theEvent
{
    if([theEvent modifierFlags] & (NSControlKeyMask)){
	switch(flag & P_BUT_MASK){
	case P_BUT_PERSON:
	case P_BUT_COMPANY:
	    [iv popMenuWithEvent:theEvent]; // allow to change something
	    return;
	default:
	    return;			// nothing defined.
	}
    }

    if([theEvent modifierFlags] & (NSShiftKeyMask|NSAlternateKeyMask)){
	[self copyToPasteboard:[NSPasteboard generalPasteboard]];
	[slc  setStatus:@"copied"];
    }

    selected = YES;			// clicking causes selection
    [self setNeedsDisplay:YES];
}
    



/*
 * mouseUp: If mouse comes up without a modifier, execute the icon
 * and all other icons of the same time...
 */
- (void)mouseUp:(NSEvent *)theEvent
{
    BOOL useRules = TRUE;

    if([theEvent modifierFlags] & (NSShiftKeyMask|NSAlternateKeyMask)){
	goto done;
    }

    switch(flag & P_BUT_MASK){
    case P_BUT_EMAIL:
	[Emailer sendMailTo:[self stringForSelectedIconWithName:NO forPasteboard:NO]
		 cc:nil subject:nil body:nil];
	[[slc displayedPerson] emailed];
	break;
    case P_BUT_LINK:
	[[NSWorkspace sharedWorkspace]
	    openURL:[NSURL URLWithString:[self stringForSelectedIconWithName:NO forPasteboard:NO]]];
	break;
    case P_BUT_TELEPHONE:
	if([[slc doc] queryFlag:SLIST_DIAL_EXACT_FLAG]){
	    useRules = NO;
	}
	if(([[slc doc] queryFlag:SLIST_DIAL_BOLD_EXACT_FLAG]) && [iv isLineBold:line]){
	    useRules = NO;
	}
	if([person queryFlag:ENTRY_DIAL_EXACT_FLAG]){
	    useRules = NO;
	}
	    
	[[AppDelegate localizedDialer]
	    dial:[self stringForSelectedIconWithName:NO forPasteboard:NO]
	    withLocalRules:useRules
	    forWindow:[self window]];
	[person telephoned];
	break;
    case P_BUT_ADDRESS:
	[[AppDelegate reportBundleClassInstance]
	    printEnvelope:person
	    address:[self stringForSelectedIconWithName:YES forPasteboard:NO]
	    forWindow:[self window]];
	break;
    case P_BUT_PERSON:
    case P_BUT_COMPANY:
	break;				// ignore mouse-up on these buttons

    default:
	NSLog(@"flag=%x",flag);
	NSAssert(0,@"unknown icon!");
    }
 done:;
    selected = NO;
    [self setNeedsDisplay:YES];
}


/*
 * mouseDragged:
 * Figure out where we are now. If mouse has been dragged outside
 * of the icon, start a drag event...
 */
- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPasteboard     *pb = nil;
    NSMutableString	*str=nil;
    NSSize	  stringSize;
    NSImage         *dragImage=nil;
    NSRect	where;


    if([self mouse:[self convertPoint:[theEvent locationInWindow] fromView:nil]
	     inRect:[self bounds]]==NO){
	return;				// not dragged out
    }

    pb = [NSPasteboard pasteboardWithName:NSDragPboard];

    [self copyToPasteboard:pb];
    str = [NSMutableString stringWithString:[pb stringForType:NSStringPboardType]];

    if([str length]>0 && [str characterAtIndex:[str length]-1]=='\n'){
	[str deleteCharactersInRange:NSMakeRange([str length]-1,1)];
    }
    stringSize = [str sizeWithAttributes:nil]; // get size
    dragImage = [[NSImage alloc] initWithSize:stringSize];

    where.size = stringSize;
    where.origin = NSMakePoint(0,0);

    [dragImage lockFocus];
    [[NSColor colorWithDeviceCyan:0 magenta:0 yellow:1.0 black:0 alpha:0.3] set];
    NSRectFill(where);
    [str drawInRect:where withAttributes:nil];
    [dragImage unlockFocus];

    [self copyToPasteboard:pb];
    [self dragImage:dragImage
	  at:[self convertPoint:[theEvent locationInWindow] fromView:nil]
	  offset:NSMakeSize(5,5)
	  event:theEvent
	  pasteboard:pb
	  source:self
	  slideBack:YES];
    [dragImage release];
    selected = NO;
    [self setNeedsDisplay:YES];
}





@end
