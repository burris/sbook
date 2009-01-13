#ifndef SBOOK_H

#pragma warning( disable: 4530 )



#ifndef u_int
#define u_int unsigned int
#endif

#define DEFAULT_ALLOW_MULTIPLE_SELECTIONS	"AllowMultipleSelections"
#define DEFAULT_AUTOSAVE			"AutosaveModifiedFile"
#define DEFAULT_AUTOLOAD_LAST_SAVED_FILE	"AutoloadLastSavedFile"
#define DEFAULT_LAST_SAVED_FILE			"LastSavedFile"


#define APP_NAME	"SBook"
#define APP_VERSION     "0.21"
#define DOC_TYPE	".sbook"
#define SEARCH_NAME	"Name"
#define SEARCH_FULLTEXT "Full Text"
#define SEARCH_SOUNDEX	"Soundex"		  // sounds like?
#define SEARCH_AUTO	"Auto"			  // First line, if that fails, do full text

/* Default position for new sbooks */
#define DEFAULT_X 100
#define DEFAULT_Y 100
#define DEFAULT_W 300
#define DEFAULT_H 400


#endif
