/*
 * (C) Copyright 1992,2001 by Simson Garfinkel and Associates, Inc.
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law.
 *
 */

#import "AbstractReportView.h"

@class LabelMakerPanel;
@class LabelElement;
@class ZoomScrollView;
@interface LabelView:AbstractReportView
{
    /* Page Layout */
    IBOutlet NSFormCell	*leftLabelMarginCell;
    IBOutlet NSFormCell	*rightLabelMarginCell;
    IBOutlet NSFormCell	*topLabelMarginCell;
    IBOutlet NSFormCell	*bottomLabelMarginCell;
    
    IBOutlet NSMatrix	*textPositionMatrix;
    IBOutlet NSMatrix	*textAlignmentMatrix;

    IBOutlet NSFormCell *labelsWideCell;
    IBOutlet NSFormCell	*labelsHighCell;
    IBOutlet NSTextField *labelsPerPageField;

    IBOutlet NSPopUpButton *applyPresetButton;
    NSMutableDictionary *popupDictionary;

    int   labelsWide;
    int   labelsHigh;

    /* Layout support */
    int	ordinalOffset;
    int nextOrdinal;			// that was used

    /* Dragging Support */
    BOOL	dragging;			// am dragging
    LabelElement *draggedElement;	// element being dragged
    NSImage	*draggedSourceImage;	// what it looked like
    int		draggedSourceOrdinal;
    NSRect	draggedSourceRect;
    int		mouseDownOrdinal;	// where mouse went down
    int		draggedDestOrdinal;	// where it is being moved
    IBOutlet ZoomScrollView *zoomScrollView;
}

- (void)setLabelsWide:(int)wide;
- (void)setLabelsHigh:(int)high;
- (IBAction)resetElementsLayout:sender;

- (NSRect)rectForOrdinal:(int)ordinal;

- (int)textPositionTag;
- (int)textAlignmentTag;

- (float)leftLabelMargin;
- (float)rightLabelMargin;
- (float)topLabelMargin;
- (float)bottomLabelMargin;
- (IBAction)applyPreset:sender;

- (void)printWithWindow:(NSWindow *)windowToAttachSheet;
- (void)loadOrdinalOffset;
- (void)saveNextOrdinalOffset;			// remember ordinal for next 
- (void)printOperationDidRun:(NSPrintOperation *)printOperation success:(BOOL)success contextInfo:(void *)contextInfo;

@end
