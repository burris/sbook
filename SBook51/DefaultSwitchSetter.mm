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
#import "DefaultSwitchSetter.h"
#import "tools.h"

#import <assert.h>

/* types to set into the defaults database */
#define	BOOLEAN	1
#define	FLOAT	2
#define	INT	3
#define	TAG	4
#define	TITLE	5
#define STRING	6



static NSMutableArray *allDefaultSetters = 0;

@implementation NSTabView(stringvalue)
-(NSString *)stringValue
{
    return [NSString stringWithFormat:@"%d",[self indexOfTabViewItem:[self selectedTabViewItem]]];
}
@end

@implementation DefaultSwitchSetter
+(void)initialize
{
    allDefaultSetters = [[NSMutableArray alloc] init];
}

+(id)objectWatching:aControl
{
    NSEnumerator *en = [allDefaultSetters objectEnumerator];
    id obj;

    while(obj = [en nextObject]){
	if([obj control]==aControl){
	    return obj;
	}
    }
    return nil;
}

+ (void)setDefaultFor:obj key:(NSString *)akey
{
    id	setter;
    NSString *val;

    if([allDefaultSetters containsObject:obj]){
	return ;			// a default is already set.
    }

    val = [defaults objectForKey:akey];
    if(val==0){
	/* Programmer couldn't be bothered to set a default value.? */
	NSMutableDictionary *appDefs = [NSMutableDictionary dictionary];
	val = [obj stringValue];
	[appDefs setObject:val forKey:akey];
	[defaults registerDefaults:appDefs];
    }
    setter = [[DefaultSwitchSetter alloc] initKey:akey control:obj value:val];
    [setter setLastIntValue:[val intValue]];
}

- initKey:(NSString *)aKey control:aControl value:(NSString *)val
{
    [super	init];
    key	= [[NSString stringWithString:aKey] retain];
    control = [aControl retain];
    [allDefaultSetters addObject:self];
    
    if([aControl isKindOfClass:[NSTextView class]]){
	[aControl 	setString:val];
	[aControl	setDelegate:self];
	return self;
    }

    if([aControl respondsToSelector:@selector(setTarget:)]){
	oldTarget = [aControl target];
	oldAction = [aControl action];
	[aControl setTarget:self];
	[aControl setAction:@selector(changed:)];
    }

    if([aControl isKindOfClass:[NSPopUpButton class]]){
	[aControl  selectItemWithTag:[val intValue]];
	return self;
    }

    if([aControl isKindOfClass:[NSButton class]]){
	[aControl setIntValue:[val intValue]];
	return self;
    }
    if([aControl isKindOfClass:[NSMatrix class]]){
	[aControl selectCellWithTag:[val intValue]];
	return self;
    }
    if([aControl isKindOfClass:[NSTextField class]]){
	[aControl 	setStringValue:val];
	[aControl	setDelegate:self];
	return self;
    }
    if([aControl isKindOfClass:[NSFormCell class]]){
	[aControl 	setStringValue:val];
	[(NSMatrix *)[aControl controlView] setDelegate:self];
	return self;
    }
    if([aControl isKindOfClass:[NSTabView class]]){
	[aControl	selectTabViewItemAtIndex:[val intValue]];
	[aControl	setDelegate:self];
	return self;
    }

    NSLog(@"setDefault: unknown class '%@'",aControl);
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [key release];
    [control setTarget:nil];		// not me anymore!
    [control release];
    [super dealloc];
}

- control { return control; }

- (IBAction)changed
{
    id	enabled=nil;
    id	disabled=nil;
    NSString	*value = nil;

    if([control isKindOfClass:[NSMatrix class]]){
	value  = [NSString stringWithFormat:@"%d",[[control selectedCell] tag]];
    }
	
    if([control isKindOfClass:[NSTextView class]]){
	value = [control string];
    }

    if([control isKindOfClass:[NSTabView class]]){
	value = [NSString stringWithFormat:@"%d",
			  [control indexOfTabViewItem:[control selectedTabViewItem]]];
    }

    if([control isKindOfClass:[NSPopUpButton class]]){
	value = [NSString stringWithFormat:@"%d",[control tagOfTitle]];
    }

    if(!value){
	value = [control stringValue];
    }

    [defaults setObject:value forKey:key];
    //NSLog(@"[%@ setObject:%@ forKey:%@",defaults,value,key);

    lastIntValue = [value intValue];

    enabled	 = lastIntValue ? self : nil;
    disabled = lastIntValue ? nil  : self;
	
    [autoEnableList makeObjectsPerformSelector:@selector(setEnabled:) withObject:enabled];
    [autoDisableList makeObjectsPerformSelector:@selector(setEnabled:) withObject:disabled];
    [[NSNotificationCenter defaultCenter]
	postNotificationName:key
	object:control];		// say that it has changed

}

- (IBAction)changed:sender		// external entry point - forward to old action
{
    [self changed];
    if(oldTarget && oldAction){
	[control sendAction:oldAction to:oldTarget];
    }
}

- (void)setAutoEnable:aControl
{
    if(!autoEnableList){
	autoEnableList = [[NSMutableArray allocWithZone:[self zone]] init];
    }
    [autoEnableList addObject:aControl];
    [aControl	setEnabled:lastIntValue];
    if([aControl respondsToSelector:@selector(setTextColor:)]){
	[aControl setTextColor:lastIntValue ?
		  [NSColor blackColor] : [NSColor darkGrayColor]];
    }
}

- (void)setAutoDisable:aControl
{
    if(!autoDisableList){
	autoDisableList = [[NSMutableArray allocWithZone:[self zone]] init];
    }
    [autoDisableList addObject:aControl];
    [aControl	setEnabled:!lastIntValue];
    if([aControl respondsToSelector:@selector(setTextColor:)]){
	[aControl setTextColor:!lastIntValue ?
		  [NSColor blackColor] : [NSColor darkGrayColor]];
    }
}

-(void)textDidChange:(NSNotification *)notification
{
    [self	changed];
}

- (void)setLastIntValue:(int)aValue
{
    lastIntValue = aValue;
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [self	changed];
}


@end

#if 0
id	setSlider(id slider,id field,const char *key)
{
    id	setter = [[DefaultSwitchSetter alloc] initOwner:AppOwner key:key type:FLOAT];
    [slider	setFloatValue:atof(NXGetDefaultValue(AppOwner,key))];
    [[slider setTarget:setter] setAction:@selector(changed:)];
    [setter	setMonitoredSlider:slider];

    [field 	setFloatValue:atof(NXGetDefaultValue(AppOwner,key))];
    [[field	setTarget:setter] setAction:@selector(changed:)];
    [setter	setMonitoredField:field];
    return	setter;
}

id	setPopup(id cover,id switcher,const char *key)
{
    id	setter  = [[DefaultSwitchSetter alloc] initOwner:AppOwner key:key type:TITLE];
    id	popup	= [cover target];
    id	cellList= [[popup  itemList] cellList];
    int	i;

    [setter	setMatrix:YES];
    [cellList makeObjectsPerform:@selector(setTarget:) with:setter];
    [cellList makeObjectsPerform:@selector(setAction:) with:(id)@selector(changed:)];
    [setter	setSwitcher:switcher];
    [cover 	setTitle:NXGetDefaultValue(AppOwner,key)];

    /* 
     * Find the cell with the current title and set the switcher to that cell's tag...
     */
    if(switcher){
	for(i=0;i<[cellList count];i++){
	    id	cell = [cellList objectAt:i];
			
	    if(!strcmp([cell title],[cover title])){
		[switcher setViewNumber:[cell tag]];
	    }
	}
    }

    return	setter;
}
#endif
