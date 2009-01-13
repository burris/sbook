/*
 * SBookIcon: 
 * Displays the little icon.
 */

#import <Cocoa/Cocoa.h>

@class SBookIconView,Person,SLC;
@interface SBookIcon : NSView
{
    SBookIconView *iv;			// my iconView
    Person	*person;
    NSRect	loc;				// where we should draw the icon
    NSRect	tr;				// the tracking rectangle
    int		flag;			// what we are
    int		line;			// what line it was
    NSRect	lineRect;			// where the line is displayed
    SLC		*slc;
    BOOL	selected;		// is the button down?

}

+ (NSImage *)imageForFlag:(int)i;

+ iconForOrigin:(NSPoint)pt_ flag:(int)flag_  slc:(SLC *)aSLC person:(Person *)aPerson
	inView:(SBookIconView *)iv_ line:(int)i;

- (SBookIcon *)initWithFrame:(NSRect)frame_ flag:(int)flag_ slc:(SLC *)slc_ 
		      person:(Person *)person_ inView:(SBookIconView *)iv_
			line:(int)line_;

- (NSString *)stringForSelectedIconWithName:(BOOL)nameFlag forPasteboard:(BOOL)flag;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;

@end


// Local Variables:
// mode:ObjC
// End:
