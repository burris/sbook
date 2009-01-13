/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2004 by Simson L. Garfinkel.
 *
 * All Rights Reserved.
 *
 * The MultiPageView is an AbstractReportView that automatically lays out
 * MultiPageElements for each page face. TextElements are automatically laid out 
 * for pages that need notes if the "showNotes" flag is true.
 * 
 * The MultiPageElement each knows its containing View, and ask that view for the
 * docView, a portion of which is displayed when the MultiPageElement is asked to display.
 *
 *
 */


/* Generated by Interface Builder */

#import "AbstractReportView.h"

@interface MultiPageView:AbstractReportView
{
    IBOutlet AbstractReportView *docView;
    IBOutlet id printOptionsCover;

    NSRange  docPageRange;		// range of pages for doc view

    unsigned int	docPagesPerPage;
    unsigned int	docPagesToPlace;
    unsigned int	printOption;
    unsigned int	totalPages;		// print all, bottoms, tops
    
    NSFont		*foldFont;		// font for "fold here" ledgend
    unsigned int	folds;
    IBOutlet NSPopUpButton *foldsPopup;
    bool   showNotes;
    NSSize		docPageSize;
    float	pageHeight;		// used in layout
    float	pageWidth;
}

- (unsigned int)folds;
- (void)setShowNotes:(BOOL)flag;
- (void)setFolds:(unsigned int)numFolds;
- (void)setDocView:(AbstractReportView *)aDocView;
- (void)setPrintOption:(int)option;

- (void)addFirstLineAt:(float)y0 staple:(BOOL)sflag; // first fold here line
- (void)addSecondLineAt:(float)y staple:(BOOL)sflag; // 
- (void)addThirdLineAt:(float)y0 staple:(BOOL)sflag;
- (void)layout0;			// regular layout
- (void)layout1;			// layout a single-fold book
- (void)layout2;			// layout a two-fold book
- (void)layout3;			// layout a three-fold book
- (void)setEnabled:(BOOL)flag;		// controls popup
- (IBAction)layout:(id)sender;		// do the layout
- (IBAction)foldsChanged:(id)sender;
@end


/* Print options */
#define 	PRINT_ALL	0
#define		PRINT_TOPS	1
#define		PRINT_BOTTOMS	2
  