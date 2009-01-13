/* ZoomScrollView */

#import <Cocoa/Cocoa.h>

@interface ZoomScrollView : NSScrollView
{
    IBOutlet id subView;
    IBOutlet id zoomButton;
    float scaleFactor;
    //    NSRect originalContentViewFrame;
}
- (IBAction)changeZoom:(id)sender;
- (void)setScaleFactor:(float)aFloat;
- (float)scaleFactor;
@end
