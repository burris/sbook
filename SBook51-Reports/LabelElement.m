/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 * (C) Copyright 2002 by Simson Garfinkel.
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law.
 *
 */

#import "LabelElement.h"
#import "Person.h"
#import "LabelMakerPanel.h"
#import "LabelView.h"
#import "../libsbook/find_zip.c"

@implementation LabelElement

- initPerson:(Person *)aPerson labelView:(LabelView *)lv
{
    [super init];
    person = [aPerson retain];
    labelview = lv;
    text = [[NSMutableString alloc] init];
    attrsWithAlignment    = [[NSMutableDictionary dictionary] retain];
    attrsWithoutAlignment = [[NSMutableDictionary dictionary] retain];
    return self;
}

- (void)dealloc
{
    [attrsWithAlignment release];
    [attrsWithoutAlignment release];
    [zip    release];
    [person release];
    [text release];
    [super dealloc];
}

- (NSString *)text {return text;}
- (Person *)person { return person;}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: text='%@' ordinal=%d blank=%d",
		     [super description],text,ordinal,blank];
}

- (NSString *)zip 	{ return zip; 		}



- (float)widthOfText
{
    return textExtent.width;
}

- (float)heightOfText
{
    return textExtent.height;
}

- (void)calculateTextExtent
{
    [attrsWithAlignment setObject:lfont forKey:NSFontAttributeName];
    [attrsWithoutAlignment setObject:lfont forKey:NSFontAttributeName];
    textExtent = [text sizeWithAttributes:attrsWithoutAlignment];
}

- (void)reduceFontTo:(float)pointSize
{
    NSFont	*newFont = [NSFont fontWithName:[ofont fontName] size:pointSize];

    [lfont release];
    lfont = [newFont retain];
    [self calculateTextExtent];
}

- (void)setFont:(NSFont *)aFont
{
    [lfont release];
    lfont = [aFont retain];

    [ofont release];
    ofont = [aFont retain];

    [self calculateTextExtent];
}

#define labelpanel ((LabelMakerPanel *)panel)

/* Figure out which pointsize to use for this label to make it fit */
- (void)set
{
    int		textAlignmentTag = [labelview textAlignmentTag];
    int		textPositionTag  = [labelview textPositionTag];
    NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
    float	slackWidth = 0;
    float	slackHeight= 0;
    float	leftLabelMargin = [labelview leftLabelMargin];
    float	rightLabelMargin = [labelview rightLabelMargin];
    float	topLabelMargin = [labelview topLabelMargin];
    float	bottomLabelMargin = [labelview bottomLabelMargin];

    if(leftLabelMargin > bounds.size.width) leftLabelMargin = 0;
    if(rightLabelMargin > bounds.size.width) rightLabelMargin = 0;
    if(leftLabelMargin + rightLabelMargin > bounds.size.width){
	leftLabelMargin = 0;
	rightLabelMargin = 0;
    }
	
    if(topLabelMargin > bounds.size.width) topLabelMargin = 0;
    if(bottomLabelMargin > bounds.size.width) bottomLabelMargin = 0;
    if(topLabelMargin + bottomLabelMargin > bounds.size.width){
	topLabelMargin = 0;
	bottomLabelMargin = 0;
    }

    printArea	= bounds;
    printArea.origin.x	 += [labelview leftLabelMargin];
    printArea.size.width -= [labelview leftLabelMargin] + [labelview rightLabelMargin];

    printArea.origin.y    += [labelview topLabelMargin];
    printArea.size.height -= [labelview bottomLabelMargin] + [labelview topLabelMargin];

    /* See if there is no space... */
    if(printArea.size.height < 0 ||
       printArea.size.width  < 0 ||
       [text length]==0){
	printArea.size.height = 0;
	printArea.size.width  = 0;
	textArea = printArea;
	return;
    }

    /* Determine the text alignment */
    switch(textAlignmentTag){
    default:
	[style setAlignment:NSLeftTextAlignment];
	break;
    case 2: 
	[style setAlignment:NSCenterTextAlignment];
	break;
    case 3: 
	[style setAlignment:NSRightTextAlignment];
	break;
    }
    [attrsWithAlignment setObject:style forKey:NSParagraphStyleAttributeName];

    /* While the font is too big, shrink the font */
    while([self widthOfText] > printArea.size.width ||
	  [self heightOfText] > printArea.size.height){

	float pointSize = [lfont pointSize];

	if(pointSize<5) break;		// give up

	[self	reduceFontTo:pointSize-1.0];
    }

    /* Finally, put the text in the page */
    textArea = printArea;
    slackWidth  = textArea.size.width  - [self widthOfText];
    slackHeight = textArea.size.height - [self heightOfText];

    /* alter the horizontal position if there is room */
    if(slackWidth > 0){
	switch(textPositionTag){
	case 1:    case 4:    case 7:	// left
	    textArea.size.width  = [self widthOfText];
	    break;
	case 2:    case 5:    case 8:	// center
	    textArea.origin.x	  += slackWidth/2;
	    textArea.size.width  = [self widthOfText];
	    break;
	case 3:    case 6:   case 9:	// right
	    textArea.origin.x   += slackWidth;
	    textArea.size.width = [self widthOfText];
	    break;
	}
    }
    
    /* Alter the vertical position if there is room */
    if(slackHeight > 0){
	switch(textPositionTag){
	case 1:  case 2:  case 3:	
	    textArea.size.height  = [self heightOfText];
	    break;
	case 4:  case 5:  case 6:
	    textArea.origin.y     += slackHeight/2;
	    textArea.size.height  = [self heightOfText];
	    break;
	case 7: case 8: case 9:
	    textArea.origin.y     += slackHeight;
	    textArea.size.height  = [self heightOfText];
	    break;
	}
    }
}

- (void)setBlank:(BOOL)flag {blank = flag;}


/* note: ignores offset and view */
- (void)drawElementIn:(NSView *)v offset:(NSPoint)pt
{
    //NSLog(@"drawing %@",self);


    if([NSGraphicsContext currentContextDrawingToScreen]==YES){
	if(blank){
	    [[NSColor lightGrayColor] set];
	    NSRectFill([self bounds]);
	}
    }

    [self screenStroke:bounds color:[NSColor blackColor]];

    if(text && [text length]){
	[self	screenStroke:printArea color:[NSColor cyanColor]];
	[self	screenStroke:textArea color:[NSColor orangeColor]];
	[text	drawInRect:textArea withAttributes:attrsWithAlignment];
    }
}

- (int)ordinal  {    return ordinal;}

- (void)setOrdinal:(int)anOrdinal
{
    ordinal = anOrdinal;
    [self setBounds:[labelview rectForOrdinal:ordinal]];
}

- (void)addLine:(NSString *)buf tag:(int)tag
{
    if([text length]>0){
	[text	appendString:@"\n"];
    }
    [text	appendString:buf];

    if(!zip){				// see if I can get a zip
	const char *z;
	int   len;

	z = find_zip([buf UTF8String],&len);
	if(z)	zip = [[NSString stringWithUTF8String:z] retain];
    }
}


@end
