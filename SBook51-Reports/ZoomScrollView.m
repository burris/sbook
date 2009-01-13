#import "ZoomScrollView.h"
#import "tools.h"

@implementation ZoomScrollView

- initWithFrame:(NSRect)theFrame
{
    [super initWithFrame:theFrame];
    [self setBackgroundColor:[NSColor whiteColor]];
    scaleFactor = 1.0;
    return self;
}

- (float)scaleFactor
{
    return scaleFactor;
}

-(void) awakeFromNib
{
    [self setHasHorizontalScroller:YES];
    [self setHasVerticalScroller:YES];
    [self setBorderType:NSLineBorder];

    /* Set up the zoom button */
    [[zoomButton cell] setBordered:NO];
    [[zoomButton cell] setBezeled:YES];
    [[zoomButton cell] setFont:[NSFont labelFontOfSize:10.0]];
    [self addSubview:zoomButton];
    
    /* The next 2 lines install the subview 
     * and set its size to be the same as 
     * the NSScrollView
     */
    [self setDocumentView:subView];
    [subView setFrame:[[self contentView] frame]];
}

- (void)setScaleFactor:(float)aFactor
{
    if(aFactor==0){
	NSRunAlertPanel(@"ZoomScrollView",@"Illegal scale factor==0. Set the tag!",0,0,0);
	return;
    }

    if (scaleFactor != aFactor) {
	float delta = aFactor/scaleFactor;
	scaleFactor = aFactor;
	[[self contentView] scaleUnitSquareToSize:NSMakeSize(delta,delta)];
	[zoomButton selectItemWithTag:(int)(aFactor*100)];
    }

}

- (IBAction)changeZoom:(id)sender
{
    [self setScaleFactor:[[sender selectedCell] tag] / 100.0];
}

- (void)tile
{
    NSRect scrollerRect, buttonRect;

    [super tile];

    /* Place the pop-up button next to the scroller
     */
    scrollerRect = [[self horizontalScroller] frame];
    NSDivideRect(scrollerRect, &buttonRect, &scrollerRect, 50.0, NSMaxXEdge);
    [[self horizontalScroller] setFrame: scrollerRect];
    [zoomButton setFrame: NSInsetRect(buttonRect, 1.0, 1.0)];
}

       
- (BOOL)validateMenuItem:(id <NSMenuItem>)item
{
    if([item action]==@selector(changeZoom:)){
	return YES;
    }
    return NO;
}


@end
