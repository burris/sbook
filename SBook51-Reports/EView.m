

#import <sys/types.h>
#import <regex.h>

#import <DefaultSwitchSetter.h>

#import "Person.h"
#import "EView.h"
#import "FontWell.h"
#import "tools.h"

#define DEF_ENV_PAPER	@"DefaultEnvelopePaper"
#define DEF_PRINT_BARCODE @"DefaultPrintBarcode"
#define DEF_PRINT_FIM	@"DefaultPrintFIM"
#define DEF_PRINT_RETADDR @"DefaultPrintReturnAddress"

#define ALIGNMENT_LEFT 1
#define ALIGNMENT_CENTER 2
#define ALIGNMENT_RIGHT 3

@implementation EView

-initWithFrame:(NSRect)aRect
{
    [super initWithFrame:aRect];
    [printInfo release];
    printInfo = [[NSPrintInfo alloc] init];
    drawText  = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,1,1)];
    [drawText setEditable:NO];
    [drawText setSelectable:NO];
    return self;
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    [self  setNeedsDisplay:YES];
}

- (void)setFrameSize:(NSSize)newSize
{
    [self  setNeedsDisplay:YES];
    [super setFrameSize:newSize];
}


- (void)scaleUnitSquareToSize:(NSSize)newUnitSize
{
    [super scaleUnitSquareToSize:newUnitSize];
}


- (void)awakeFromNib
{
    NSMutableDictionary *appDefs = [NSMutableDictionary dictionary];

    [super awakeFromNib];

    [addrFontWell	setDisplayFont:[NSFont systemFontOfSize:9]];
    [retAddrFontWell	setDisplayFont:[NSFont systemFontOfSize:9]];

    [addrFontWell setSupportsColor:NO];
    [retAddrFontWell setSupportsColor:NO];

    [appDefs setObject:@"3" forKey:DEF_ENV_PAPER];
    [appDefs setObject:@"1" forKey:DEF_PRINT_BARCODE];
    [appDefs setObject:@"1" forKey:DEF_PRINT_FIM];

    [defaults registerDefaults:appDefs];

    setDefault(paperSizePopup,DEF_ENV_PAPER);
    setDefault(printBarcode,DEF_PRINT_BARCODE);
    setDefault(printFIM,DEF_PRINT_FIM);
    setDefault(printReturnAddress,DEF_PRINT_RETADDR);

    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(textDidChange:)
					  name:NSTextDidChangeNotification
					  object:addrText];

    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(textDidChange:)
					  name:NSTextDidChangeNotification
					  object:retAddrText];

    popupDictionary = [[NSMutableDictionary dictionary] retain];

    [printInfo setPaperName:@"Comm10"];
    [printInfo setOrientation:NSLandscapeOrientation];
    [self takeSizeFromPrintInfo:printInfo];
    [self setNumPages:1];		// one page
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [postnet release];
    [super dealloc];
}

- (BOOL)isOpaque  { return YES;}
- (BOOL)isFlipped { return YES;}

- (IBAction)pageSetup:sender
{
    [super pageSetup:sender];		// do the page setup
    [self  setNumPages:1];		// and resize the view itself
    [self  textDidChange:nil];		// relay
}

/****************************************************************
 ** Barcode Stuff
 ****************************************************************/

#define inches 72

static    float bigspace   = 13;
static    float smallspace = 4;
static    float linewidth  = 2.232;
static    float barwidth = .020 * inches;
static    float longbar  = .125 * inches;
static    float shortbar = .050 * inches;
static    float nextx    = .0475 * inches;

/* The POSTNET codes */

static char *codes[11] = {
    "L L S S S", 	//  digit 0
    "S S S L L", 	//  digit 1
    "S S L S L", 	//  digit 2
    "S S L L S", 	//  digit 3
    "S L S S L", 	//  digit 4
    "S L S L S", 	//  digit 5
    "S L L S S", 	//  digit 6
    "L S S S L", 	//  digit 7
    "L S S L S", 	//  digit 8
    "L S L S S", 	//  digit 9
    "L L S S S" 	//  digit 10 (also 0)
};

/* add an lbar to the bezier path */
- (void)addLbar:(NSBezierPath *)path
{
    [path relativeLineToPoint:NSMakePoint(0,-longbar)];
    [path relativeLineToPoint:NSMakePoint(0,longbar)];
    [path relativeMoveToPoint:NSMakePoint(nextx,0)];
}

/* add an lbar to the bezier path */
- (void)addSbar:(NSBezierPath *)path
{
    [path relativeLineToPoint:NSMakePoint(0,-shortbar)];
    [path relativeLineToPoint:NSMakePoint(0,shortbar)];
    [path relativeMoveToPoint:NSMakePoint(nextx,0)];
}


/*
 * scan through the addressText looking for the zip.
 * When you find it, update the barcode.
 */

- (void)createPOSTNET
{
    unsigned int i;
    int sum=0;
    int check;
    NSPoint pt = toRect.origin;

    pt.y += 72*0.5;

    [postnet release];
    postnet = 0;
    
    addrZip = [[[NSApp delegate] PersonClass] findZip:[addrText string]];
    if(!addrZip) return;

    postnet = [[NSBezierPath bezierPath] retain];
    [postnet setLineWidth:barwidth];
    [postnet moveToPoint:toRect.origin];
    
    if(addrZip && [addrZip length]>0){
	NSMutableString *strc = nil;

	/* Calculate the check digit.
	 * http://www.snx.com/mechanics.html
	 * "the check digit is the sum of the digits subtracted from the next higher
	 * multiple of 10."
	 */
	
	for(i=0;i<[addrZip length];i++){
	    int val = [addrZip characterAtIndex:i]-'0';
	    if(val<0 || val>9) continue;
	    sum += val;
	}
	check = 10 - (sum % 10);
	strc = [NSMutableString stringWithFormat:@"%@%d",addrZip,sum];
	
	/* Now create a new string with the check digit appended */
	
	/* Generate the postnet */
	
	[self  addLbar:postnet];
	for(i=0;i<[strc length];i++){
	    int val = [strc characterAtIndex:i] - '0';
	    char *cc;
	    if(val<0 || val>9) continue;
	    
	    for(cc=codes[val];*cc;cc++){
		if(*cc == 'S') [self addSbar:postnet];
		if(*cc == 'L') [self addLbar:postnet];
	    }
	}
	[self addLbar:postnet];
    }
}


/****************************************************************
 ** FIM STUFF
 ****************************************************************/

- (void)drawFIM
{
    NSRect bounds = [self bounds];
    NSPoint pt = NSMakePoint(NSMaxX(bounds) - 2*72.0,
			     NSMinY(bounds) + 1*72.0);
    NSBezierPath *fim = [NSBezierPath bezierPath];
    float height = 2 * inches;

    [fim setLineWidth:linewidth];
    [fim moveToPoint:pt];
    [fim relativeMoveToPoint:NSMakePoint(0,-height)];
    [fim relativeLineToPoint:NSMakePoint(0,height)];

    [fim relativeMoveToPoint:NSMakePoint(smallspace,0)]; // do the second line
    [fim relativeLineToPoint:NSMakePoint(0,-height)];
    [fim relativeLineToPoint:NSMakePoint(0,height)];

    [fim relativeMoveToPoint:NSMakePoint(bigspace,0)]; // do the middle line
    [fim relativeLineToPoint:NSMakePoint(0,-height)];
    [fim relativeLineToPoint:NSMakePoint(0,height)];

    [fim relativeMoveToPoint:NSMakePoint(bigspace,0)]; // do the second-to-last line
    [fim relativeLineToPoint:NSMakePoint(0,-height)];
    [fim relativeLineToPoint:NSMakePoint(0,height)];

    [fim relativeMoveToPoint:NSMakePoint(smallspace,0)]; // do the last
    [fim relativeLineToPoint:NSMakePoint(0,-height)];
    [fim relativeLineToPoint:NSMakePoint(0,height)];

    [[NSColor blackColor] set];
    [fim stroke];
}



- (void)drawText:(NSString *)str inRect:(NSRect)rect withFont:(NSFont *)aFont
{
    if(str){
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	[attrs setObject:aFont forKey:NSFontAttributeName];
	[str drawInRect:rect withAttributes:attrs];
    }

    if([printOutlines intValue]){
	[[NSColor lightGrayColor] set];
	NSFrameRectWithWidth(rect,1.0);
    }
}

/*
 * Draw the envelope...
 */

- (void)drawRect:(NSRect)rect
{
    BOOL screen = [NSGraphicsContext currentContextDrawingToScreen];

    /* Draw the background */
    if(screen==YES){
	[[NSColor colorWithCalibratedRed:1.0 green:0.95 blue:0.95 alpha:1.0] set];
    }
    else{
	[[NSColor whiteColor] set];
    }
    NSRectFill(rect);
    
    /* Possibly do the return address */
    if([printReturnAddress intValue]){
	NSLog(@"printing return address at %g,%g",NSMinX(fromRect),NSMinY(fromRect));
	[drawText setFrame:fromRect];
	[drawText setRtfdData:[retAddrText rtfdData]];
	[drawText drawRect:rect];	// draw it
	[self drawText:nil inRect:rect withFont:nil];
    }

    /* Do the sending address */
    [self drawText:[addrText string]    inRect:toRect withFont:[addrFontWell font]];



    if([printBarcode intValue]){
	[[NSColor blackColor] set];
	[postnet stroke];
    }

    if([printFIM intValue]){
	[[NSColor blackColor] set];
	[self drawFIM];
    }

    if([printOutlines intValue]){
	[[NSColor lightGrayColor] set];
	NSFrameRectWithWidth([self bounds],2.0);
    }
}



- (void)textDidChange:(NSNotification *)notification
{
    NSPoint pt;

    fromRect = [self bounds];
    fromRect.origin.x += 72*.5;		// bring in .5 inches
    fromRect.origin.y += 72*.5;		// bring in .5 inches
    fromRect.size.width -= 72 * .5;
    fromRect.size.height -= 72 * .5;

    fromRect.size.width /= 2;		// only use half of the envelope

    toRect   = fromRect;
    toRect.origin.x += toRect.size.width; // start in middle
    toRect.size.height /= 2;
    toRect.origin.y += toRect.size.height;

    pt = toRect.origin;

    pt.y += 72 * 0.5;

    [self createPOSTNET];		// create a new postnet
    [self setNeedsDisplay:YES];
}


- (void)printWithWindow:(NSWindow *)windowToAttachSheet
{
    NSPrintOperation *po;

    [self textDidChange:nil];
    po = [NSPrintOperation printOperationWithView:self printInfo:printInfo];
    
    /*
     * When I can get printers, we can skip this step.
     *
     * [po setShowPanels:NO];
     */
    [po runOperationModalForWindow:windowToAttachSheet
	delegate:nil didRunSelector:nil contextInfo:nil];
}

- (void)redisplay:sender
{
    [self textDidChange:nil];
    [self setNeedsDisplay:YES];
    [self display];
}


- (void)print:sender
{
    NSPrintInfo *pi = [NSPrintInfo sharedPrintInfo];

    [pi setRightMargin:0];
    [pi setLeftMargin:0];
    [pi setTopMargin:0];
    [pi setBottomMargin:0];

    [super print:sender];
}

@end
