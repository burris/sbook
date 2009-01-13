/*
 * SBookIconView:
 * The view that displays the SBookIcons
 */

#import "SBookIconView.h"
#import "SBookIcon.h"
#import "SBookText.h"
#import "SLC.h"
#import "tools.h"
#import "Emailer.h"
#import "Person.h" 
#import "defines.h"
#import "SBookController.h"
#import "SList.h"


@implementation SBookIconView

NSString *VisibleRectChanged = @"VisibleRectChanged";

- (void)dealloc
{
    if(results){
	free(results);
	results = 0;
    }
    if(rects){
	free(rects);
	rects = 0;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


- (id)initWithScrollView:(NSScrollView *)scrollView
	     orientation:(NSRulerOrientation)orientation;
{
    [super initWithScrollView:scrollView orientation:orientation];	// initialize

    slc = [[scrollView window] delegate];

    [slc setIconView:self];		// tell the SLC where we are
    [self setText:[slc entryText]];	// get my text

    /* Create an observer on the text */
    [[NSNotificationCenter defaultCenter]
	addObserver:self selector:@selector(textChanged:)
	name:NSTextDidChangeNotification
	object:text];

    [[NSNotificationCenter defaultCenter]
	addObserver:self selector:@selector(visibleRectChanged:)
	name:VisibleRectChanged object:text];

    [[self window] setAcceptsMouseMovedEvents:YES];

    [self setToolTip:@"Click icon to execute.\nShift-click or drag icons for copy.\nControl-click to change icon."];

    displayIcons = YES;			// default

    /* Create the temp storage areas */
    results	= (unsigned int *)malloc(0);
    return self;
}

- (BOOL)displayIcons
{
    return displayIcons;
}

- (void)setDisplayIcons:(BOOL)aVal
{
    if(displayIcons != aVal){
	displayIcons = aVal;
	[self setNeedsDisplay:YES];
    }
}


- (BOOL)isFlipped	{ return YES;  }
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent { return YES;}
- (BOOL)isOpaque	{ return YES;  }
- (SBookText *)text	{ return text; }

-(void)setText:(SBookText *)aText
{
    text = aText;
    [text setIconView:self];
}

- (void)drawRect:(NSRect)rect
{
    [[NSColor whiteColor] set];
    NSRectFill(rect);
}

/*
 * layoutIcons:
 * Lay out the icons and their tracking rectangles,
 * which is a bit complicated because of the flipped view.
 */

- (void)layoutIcons
{

    NSRect dvr = [text documentVisibleRect];
    float yoffset = dvr.origin.y;
    NSRect bounds = [self bounds];
    unsigned int i;

    [[self subviews] makeObjectsPerformSelector:
			 @selector(removeFromSuperviewWithoutNeedingDisplay)]; // get them out

    /* Now calculate where the new icons will go.
     * If any are in new locations, we need to relay the tracking rectangles.
     */

    if(rects){
	free(rects);
	rects = 0;
    }
    rects = [text getLayoutRectsWithCount:&rectCount];
    for(i=0;tp && i<tp->numLines;i++){
	NSPoint org = NSMakePoint(bounds.origin.x +bounds.size.width/2 ,
				  rects[i].origin.y + 2 - yoffset  );
	[SBookIcon iconForOrigin:org flag:results[i]
		   slc:slc
		   person:[slc displayedPerson]
		   inView:self
		   line:i ];
    }
    [self setNeedsDisplay:YES];
}


/*
 * reparse:
 * reparse the entry;
 * Called every time the text changes.
 * also highlights the searched for text
 */
- (void)reparse
{
    //if(debug) NSLog(@"SBookIconView: reparse");
    if(tp){
	[NSTextView freeParagraphs:tp];
	tp=0;
    }

    if([slc numDisplayedPeople]==1){
	/* Get the text */
	tp = [text getParagraphsWithEncoding:NSUTF8StringEncoding];
	results = (unsigned int *)realloc(results,tp->numLines*sizeof(int));
	memset(results,0,tp->numLines*sizeof(int));

	parse_lines(tp->numLines,(const char **)tp->lines,
		    0,
		    tp->lineAttributes,results,
		    [[slc doc] flags],
		    [[slc displayedPerson] flags]);
    }
    [self layoutIcons];
    [self highlightSearchResults];
    [self setNeedsDisplay:YES];
}

- (const char *)line:(unsigned int)i
{
    if(i>=0 && i<tp->numLines){
	return tp->lines[i];
    }
    return "";				// null
}

- (unsigned int)results:(unsigned int)i			// contents of results[i]
{
    if(i>=0 && i<tp->numLines){
	return results[i];
    }
    return 0;				// null
}


- (unsigned int)numLines
{
    return tp->numLines;
}

- (void) highlightSearchResults
{
    NSString *str = [text string];

    [text removeHighlight];

    if([[[NSUserDefaults standardUserDefaults]
	    objectForKey:DEF_HIGHLIGHT_SEARCH_RESULTS] intValue]==0){
	return;				// don't highlight
    }

    /* Only highlight for full-text searches */
    if([[slc doc] lastSuccessfulSearchMode] != SEARCH_FULL_TEXT){
	return;
    }

    /* Don't highlight if the SBookText is the first responder or if the
     * search string is 0-length.
     */
    if(([[slc window] firstResponder] == text) ||
       ([str length]==0)){
	return;
    }
    else {
	int len = [str length];
	int pos = 0;
	NSRange r;
	NSString *searchString = [[slc searchCell] stringValue];

	do {
	    r = [str rangeOfString:searchString
		     options:NSCaseInsensitiveSearch
		     range:NSMakeRange(pos,len-pos)];
	    if(r.length>0){
		[text highlightRange:r];
		pos = r.location + r.length; // start next search
	    }
	} while(r.length>0);
    }
}


- (BOOL)isLineBold:(u_int)line
{
    if(tp && line<tp->numLines && (tp->lineAttributes[line] & P_ATTRIB_BOLD)){
	return YES;
    }
    return NO;
}


- (int)whichLine:(NSPoint)pt
{
    NSRect frame = [self frame];
    unsigned int i;
    for(i=0;i<rectCount;i++){
	NSRect r = rects[i];
	r.origin.x   = frame.origin.x;			// make it us
	r.size.width = frame.size.width;
	if(NSMouseInRect(pt,r,YES)){
	    return i;
	}
    }
    return -1;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    unsigned i;

    if([theEvent modifierFlags] & (NSControlKeyMask)){
	[self popMenuWithEvent:theEvent];
    }

    if([theEvent modifierFlags] & (NSShiftKeyMask & NSAlternateKeyMask)){
	Person *p = [slc displayedPerson];
	for(i = 0; i < [p numAsciiLines]; i++){
	    NSLog(@"tag=%x  line='%@'",[p sbookTagForLine:i],[p asciiLine:i]);
	}
	return;
    }
    [self whichLine:pt];

    return;
}

/****************************************************************/
- (void)force:(id)sender
{
    Person *person = [slc displayedPerson];
    int tag = [sender tag];
    int of = [person flags];
    int newFlags = of;

    newFlags &=  ~ENTRY_FORCE_MASK;	// reset this flag
    newFlags &=  ~ENTRY_SHOULD_PARSE_FLAG; // and this flag

    switch(tag){
    case 0:
	newFlags |= ENTRY_SHOULD_PARSE_FLAG;
	break;				// auto
    case -1:
	break;				// don't parse and don't force
    case P_BUT_PERSON:
	newFlags |= ENTRY_SHOULD_PARSE_FLAG | ENTRY_FORCE_PERSON;
	break;
    case P_BUT_COMPANY:
	newFlags |= ENTRY_SHOULD_PARSE_FLAG | ENTRY_FORCE_COMPANY;
	break;
    }

    [person setFlags:newFlags];
    [person setSmartSortNameAndPersonFlag];
    [slc setNameToFirstLine:NO];
    [[slc iconView] reparse];		// 
}



- (void)popMenuWithEvent:(NSEvent *)theEvent
{
    Person *person = [slc displayedPerson];
    int forcedItem = [person flags] & ENTRY_FORCE_MASK;

    if([slc numDisplayedPeople]!=1) return; // 

    /* See if we should pop */

    if(!contextMenu){

	contextMenu = [[NSMenu alloc] init];

	[contextMenu setTitle:@"Parse Control"];
	
	forceAutoItem = [contextMenu addMenuItemTitle:@"auto" image:nil
		     target:self action:@selector(force:) tag:0];

	forceNoneItem = [contextMenu addMenuItemTitle:@"none" image:nil
		     target:self action:@selector(force:) tag:-1];

	[contextMenu addItem:[NSMenuItem separatorItem]];

	forcePersonItem = [contextMenu addMenuItemTitle:@""
				       image:[SBookIcon imageForFlag:P_BUT_PERSON]
				       target:self
				       action:@selector(force:)
				       tag:P_BUT_PERSON];


	forceCompanyItem = [contextMenu addMenuItemTitle:@""
				       image:[SBookIcon imageForFlag:P_BUT_COMPANY]
				       target:self
				       action:@selector(force:)
				       tag:P_BUT_COMPANY];
    }

    [forceAutoItem setEnabled:YES];
    [forceNoneItem setEnabled:YES];
    [forcePersonItem setEnabled:YES];
    [forceCompanyItem setEnabled:YES];

    if([person flags] & ENTRY_SHOULD_PARSE_FLAG){
	/* parse entry */
	[forceAutoItem setState:(forcedItem == 0)];
	[forceNoneItem setState:0];
	[forcePersonItem setState:(forcedItem == ENTRY_FORCE_PERSON)];
	[forceCompanyItem setState:(forcedItem == ENTRY_FORCE_COMPANY)];
    }
    else {
	/* don't parse entry */
	[forceAutoItem setState:0];
	[forceNoneItem setState:1];
	[forcePersonItem setState:0];
	[forceCompanyItem setState:0];
    }



    [NSMenu popUpContextMenu:contextMenu withEvent:theEvent forView:self];

    //[showPhone setState:[doc columnOneMode]==FirstPhone];
    //[showEmail setState:[doc columnOneMode]==FirstEmail];
    //[showSecondLine setState:[doc columnOneMode]==SecondLine];
}


/****************************************************************/


/*
 * textChanged:
 * reparse and lay out the new icons.
 */

- (void)textChanged:(NSNotification *)n
{
    [slc setTextChanged:YES];		// make sure we know that the text is changed
    [self reparse];
}

- (void)visibleRectChanged:(NSNotification *)n
{
    [self layoutIcons];
    [self setNeedsDisplay:YES];
}


@end
