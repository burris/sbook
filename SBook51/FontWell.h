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


#import <Cocoa/Cocoa.h>


@interface FontWell:NSColorWell
{
    NSFont	*theFont;
    NSFont	*displayFont;		// if not theFont
    NSMutableAttributedString *displayString;
    BOOL	inFontPanel;
    float	drawPointSize;
    NSMenu	*contextMenu;

    NSRect	contentRect;		// set by draw: might it be a problem in some specific situations??? I hope not: before the view can be clicked at, it *must* be drawn at least once...
    BOOL	supportsColor;

    NSDictionary *fontAttributes;	// theFont

    /* default support --- not yet implemented */
    NSString	*owner;
    NSString	*key;
}

+ (void)deactivateAllWells;
+ (void)activeWellsTakeFontFrom:sender;

// API works the way NSColorWell does. Outcommented methods are just inherited

//- (void)deactivate;
//- (void)activate:(BOOL)exclusive;
//- (BOOL)isActive;


- initWithFrame:(NSRect)aRect;
- (void)drawRect:(NSRect)aRect;
- (void)setFont:(NSFont *)aFont;
- (IBAction)takeFontFrom:(id)sender;
- (NSFont *)font;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)setInFontPanel:(BOOL)flag;
- (void)setActive:(BOOL)flag;
- (BOOL)isActive;

//- (void)dragFont:aFont withEvent:(NSEvent *)anEvent;
//- (NSString *)defaultsName;
//- (void)setFromDefault:(NSString *)aKey;

// Normally FontWell displays with the actual font;
// set a displayFont to display in that font.
- (void)setDisplayFont:(NSFont *)aFont;

// note: the color API remains unchanged.
// That's all right, since a color is a font attribute as well!
// though, there might be cases when we don't like it, so:
- (BOOL)supportsColor;
- (void)setSupportsColor:(BOOL)coloured;
- (NSColor *)color;
//- (void)takeColorFrom:(id)sender;
//- (void)setColor:(NSColor *)color;

- (IBAction)displayLinkedFontPanel:(id)sender;

// fontAttributes returns an NSDictionary of font attributes.
// When font is changed, a different dictionary will be returned, so you can just keep the id.
- (NSDictionary *)fontAttributes;	

@end
