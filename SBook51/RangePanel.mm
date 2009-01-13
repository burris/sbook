#import "RangePanel.h"
#import "SLC.h"
#import "SList.h"
#import "tools.h"

#define ALL_ENTRIES_TAG 1
#define ALL_ENTRIES_DISPLAYED_TAG 2
#define ALL_ENTRIES_SELECTED_TAG 3

@implementation RangePanel

-(void)awakeFromNib
{
    allEntries		= [[[selectionMatrix cellWithTag:ALL_ENTRIES_TAG] title] retain];
    allEntriesDisplayed = [[[selectionMatrix cellWithTag:ALL_ENTRIES_DISPLAYED_TAG] title] retain];
    allEntriesSelected  = [[[selectionMatrix cellWithTag:ALL_ENTRIES_SELECTED_TAG] title] retain];
}


- (NSArray *)selected { return selected;}

- (void)proceed:sender
{

    [super proceed:sender];
    if(endSelector){
	[endTarget performSelector:endSelector withObject:selected];
    }
}

- (IBAction)setToday:sender
{
    time_t now = time(0);
    struct tm *tm = localtime(&now);

    [yearPopup setTitle:[NSString stringWithFormat:@"%d",tm->tm_year+1900]];
    [monthPopup selectItemAtIndex:tm->tm_mon];
    [dateField setIntValue:tm->tm_mday];
    [self rangeSelectionChanged:nil];
}

inline int daycomp(time_t a,time_t start,time_t end)
{
    if(a<start) return -1;
    if(a>end) return 1;
    return 0;
}

    

- (IBAction)rangeSelectionChanged:sender
{
    int enabled = [timeRangeSwitch intValue];

    NSAssert(slc!=nil,@"SLC must not be nil");

    [[selectionMatrix cellWithTag:ALL_ENTRIES_TAG]
	setTitle:[NSString stringWithFormat:allEntries,[slc numPeople]]];
			 
    [[selectionMatrix cellWithTag:ALL_ENTRIES_DISPLAYED_TAG]
	setTitle:[NSString stringWithFormat:allEntriesDisplayed,[slc numVisiblePeople]]];

    [[selectionMatrix cellWithTag:ALL_ENTRIES_SELECTED_TAG]
	setTitle:[NSString stringWithFormat:allEntriesSelected,[slc numSelectedPeople]]];
			 
    /* Enable or disable selected time range depending on cell value */
    [whichPopup setEnabled:enabled];
    [beforeOnAfterPopup setEnabled:enabled];
    [monthPopup setEnabled:enabled];
    [dateField  setEnabled:enabled];
    [yearPopup  setEnabled:enabled];
    [todayButton setEnabled:enabled];

    /* Now get the list */
    [selected release];
    selected = nil;

    switch([[selectionMatrix selectedCell] tag]){
    case ALL_ENTRIES_TAG:
	selected = [[[slc doc] allPeople] retain];
	break;
    case ALL_ENTRIES_DISPLAYED_TAG:
	selected = [[slc visibleList] retain];
	break;
    case ALL_ENTRIES_SELECTED_TAG:
	selected = [[slc selectedPeopleArray:NO] retain];
	break;
    default:
	NSAssert(0,@"Invalid tag");
    }

    /* If we are considering the date range, remove the entries out of range */
    if(enabled){
	NSEnumerator *en = [selected objectEnumerator];
	Person *obj;
	int cmv_tag = [whichPopup tagOfTitle];
	int boa_tag = [beforeOnAfterPopup tagOfTitle];
	struct tm ta;

	memset(&ta,0,sizeof(ta));
	ta.tm_mon  = [monthPopup tagOfTitle];
	ta.tm_year = atoi([[yearPopup title] cString]) - 1900;
	ta.tm_mday = [dateField intValue];
	
	time_t dayStart = mktime(&ta);
	time_t dayEnd   = dayStart+24*60*60;

	NSMutableArray *newSelected = [[NSMutableArray array] retain];
	    
	while(obj = [en nextObject]){
	    int t=0;
	    switch(cmv_tag){
	    case CREATED_TAG: t=[obj ctime];break;
	    case MODIFIED_TAG: t=[obj mtime];break;
	    case VIEWED_TAG: t=[obj atime];break;
	    }
	    if(daycomp(t,dayStart,dayEnd) == boa_tag){
		[newSelected addObject:obj];
	    }
	}
	[selected release];
	selected = newSelected;
    }

    [numberSelectedField setIntValue:[selected count]];
}

- (void)runAsSheet:(NSWindow *)baseWindow title:(NSString *)aTitle
	       slc:(SLC *)aSLC endTarget:aTarget didEndSelector:(SEL)aSelector
{
    endTarget	= aTarget;
    endSelector = aSelector;
    slc		= aSLC;
    [slc	saveEntry];
    [rangeTitle setStringValue:aTitle];
    [self rangeSelectionChanged:nil];
    [self setToday:nil];

    /* calculate the rangeOfYears for the popup update */
    NSRange yearRange = [[slc doc] rangeOfYears];
    [yearPopup removeAllItems];
    for(unsigned int i=yearRange.location;i<yearRange.location+yearRange.length+1;i++){
	[yearPopup addItemWithTitle:[NSString stringWithFormat:@"%d",i]];
    }



    [self runAsSheet:baseWindow
	  modalDelegate:self
	  didEndSelector:nil
	  contextInfo:nil];
}


- (void)textDidChange:(NSNotification *)notification
{
    [self rangeSelectionChanged:nil];
}

- (void)textDidEndEditing:(NSNotification *)notification
{
    [self rangeSelectionChanged:nil];
}

@end
