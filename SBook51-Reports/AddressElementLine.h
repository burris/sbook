/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2002 by Simson L. Garfinkel
 *
 * All Rights Reserved.
 *
 * AddressElement is an element that can display a collection of lines.
 * It remembers the tag for each line and displays each line with the
 * appropriate font of its controlling view. 
 *
 * format:
 *
 * NAME
 * label:
 * address1		phone1
 * address2		phone2
 * address3		phone3
 */

#import "AbstractReportElement.h"

@class AddressBookView;
@class Person;


/* Object for each address element block.
 * The block can have text on the left and text on the right.
 * They print side-by-side. The element says how tall it is, which is the
 * height of the taller. If there is no text on the right, the text on the
 * left is allowed the entire area.
 */
@interface AddressElementLine:AbstractReportElement
{
    AddressBookView	*view;
    NSDictionary	*fontAttrsLeft;
    NSDictionary	*fontAttrsRight;
    NSMutableString	*textLeft;
    NSMutableString	*textRight;
    float		width;	// width of entire element
    float		rightWidth;	// width of phone number areat
    float		yoffset;	// how far down it is set
}

+ lineWithView:(AddressBookView *)aView;
- initWithView:(AddressBookView *)aView;
-(BOOL)addingRight;			// true if we have started adding to the right
-(void)addLine:(NSString *)line right:(BOOL)flag; // should add?
-(NSSize)rightSize;			// just the text block
-(NSSize)leftSize;			// just the text block

/* Derrived */
-(float)height;				// highest of right and left
-(float)leftWidth;			// width-right or width, depending if there is right text or not
-(void)drawWithOrigin:(NSPoint)pt;
-(void)setYoffset:(float)offset;
-(void)setWidth:(float)aWidth rightWidth:(float)aRightWidth;

@end



  
