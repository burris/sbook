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

#import "AbstractReportPanel.h"

@interface LabelMakerPanel:AbstractReportPanel
{
    BOOL oneLabel;
    IBOutlet NSButton	*entireEntryOnLabelCell;
}

- (void)generateLabelForString:(NSString *)str;

@end

/* center modes */
#define	LABELS_LEFT	0
#define LABELS_CENTER   1
#define LABELS_CENTERED 2  

/* sort modes */
#define BY_NAME  	0
#define BY_ZIP		1
