#import "History.h"
#import "SLC.h"

@implementation HistoryView
- initForSLC:(SLC *)slc
{
    [super init];
    searchString   = [[[slc searchCell] stringValue] retain];
    selectedPeople = [[slc selectedPeopleArray:NO] retain];
    return self;
}
    
- (NSString *)searchString { return searchString;}
- (NSArray *)selectedPeople { return selectedPeople;}

- (void)dealloc
{
    [searchString release];
    [selectedPeople release];
    [super dealloc];
}

/* isEqual only considers array, not search string */
- (BOOL)isEqual:(id)object
{
    if(![object isMemberOfClass:[self class]]) return NO;
    return [selectedPeople isEqual:[object selectedPeople]];
}


@end


@implementation History
- initForSLC:(SLC *)aSLC;
{
    [super init];
    views = [[[NSMutableArray alloc] init] retain];
    slc   = [aSLC retain];
    return self;
}

- (void)dealloc
{
    [views release];
    [slc   release];
    [super dealloc];
}

static int manipulatingHistory = 0;

- (void)save 
{
    History *newHistory;

    if(manipulatingHistory) return;

    /* Erase anything after the current location */
    if(ptr != [views count]){
	[views removeObjectsInRange:NSMakeRange(ptr,[views count]-ptr)];
    }
    
    /* Don't bother saving is the current history is equal to the last one */
    newHistory = [[HistoryView alloc] initForSLC:slc];

    if([[views lastObject] isEqual:newHistory]){
	//NSLog(@"history matches");
	return;
    }
    //NSLog(@"history doesn't match");

    /* Save the current search string */
    [views addObject:newHistory];
    ptr++;
}

- (BOOL)hasBack
{
    return ptr > 0 && [views count] > 0;
}

- (BOOL)hasForward
{
    return (ptr+1 ) < [views count];
}

- (void)setToPtr
{
    NSArray *added;

    HistoryView *hv = [views objectAtIndex:ptr];	// back up
    if(!hv){
	return;
    }

    //NSLog(@"setToPtr ptr=%d count=%d\n",ptr,[views count]);

    manipulatingHistory = 1;
    //NSLog(@"ptr=%d search=%@ selected=%@",ptr,[hv searchString],[hv selectedPeople]);


    /* Now set up the viewer */
    // search string
    [[slc searchCell] setStringValue:[hv searchString]]; 

    // selected people in visible list
    added = [slc addListToVisibleList:[hv selectedPeople]];

    [slc displayPersonEntryList:[hv selectedPeople]];
    manipulatingHistory = 0;
}

- (IBAction)forward:sender
{
    [slc saveEntry];
    if(ptr < [views count]-1){
	ptr++;
    }
    [self setToPtr];
}

- (IBAction)back:sender
{
    if(ptr>0){
	int nptr = ptr - 1;
	
	//NSLog(@"back: ptr=%d count=%d\n",ptr,[views count]);
	
	if(ptr==[views count] && ptr>1){
	    nptr = ptr - 2;
	}
	
	[slc saveEntry];
	
	
	ptr = nptr;
	[self setToPtr];
    }
}

@end


