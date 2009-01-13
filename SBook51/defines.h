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

/* defines.h
 *
 * defaults for sbook...
 */

#define SBOOK_FILE_EXTENSION		@"sbok"
#define VCARD_FILE_EXTENSION		@"vcf"

#define SBOOK_BUILD_URL			@"http://www.sbook5.com/build.txt"

/* Colors */
#define NS_DKGRAY [NSColor darkGrayColor]
#define NS_WHITE  [NSColor whiteColor]
#define NS_LTGRAY [NSColor lightGrayColor]
#define NS_BLACK  [NSColor blackColor]

/* Pasteboard and File Types */
#define	TYPE_SBOOK_ARRAY		@"SBookArray"// NSArray of People elements
#define TYPE_SBOOK_XML			@"SBook XML"
#define TYPE_SBOOK_ASCII		@"SBook ASCII"
#define TYPE_INFOGENIE			@"InfoGenie"
#define TYPE_IDATA			@"iData"

/* import/export types */
#define TAG_UNKNOWN		-1
#define TAG_SBOOK_XML		1
#define	TAG_SBOOK_ASCII		2
#define TAG_INFOGENIE		3
#define TAG_TAB_DELIMITED	4
#define TAG_CSV_DELIMITED	5	// import only
#define TAG_BLANK_LINE_DELIMITED	6 // import only
#define TAG_TAB_DELIMITED_SMART	7 // export only
#define TAG_RTF			8 // import only
#define TAG_VCARD		9
#define TAG_IPOD		10
#define TAG_IDATA		11

#define NSNUMBER_SBOOK_XML	[NSNumber numberWithInt:TAG_SBOOK_XML]
#define NSNUMBER_SBOOK_ASCII	[NSNumber numberWithInt:TAG_SBOOK_ASCII]
#define NSNUMBER_INFOGENIE	[NSNumber numberWithInt:TAG_INFOGENIE]
#define NSNUMBER_IDATA		[NSNumber numberWithInt:TAG_IDATA]
#define NSNUMBER_TAB_DELIMITED	[NSNumber numberWithInt:TAG_TAB_DELIMITED]



/* Format for importing and exporting information */
#define FMT_RECORD_DELIM	@"RecordDelim"		// characters in record delimiters
#define FMT_LINE_DELIM		@"LineDelim"
#define FMT_DOC_TYPE_TAG	@"DocTypeTag"
#define FMT_IGNORE_FIRST_LINE	@"IgnoreFirstLine"
#define FMT_SWAP_NAMES		@"SwapNames"
#define EXPORT_ARRAY		@"ExportArray"	// list of objects to export


/* Defaults for files and entries */

#define DEF_OPEN_ON_LAUNCH		@"OpenOnLaunch"
#define DEF_FILES_IN_SPECIAL_MENU	@"FilesInSpecialMenu"
#define DEF_MAX_ENTRIES_DISPLAYED	@"MaxEntriesDisplayed"
#define DEF_CHECK_ON_LAUNCH		@"CheckForNewVersionOnLaunch"
#define DEF_SHOW_INTRO_TEXT		@"ShowIntroText"
#define DEF_AUTOSAVE_ENABLE		@"AutosaveEnable"
#define DEF_AUTOCHECK_ENABLE		@"AutocheckEnable"
#define DEF_AUTOSAVE_INTERVAL		@"AutosaveInterval"
#define DEF_AUTOCHECK_INTERVAL		@"AutocheckInterval"

#define DEF_REMOVE_COLOR_FROM_PASTED_TEXT @"RemoveColorFromPastedText"
#define DEF_AUTO_CREATE_ON_BLANK_CLICK	@"AutoCreateOnBlankClick"
#define DEF_OPEN_ON_ACTIVATE		@"OpenOnActivate"


/* View */
#define DEF_HIGHLIGHT_SEARCH_RESULTS    @"HighlightSearchResults"
#define DEF_SPLITVIEW_LOCATION		@"%@ SplitView_Location"

#define DEF_SHOW_HORIZONTAL_SCROLLER	@"ShowHorizontalScroller"

#define PRINT_ENVELOPE_TAG		1
#define PRINT_LABEL_TAG			2

extern NSString *VisibleRectChanged;

/* these accessor methods automatically load nibs */
#if 0
#define	DRAG_ICONS_AS_TEXT	"DragIconsAsText"

#define	MODEM_PORT		"ModemPort"
#define MODEM_BAUD		"ModemBaudRate"
#define MODEM_DIALSTRING	"ModemDialString"
#define MODEM_LOCK		"ModemLock"

#define	TONE_GAPTIME		"ToneGapTime"
#define	TONE_TONETIME		"ToneToneTime"
#define TONE_VOLUME		"ToneVolume"
#define TONE_DIALING		"ToneDialing" /* 1 or 0 */

#define	ENVELOPE_DEFAULT	"EnvelopeDefaultText"
#define	ENVELOPE_FONT_1		"EnvelopeFont1"
#define	ENVELOPE_FONT_2		"EnvelopeFont2"
#define	ENVELOPE_STATIONARY	"EnvelopeStationary"
#define	ENVELOPE_STATIONARY_BASE "EnvelopeStationaryBase"
#define ENVELOPE_ALLCAPS	"EnvelopeAllCaps"

#define	LOG_CALLS_TO_EMAIL	"LogCallsToEmail"
#define	LOG_ENVELOPES_TO_EMAIL	"LogEnvelopesToEmail"
#define LOG_ALL_CALLS		"LogAllCalls"
#define LOG_ALL_ENVELOPES	"LogAllEnvelopes"
#define LOG_CALLS_FILE		"LogCallsFile"
#define LOG_CALLS_TO_FILE	"LogCallsToFile"
#define LOG_ENVELOPES_FILE	"LogEnvelopesFile"
#define LOG_ENVELOPES_TO_FILE	"LogEnvelopesToFILE"

#define EMAIL_FORMAT		"EmailFormat"

#define HINTS			"Hints"

#define KEEP_BACKUPS		"KeepBackupFile"
#define SEARCH_INCREMENTAL	"SearchIncremental" /* not used */
#define	DONT_PARSE_FLAG		"DontParseFlag"
#define AUTOSORT		"Autosort"
#define GAUDY_WINDOWS		"GaudyWindows"



#endif
