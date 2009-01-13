/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2003 by Simson Garfinkel and Associates, Inc.
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law.
 *
 */

#import "AbstractReportElement.h"


@class Person;
@class LabelView;
@interface LabelElement:AbstractReportElement
{
    LabelView		*labelview;
    NSString		*zip;		// our zip code, for sorting
    NSRect		printArea;	// where we can print inside the margins
    NSRect		textArea;	// where we put the text, given the alignment
    NSFont		*lfont;		// font we draw in
    NSFont		*ofont;		// font size that is originally passed in
    NSMutableDictionary *attrsWithoutAlignment;
    NSMutableDictionary *attrsWithAlignment;
    NSSize		textExtent;
    int			ordinal;
    BOOL		blank;		// a blank spacer
    NSMutableString	*text;
    Person		*person;
}

/* Line control */
- initPerson:(Person *)aPerson
   labelView:(LabelView *)aView;
- (Person *)person;
- (NSString *)text;
- (float)widthOfText;
- (float)heightOfText;
- (void)calculateTextExtent;
- (void)setFont:(NSFont *)aFont;
- (void)set;
- (void)reduceFontTo:(float)pointSize;			// go to a smaller font
- (void)setOrdinal:(int)anOrdinal;
- (int)ordinal;
- (NSString *)zip;
- (void)setBlank:(BOOL)flag;
- (void)addLine:(NSString *)buf tag:(int)tag;
- (void)drawElementIn:(NSView *)v offset:(NSPoint)pt;
@end
// Local Variables:
// mode:ObjC
// End:
