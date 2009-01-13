/*
 * SBookIconView:
 * 
 * Works with the SBookText. Displays the icons
 */


#import <Cocoa/Cocoa.h>

@class SBookText,SLC;
@class SBookIcon;
@interface SBookIconView:NSRulerView
{
    SBookText		*text;
    float		margin;
    struct TextParagraphs *tp;		// paragraphs that were found
    unsigned int	*results;	// parsed results
    SLC			*slc;		// our SLC
    BOOL		displayIcons;	// true if we are displaying icons

    NSRectArray		rects;		// where each line of text is
    unsigned int	rectCount;	// number of lines of text


    NSMenu	*contextMenu;
    NSMenuItem  *forceNoneItem;
    NSMenuItem  *forceAutoItem;
    NSMenuItem  *forcePersonItem;
    NSMenuItem  *forceCompanyItem;


}

- (void)dealloc;
- (id)initWithScrollView:(NSScrollView *)scrollView
	     orientation:(NSRulerOrientation)orientation;
- (BOOL)displayIcons;
- (void)setDisplayIcons:(BOOL)aVal;
- (SBookText *)text;
- (void)setText:(SBookText *)aText;
- (void)layoutIcons;
- (void)reparse;			// reparse, rehighlight search, and show icons

- (const char *)line:(unsigned int)i;		// contents of line i
- (unsigned int)results:(unsigned int)i;	// contents of results[i]
- (unsigned int)numLines;
- (void)highlightSearchResults;	       // just show the search results
- (BOOL)isLineBold:(u_int)line;
- (int)whichLine:(NSPoint)pt;		// which line did the mouse hit? -1 for no line
- (void)mouseDown:(NSEvent *)theEvent;

// Menus
- (void)force:(id)sender;
- (void)popMenuWithEvent:(NSEvent *)theEvent;


// Notifications
- (void)textChanged:(NSNotification *)n;
- (void)visibleRectChanged:(NSNotification *)n;


@end

// Local Variables:
// mode:ObjC
// End:
