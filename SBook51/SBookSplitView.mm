#import "SBookSplitView.h"

@implementation SBookSplitView

- (void)drawDividerInRect:(NSRect)aRect
{
    [[NSColor darkGrayColor] set];
    NSRectFill(aRect);
}

@end
