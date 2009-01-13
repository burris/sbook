/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2002 by Simson L. Garfinkel
 *
 * All Rights Reserved.
 *
 */

#import <Cocoa/Cocoa.h>

#import <Person.h>


#import "AddressElementLine.h"
#import "AddressBookView.h"
#import "AddressBookPanel.h"
#import "AddressElement.h"

@implementation AddressElementLine
+ lineWithView:(AddressBookView *)aView
{
    self = [[[AddressElementLine alloc] initWithView:aView] autorelease];
    return self;
}

- initWithView:(AddressBookView *)aView
{


    [super init];
    view = aView;
    textLeft  = [[NSMutableString alloc] init];
    textRight = [[NSMutableString alloc] init];
    fontAttrsLeft  = [[view fontAttrsForTag:P_BUT_ADDRESS] retain];
    fontAttrsRight = [[view fontAttrsForTag:P_BUT_TELEPHONE] retain];

    {
	NSFont *ft = [[NSFont fontWithName:@"Times" size:10.0] retain];
	NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
						 ft, NSFontAttributeName,
					    [NSColor blackColor],NSStrokeColorAttributeName, 0,0];
	fontAttrsLeft = [attrs retain];
	fontAttrsRight = [attrs retain];
    }

    

#ifdef DEBUG
    NSLog(@"%@: init",self);
#endif
    return self;
}

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"%@: dealloc",self);
#endif
    [textLeft release];
    [textRight release];
    [fontAttrsLeft release];
    [fontAttrsRight release];
    [super dealloc];
}

-(BOOL)addingRight { return [textRight length]>0;}

-(void)addLine:(NSString *)buf right:(BOOL)rightFlag
{
    NSMutableString *text = rightFlag ? textRight : textLeft;

#ifdef DEBUG
    NSLog(@"%@: addLine '%@'",self,buf);
#endif
    if([text length]>0){
	[text appendString:@"\n"];
    }
    [text appendString:buf];
}

- (NSSize)rightSize
{
    return [textRight sizeWithAttributes:fontAttrsRight];
}

- (NSSize)leftSize
{
    return [textLeft sizeWithAttributes:fontAttrsLeft];
}

- (float)height
{
    float rightHeight = [self rightSize].height;
    float leftHeight  = [self leftSize].height;

    return (rightHeight > leftHeight) ? rightHeight : leftHeight;
}

-(float)leftWidth
{
    if([textRight length]>0) return width-rightWidth;
    return width;
}

-(void)setWidth:(float)aWidth rightWidth:(float)aRightWidth
{
    width = aWidth;
    rightWidth = aRightWidth;
}


-(void)drawWithOrigin:(NSPoint)pt
{
    NSRect rect;

    pt.y += yoffset;			// space down by our given offset

    /* Show the outline of the box and the phone area */
    rect.origin = pt;
    rect.size.width = width;
    rect.size.height = [self height];

    [self screenStroke:rect color:[NSColor yellowColor]]; // the whole thing

    /* Draw the box for the address */
    rect.size = [self leftSize];
    rect.size.width = [self leftWidth];
    [self screenStroke:rect color:[NSColor greenColor]]; // the whole thing
    [textLeft drawInRect:rect withAttributes:fontAttrsLeft];

    /* Now show the box for the telephone if we are supposed to */
    if([view displayPhoneNumbers] && [textRight length]>0){
	rect.origin.x = pt.x + width - rightWidth;
	rect.size.width  = rightWidth;
	rect.size.height = [self rightSize].height;
	[self screenStroke:rect color:[NSColor blueColor]]; // the whole thing
	[textRight drawInRect:rect withAttributes:fontAttrsRight];
    }
}

-(void)setYoffset:(float)offset
{
    yoffset = offset;
#ifdef DEBUG
    NSLog(@"offset set to %f",yoffset);
#endif
}


@end


