/* ExportInfoView */

#import <Cocoa/Cocoa.h>

@class SLC;
@interface ExportFileInfoView : NSView
{
    IBOutlet id messageCell;
    IBOutlet id delimiterPopup;
    IBOutlet id formatPopup;
    id savePanel;
    id currentRemoveSwitch;		// 
    SLC *slc;
    NSArray *exportArray;		// set array to export
}
- (void)awakeFromNib;
- (void)setSavePanel:(NSSavePanel *)aPanel;
- (void)setSLC:(SLC *)slc;
- (void)setupForFormat;
- (void)setExportArray:(NSArray *)aList;
- (int)exportFormatTag;
- (IBAction)takeExportFormat:(id)sender;
- (void)setDefaultFormat;
- (NSDictionary *)exportInfo;
- (void)exportToPath:(NSString *)path;
- (void)savePanelDidEnd:sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

