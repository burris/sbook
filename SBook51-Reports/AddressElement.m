/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2002 by Simson L. Garfinkel
 *
 * All Rights Reserved.
 *
 */

#import <Cocoa/Cocoa.h>

#import "AddressElement.h"
#import "AddressElementLine.h"
#import "Person.h"
#import "AddressBookView.h"
#import "AddressBookPanel.h"
//#import "tools.h"
//#import "defines.h"

#define DEBUG


NSDictionary *attrs = nil;
				

@implementation AddressElement

+(void)initialize
{
    NSFont *ft = [[NSFont fontWithName:@"Times" size:10.0] retain];
    attrs = [[NSDictionary dictionaryWithObjectsAndKeys:
			       ft, NSFontAttributeName,
			   [NSColor blackColor],NSStrokeColorAttributeName, 0,0] retain];
}




- initPerson:(Person *)aPerson panel:(AbstractReportPanel *)aPanel
	view:(AbstractReportView *)aView
{
    [super init];

    panel = aPanel;
    view  = aView;
    person = [aPerson retain];
    lines = [[NSMutableArray alloc] init];
    return self;
}

-(void)dealloc
{
    [lines release];
    [person release];
    [personName release];
    [super dealloc];
}


- (Person *)person { return person;}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ person=%@ ",[super description],person];
}

- (void)addLine:(NSString *)buf tag:(int)tag
{
    AddressElementLine *lastLine = [lines lastObject];

    /* Create an element if one doesn't exist */
    if(lastLine==nil){
	lastLine = [AddressElementLine lineWithView:(AddressBookView *)view];
	[lines addObject:lastLine];
    }

    /* If we are adding right and we don't have a telephone, start
     * a new line...
     */
    if([lastLine addingRight] && tag!=P_BUT_TELEPHONE){
	lastLine = [AddressElementLine lineWithView:(AddressBookView *)view];
	[lines addObject:lastLine];
    }
	
    /* Finally, add the line! */
    [lastLine addLine:buf right:(tag==P_BUT_TELEPHONE)];
}


- (void)setWidth:(float)aWidth phoneWidth:(float)phoneNumberWidth;
{
    if(phoneNumberWidth > aWidth) phoneNumberWidth = aWidth;

    bounds.size.width = aWidth;
    phoneWidth 	      = phoneNumberWidth;
    addressWidth      = aWidth - phoneWidth;

    [self set];				// figure out the new widths and heights
}

- (float)nameWidth
{
    return [[lines objectAtIndex:0] width];
}

- (void)setDisplayPersonName:(BOOL)flag
{
    if(displayPersonName != flag){
	displayPersonName = flag;
	[self set];
    }
}


- (float)height
{
    [self set];
    return bounds.size.height;
}

/****************************************************************
 **
 ** set: layout the element
 **
 ****************************************************************/

#define address_view (AddressBookView *)view

-(void)set
{
    NSEnumerator *en = [lines objectEnumerator];
    float down = 0;
    AddressElementLine *obj;

    if(displayPersonName){
	personName = [[person cellName:[panel displayLastnameFirst]] retain];
	
	personNameRect.origin = bounds.origin;
	personNameRect.size   = [personName sizeWithAttributes:attrs];
	down += personNameRect.size.height;
    }

    while(obj = [en nextObject]){
	[obj setWidth:bounds.size.width rightWidth:phoneWidth];
	[obj setYoffset:down];
	down += [obj height];
    }
    bounds.size.height = down;		// computed!
}

/****************************************************************
 **
 ** drawElement: draw the element
 **
 ****************************************************************/

- (void)drawElementIn:(NSView *)v offset:(NSPoint)pt
{
    NSEnumerator *en = [lines objectEnumerator];
    AddressElementLine *obj=nil;

    NSRect bounds_offset = MakeOffsetRect(bounds,pt);
    NSRect personNameRect_offset = MakeOffsetRect(personNameRect,pt);

    [self screenStroke:bounds_offset color:[NSColor cyanColor]]; // draw the outer box

    if(displayPersonName){
	[personName
	    drawInRect:personNameRect_offset
	    withAttributes:attrs];
	[self screenStroke:personNameRect_offset color:[NSColor redColor]]; // draw the outer box
	NSLog(@"drawing %@ at %f,%f - %f,%f with %@",
	      personName,NSMinX(personNameRect_offset),NSMinY(personNameRect_offset),
	      NSWidth(personNameRect_offset),NSHeight(personNameRect_offset),
	      attrs);

    }


    while(obj = [en nextObject]){
	[obj drawWithOrigin:bounds_offset.origin];
    }
}

- (NSString *)personName
{
    return personName;
}



@end  

