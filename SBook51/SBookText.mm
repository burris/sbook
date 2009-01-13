/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2001, 2002 by Simson Garfinkel.
 *
 */

#import "SBookText.h"
#import "SBookIconView.h"
#import "defines.h"
#import "SBookController.h"
#import "SLC.h"
#import "tools.h"
#import "DefaultSwitchSetter.h"

#import <assert.h>

@implementation SBookText

+(void)initialize
{
    [NSScrollView setRulerViewClass:[SBookIconView class]];
}

- (void)awakeFromNib
{
    [myScroller setHasHorizontalRuler:NO];
    [myScroller setHasVerticalRuler:YES];
    [myScroller setRulersVisible:YES];
    [self	setAllowsUndo:YES];
    slc = [[self window] delegate];
    assert(slc);
}

/****************************************************************
 *** CODE TO WORK WITH APPKIT
 ****************************************************************/

/* Some weird appkit bug; am I causing this? */
- (void)setFrameOrigin:(NSPoint)newOrigin
{
    newOrigin.y = 0;
    [super setFrameOrigin:newOrigin];
}

/* Some weird appkit bug; am I causing this? */
- (void)setFrame:(NSRect)frameRect
{
    frameRect.origin.y = 0;		// bring back to hearth
    [super setFrame:frameRect];
}


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent { return NO;}

- (void)setEditable:(BOOL)flag
{
    if(flag==YES){			// we might want to do something
    }
    [super setEditable:flag];
}


/* Code for parsing */

- (void)setIconView:(SBookIconView *)anIconView
{
    iconView = anIconView;
}

-(void)setTag:(int)aTag
{
    tag = aTag;
}

-(int)changeCount
{
    return changeCount;
}

-(void)incrementChangeCount
{
    changeCount++;
}


- (NSRect)documentVisibleRect
{
    return documentVisibleRect;
}

- (void)drawRect:(NSRect)rect
{
    NSRect visibleRect = [(NSClipView *)[self superview] documentVisibleRect];
    if(NSEqualRects(documentVisibleRect,visibleRect)==NO){
	documentVisibleRect = visibleRect;
	[[NSNotificationCenter defaultCenter]
	    postNotificationName:VisibleRectChanged object:self];
    }
    [super drawRect:rect];
}

- (void)rememberFirstLine
{
    [oldFirstLine release];
    oldFirstLine = [[self getParagraph:0] retain];
}

- (void)checkFirstLine
{
    /* Now see if the first line changed */
    if([oldFirstLine isEqualToString:[self getParagraph:0]]==NO){	// first line changed
	[slc setNameToFirstLine:YES]; // get the first line change
	[slc setTextChanged:YES];	// definately has
    }
}



/****************************************************************
			    EVENT HANDLING
 ****************************************************************/

- (void)keyDown:(NSEvent *)theEvent
{
    NSString *eventChars = [theEvent characters];

    [self rememberFirstLine];

    /* If carriage return is typed on the first line,
     * then just select the second line, if this is a new entry...
     */
    if([eventChars length]>0){
	unichar ch = [eventChars characterAtIndex:0];

	if(ch == 25 &&
	   ([theEvent modifierFlags] & (NSShiftKeyMask|NSAlternateKeyMask))){
	    [[self window] makeFirstResponder:[slc searchCell]];
	    return;
	}

	if(ch =='\r'){
	    NSRange p0  = [self getParagraphRange:0];
	    NSRange sel = [self selectedRange];
	    
	    if(sel.location <= p0.length &&
	       ([theEvent modifierFlags] & NSAlternateKeyMask)==0){
		NSRange p1 = [self getParagraphRange:1];
		
		if([slc newEntryFlag]){
		    if(p1.location>sel.location){
			[self setSelectedRange:p1];
			return;
		    }
		}
		/* Carriage return on an old entry; get the font of the second line,
		 * insert the carraige return, then paste the font...
		 */
		
		[self setSelectedRange:[self getParagraphRange:1]];
		[self copyFont:nil];
		[self setSelectedRange:sel];
		[super keyDown:theEvent];
		sel = [self selectedRange];	// remember where we were after insert
		[self setSelectedRange:[self getParagraphRange:1]];
		[self pasteFont:nil];
		[self setSelectedRange:sel];
		goto skip_super;
	    }
	}
	
	/* If delete is pressed on the second line, the do the delete but
	 * extend the font from the beginning of the first line to the end...
	 */
	if(ch =='\177'){
	    NSRange p0  = [self getParagraphRange:0];
	    NSRange sel = [self selectedRange];
	    
	    if(sel.location == p0.length+1 && sel.length==0){
		[super keyDown:theEvent];
		[self setSelectedRange:NSMakeRange(0,1)];
		[self copyFont:nil];
		[self setSelectedRange:[self getParagraphRange:0]];
		[self pasteFont:nil];
		[self setSelectedRange:NSMakeRange(sel.location-1,0)];
		goto skip_super;
	    }
	}
    }

    [super keyDown:theEvent];
 skip_super:

    [self checkFirstLine];
    [self sizeToFit];
    [self scrollRangeToVisible:[self selectedRange]];
    [[[self window] delegate] setTextChanged:YES]; // just be safe
}


- (void)mouseDown:(NSEvent *)theEvent
{
    if(![self isEditable]){
	/* If it is not editable and nothing is displayed and
	 * there is no current person, simulate a newEntry: comamnd.
	 */
	if([slc numDisplayedPeople]==0 &&
	   [[defaults objectForKey:DEF_AUTO_CREATE_ON_BLANK_CLICK] intValue]){
	    [slc newEntry:self];
	    [slc setStatus:@"Created new entry"];
	    return;
	}
    }
    [super mouseDown:theEvent];
}


/****************************************************************
			     COPY & PASTE
 ****************************************************************/


-(IBAction)paste:(id)sender
{
    [self rememberFirstLine];
    /* Remove color? */
    if([[defaults objectForKey:DEF_REMOVE_COLOR_FROM_PASTED_TEXT] intValue]){
	NSRange r0,r1;

	r0 = [self selectedRange]; // remember where we are

	[super paste:sender];		// do the paste
	r1 = [self selectedRange];	// find out where we are
	[self setTextColor:[NSColor blackColor] range:NSMakeRange(r0.location,r1.location-r0.location)];
    }
    else {
	[super paste:sender];
    }
    [iconView reparse];
    [self checkFirstLine];
    [[[self window] delegate] setTextChanged:YES];
}

-(IBAction)cut:(id)sender
{
    [self rememberFirstLine];
    [super cut:sender];
    [iconView reparse];
    [self checkFirstLine];
    [[[self window] delegate] setTextChanged:YES];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)item
{
    SEL action = [item action];

    if(action == @selector(printLabelFromSelection:)){
	NSRange r = [self selectedRange];
	if(r.length>0) return YES;
	return NO;
    }
    return [super validateMenuItem:item];
}

#if 0
/* If we are pasting into the first line:
 * 1. Only do a paste of ASCII.
 * 2. If the selection goes between lines, erase the lines seperately but do not erase the
 *    line break.
 * 2. If there is a line break, paste the remainder onto the second line in the second-line font.
 * 3. Update the cell.
 */

- paste:sender
{
	NXSelPt	startSel,endSel;		/* current selection */
	id	pboard;
	char	*pdata;
	char	*data;
	int	length;
	char	*cr;
	const	NXAtom *types;
	int	pos;

	
	if(![delegate isKindOf:[EntryDelegate class]]) return [super paste:sender]; /* not in an entry */

	[self	getSel:&startSel :&endSel];

	if(startSel.line!=0){
		NXSelPt	startSel2,endSel2;		/* current selection */
		id	res;

		/* regular paste.  Do the paste.  Then if there was a cr in the stream, do a manual parse. */
		res = [super paste:sender];
		[self	getSel:&startSel2 :&endSel2];
		if(startSel.line != startSel2.line || endSel.line != endSel2.line){
			[delegate tryToPerform:@selector(didReturn)];
		}
		return res;
		
	}

	pboard 	= [Pasteboard new];
	types	= [pboard types];

	if(![pboard readType:NXAsciiPboardType data:&pdata length:&length]){
		return [super paste:sender]; 	/* I couldn't read the data... */
	}
	data		= alloca(length+1);
	memcpy(data,pdata,length);
	data[length]	= 0;

	cr	= index(data,'\n');
	if(!cr){
		/* No carraige return.  Just handle with replace */
		[self	replaceSel:data];
	}
	else{
		int	start,end;
		char *secondLine = cr+1; 
		*cr	= '\000';	/* terminate first line */

		[self	getParagraph:0 start:&start end:&end];

		if(startSel.line==endSel.line){
			/* only first line selected */
			[self	setSel:end+1 :end+1];
			[self	replaceSel:secondLine];
			[self	setSel:startSel.cp :endSel.cp];
			[self	replaceSel:data];
		}
		else{
			/* multi-line selection.*/
			[self	setSel:end+1 :endSel.cp];
			[self	replaceSel:secondLine];
			[self	setSel:startSel.cp :end];
			[self	replaceSel:data];
		}
	}
	pos	= startSel.cp + length;
	[self	setSel:pos :pos];

	if(cr){
		[[delegate slc] manualParse:nil];
	}

	vm_deallocate(task_self(),(int)pdata,length); /* free the data */
	
	/* Inform delegate to update if necessary */
	if([delegate isKindOf:[EntryDelegate class]]){
		[[delegate slc] setNameToFirstLine:NO];
	}
	return self;
}
#endif

/* dragging */
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    id	ds = [sender draggingSource];
    BOOL myWindow = [ds respondsToSelector:@selector(window)] && [ds window]==[self window];
    BOOL me = [ds isEqualTo:self];

    NSLog(@"draggingEntered...");

    if(myWindow && !me){	     /* don't accept from my window, unless it's me */
	return NSDragOperationNone; 
    }
    if(![self isEditable]) return NO;
    return [super draggingEntered:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    id	ds = [sender draggingSource];
    BOOL myWindow = [ds respondsToSelector:@selector(window)] && [ds window]==[self window];
    BOOL me = [ds isEqualTo:self];

    if(myWindow && !me){	     /* don't accept from my window, unless it's me */
	return NSDragOperationNone; 
    }
    if(![self isEditable]) return NO;
    return [super prepareForDragOperation:sender];
}


- (IBAction)switchToFont1:sender
{
    NSLog(@"switchFont1");
    [[NSFontManager sharedFontManager] setSelectedFont:[NSFont userFontOfSize:12.0] isMultiple:NO];
    [[NSFontManager sharedFontManager] convertFont:sender];
}

- (IBAction)switchToFont2:sender
{
    NSLog(@"switchFont2");
    [[NSFontManager sharedFontManager] setSelectedFont:[NSFont fontWithName:@"Symbol" size:12.0] isMultiple:NO];
    [[NSFontManager sharedFontManager] convertFont:sender];
}


- (BOOL)becomeFirstResponder
{
    [slc delayedHighlightDisplay];
    return [super becomeFirstResponder];
}


- (BOOL)resignFirstResponder
{
    [slc delayedHighlightDisplay];
    return [super resignFirstResponder];
}


- (IBAction)insertTimeStamp:sender
{
    time_t t = time(0);
    struct tm tm;
    int pm = 0;
    
    localtime_r(&t,&tm);
    if(tm.tm_hour>=12){
	pm = 1;
	if(tm.tm_hour>12) tm.tm_hour -= 12;
    }
    if(tm.tm_hour==0) tm.tm_hour = 12;

    [self replaceCharactersInRange:[self selectedRange] withString:
	      [NSString stringWithFormat:@"%d:%02d %s ",
			tm.tm_hour,tm.tm_min,pm ? "pm" : "am"]];
}

- (IBAction)insertDateStamp:sender
{
    time_t t = time(0);
    struct tm tm;
    char *months[12]={"JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"};
    
    localtime_r(&t,&tm);

    [self replaceCharactersInRange:[self selectedRange] withString:
	      [NSString stringWithFormat:@"%4d-%3s-%2d ",
			tm.tm_year+1900,
			months[tm.tm_mon],
			tm.tm_mday]];
}


- (IBAction)insertDateandTimeStamp:sender
{
    [self insertDateStamp:sender];
    [self insertTimeStamp:sender];
}

- (void)cleanUpAfterDragOperation
{
    [super cleanUpAfterDragOperation];
    [slc setTextChanged:YES];
}


@end
