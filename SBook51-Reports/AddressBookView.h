/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
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

@class MultiPageView;
@interface AddressBookView:AbstractReportView
{
    IBOutlet MultiPageView *multiPageView;
    IBOutlet NSPopUpButton *columnsPopup;
    IBOutlet NSFormCell *gutterCell;
    IBOutlet NSFormCell *phoneNumberWidthCell;
    IBOutlet NSFormCell *betweenEntrySpacingCell;

    IBOutlet NSPopUpButton *formatButton;
}

- (void)setMargins:(float)margins gutter:(float)gutter
phoneNumberWidth:(float)width betweenEntrySpace:(float)space columns:(int)cols folds:(int)folds;

- (void) insertPageNumber:(int)pageNumber;
- (int)  columns;
- (float)gutter;

- (float) columnWidth;
- (float) phoneNumberWidth;
- (float) betweenEntrySpacing;
- (void)setAddressFormat:(int)num;
- (IBAction)changedPresetAddress:sender;
- (BOOL) displayPhoneNumbers;		// whether or not they are being displayed

- (NSFont *)fontForTag:(int)tag;
- (NSDictionary *)fontAttrsForTag:(int)tag;

@end
