/*
 * Entries:
 * The list of entries
 */

#ifndef SBOOK_ENTRIES
#define SBOOK_ENTRIES

#include <qrect.h>
#include <qstring.h>
#include <qlist.h>
#include <qsortedlist.h>
#include <qfont.h>
#include <qprogressbar.h>

#include "entry.h"

/* Define the property names */
#define ENTRIES_ENTRYCOUNT	"entrycount"
#define ENTRIES_FRAME		"frame"
#define ENTRIES_DIVIDER		"divider"
#define ENTRIES_SORTFLAG	"sortflag"
#define ENTRIES_PARSEFLAG	"parseflag"
#define ENTRIES_SEARCHMODE	"searchmode"
#define ENTRIES_TEMPLATE	"template"
#define ENTRIES_DEFAULTSORTKEY	"defaultsortkey"
#define ENTRIES_FILECREATIONDATE "filecreationdate"
#define ENTRIES_LISTFONT	"listfont"
#define ENTRIES_ENTRYFONT	"entryfont"
#define ENTRIES_NEXTSN		"nextsn"


class EntryList:public QList<Entry>
{
protected:
    virtual int compareItems(QCollection::Item c1,QCollection::Item c2);
};


class Entries : DataStorageObject
{
    DATASTORAGE;
public:
    Entries();					  // constructor

    /* GUI preferences that are stored in the file */
    QRect   frame;		/* where the window was displayed last */
    int     divider;		/* where the divider was */
    int	    searchMode;		/* default search mode */
    QString template_;		/* template for new entries */
    QFont   listFont;
    QFont   entryFont;
    time_t  file_mtime;				  // mtime of the file (for synchronization)

    bool    loading;				  // true if loading (inhibits sort)

    /* Data that is stored in the file */
    time_t  fileCreationDate;
    int	    defaultSortKey;			  /* default sort order */
    bool    sortFlag;				  /* don't sort the items in the database */
    bool    parseFlag;				  /* don't parse the database */
    bool    syncCopy;				  
    QString syncFile;				  /* If we are a sync copy, then from this file */
    EntryList list;				  /* entries in the book */
    NXAtom filename;				  // filename that was loaded
    int     nextSN;				  // next SN to use

    /* Functions used to manipulate the entry list */
    void    Empty();
    void    add(Entry *);
    void    remove(Entry *);			  // deletes
    int	    count() { return list.count();}
    void    sortEntries();
    void    setSortFlag(bool newFlag);
    void    setDefaultSortKey(int sortOrder);
    void    setLoading(bool flag);
    int     getNextSN() { return ++nextSN;}

    /* Load from a file */
    int	loadFile(const char *fname,class SBookWidget *frame,
		 QProgressBar *bar);// loads from file, returns 0 if successful
    void checkForReload();			  // check to see if file was modified.
						  // reload if it was

    /* Import and export functions return TRUE if successful */
    int Export(const char *file,int format);	  // 0 if successful, -1 if failure

    int ImportSBookASCII(const QString &fn); 
    int ImportDelimited(const QString &fn,int delim);
    int ImportIG(const QString &fn);
};


#endif
