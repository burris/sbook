#import "ExportFileInfoView.h"
#import "SList.h"
#import "SLC.h"


#import "defines.h"
#import "tools.h"

#import <sys/types.h>
#import <sys/stat.h>
#import <dirent.h>
#import <unistd.h>

/*
 * The ExportInfoView handles exporting for the SLC class.
 */


@implementation ExportFileInfoView

- (void)awakeFromNib
{
    [self setupForFormat];
}

- (void)setSavePanel:(NSSavePanel *)pan
{
    savePanel = pan;
}

- (void)setSLC:(SLC *)s;
{
    slc = s;
}


- (void)setupForFormat
{
    int tag = [self exportFormatTag];
    
    switch(tag){
    case TAG_SBOOK_XML:
	[delimiterPopup    setEnabled:NO];
	[messageCell	setStringValue:@""];
	[savePanel setRequiredFileType:SBOOK_FILE_EXTENSION];
	break;

    case TAG_INFOGENIE:
    case TAG_IDATA:
	[delimiterPopup    setEnabled:NO];
	[messageCell	setStringValue:@""];
	[savePanel setRequiredFileType:@"ig"];
	break;

    case TAG_TAB_DELIMITED:
    case TAG_TAB_DELIMITED_SMART:
	[delimiterPopup    setEnabled:YES];
	[messageCell	setStringValue:@""];
	[savePanel	setRequiredFileType:@""];
	break;

    case TAG_SBOOK_ASCII:
	[delimiterPopup    setEnabled:YES];
	[delimiterPopup setEnabled:TRUE];
	[messageCell	setStringValue:@""];
	[savePanel	setRequiredFileType:@"txt"];
	break;

    default:
	NSRunAlertPanel(@"[ExportInfoView takeExportFormat:]",@"Unknown tag=%d",0,0,0,tag);
	break;
    }
}

- (int)exportFormatTag
{
    return [formatPopup tagOfTitle];
}

- (IBAction)takeExportFormat:(id)sender
{
    [self setupForFormat];
}

- (void)setDefaultFormat
{
    [formatPopup selectItemAtIndex:[formatPopup indexOfItemWithTag:TAG_SBOOK_ASCII]];
    [delimiterPopup selectItemAtIndex:0];
    [self setupForFormat];
}

- (void)setExportArray:(NSArray *)anArray
{
    exportArray = anArray;
}


- (NSDictionary *)exportInfo
{
    NSMutableDictionary *si = [NSMutableDictionary dictionary];
    char	buf[66];
    int tag = [formatPopup tagOfTitle];

    switch(tag){
    case TAG_SBOOK_XML:
	[si setObject:NSNUMBER_SBOOK_XML forKey:FMT_DOC_TYPE_TAG];
	break;
    case TAG_SBOOK_ASCII:
	[si setObject:NSNUMBER_SBOOK_ASCII forKey:FMT_DOC_TYPE_TAG];
	memset(buf,[[delimiterPopup title] characterAtIndex:0],sizeof(buf));
	buf[64] = '\n';
	buf[65] = 0;
	[si setObject:[NSString stringWithUTF8String:buf]
	    forKey:FMT_RECORD_DELIM];
	break;
    case TAG_IDATA:
	[si setObject:NSNUMBER_IDATA forKey:FMT_DOC_TYPE_TAG];
	[si setObject:@"\006" forKey:FMT_RECORD_DELIM];
	[si setObject:@"\r" forKey:FMT_LINE_DELIM];
	break;
    case TAG_INFOGENIE:
	[si setObject:NSNUMBER_INFOGENIE forKey:FMT_DOC_TYPE_TAG];
	[si setObject:@"\006" forKey:FMT_RECORD_DELIM];
	[si setObject:@"\r" forKey:FMT_LINE_DELIM];
	break;
    case TAG_TAB_DELIMITED:
    case TAG_TAB_DELIMITED_SMART:
	[si setObject:[NSNumber numberWithInt:tag] forKey:FMT_DOC_TYPE_TAG];
	[si setObject:@"\t" forKey:FMT_RECORD_DELIM];
	[si setObject:@"\n" forKey:FMT_LINE_DELIM];
	break;
    default:
	NSRunAlertPanel(@"Unknown File Type",
			@"That file type is not recognized",0,0,0);
	break;
    }
    if(exportArray){
	[si setObject:exportArray forKey:EXPORT_ARRAY];
    }
    return si;
}


- (void)exportToPath:(NSString *)path 
{
    NSDictionary *exportInfo =  [self exportInfo];
    int	doc_type_tag = [[exportInfo objectForKey:FMT_DOC_TYPE_TAG] intValue];

    /* Conventional export */
    NSData *out = [[slc doc] txtWriteWithExportInfo:exportInfo];
    if(!out){
	NSRunAlertPanel(@"export",@"Cannot export???",nil,nil,nil);
	return;
    }
    
    if([out writeToFile:path atomically:NO]==NO){
	NSRunAlertPanel(@"export",@"Could not save file???",nil,nil,nil);
	return;
    }
    if(doc_type_tag==TAG_INFOGENIE ||
       doc_type_tag==TAG_IDATA ){
	NSFileManager *dfm = [NSFileManager defaultManager];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	
	
	if(doc_type_tag==TAG_INFOGENIE){
	    [attrs setObject:[NSNumber numberWithInt:1231971911]
		   forKey:NSFileHFSCreatorCode];	// "InfG"
	}
	if(doc_type_tag==TAG_IDATA){
	    [attrs setObject:[NSNumber numberWithInt:0x69444154]
		   forKey:NSFileHFSCreatorCode];	// "iDAT"
	}

	[attrs setObject:[NSNumber numberWithInt:1413830740]
	       forKey:NSFileHFSTypeCode];		// "TEXT"
	
	if([dfm changeFileAttributes:attrs atPath:path]){
	}
	else{
	    NSLog(@"Unable to set infoGenie/iData file type");
	}
    }
}



- (void)savePanelDidEnd:sheet returnCode:(int)returnCode
	    contextInfo:(void *)contextInfo
{    
    if(returnCode){
	[self exportToPath:[sheet filename] ];
    }
}


@end
