/* ExportingTableView */

#import <Cocoa/Cocoa.h>

enum  ColumnOneMode {
    Nothing = 0,
    FirstPhone = 1,
    FirstEmail = 2,
    SecondLine = 3
};


@class SLC,SList;
@interface ExportingTableView : NSTableView
{
    SLC		*slc;
    SList	*doc;
    NSTableColumn *col1;		// first column
    NSTableColumn *col2;		// second column
    NSMenu	*contextMenu;
    NSMenuItem	*showNothing;
    NSMenuItem	*showPhone;
    NSMenuItem	*showEmail;
    NSMenuItem	*showSecondLine;
    NSTableHeaderView *savedHeaderView;
}
- (void)setColumnOneMode;
- (void)popMenuWithEvent:(NSEvent *)theEvent;
@end


