/*
 * Entry object:
 * Each address entry.
 * line1 is the first line (the name)
 * text is all of the entry
 */



#ifndef BOOK_Entry_H
#define BOOK_Entry_H

#include "sbook.h"
#include "../libsbook/libsbook.h"
#include "parser.h"

#include <time.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtextstream.h>

#include "datastorageobject.h"


#define TAB_DELIM 1
#define CSV_DELIM 2

#define SORTKEY_SMART	  1001



/* Define the property names */
#define ENTRY_TEXT	"t"
#define ENTRY_SORTKEY	"sk"
#define ENTRY_SHOULDPARSE "spf"
#define ENTRY_SN	"sn"
#define ENTRY_CTIME	"ctime"
#define ENTRY_MTIME	"mtime"
#define ENTRY_ATIME	"atime"
#define ENTRY_CALLTIME	"cltime"
#define ENTRY_ENVTIME   "entime"
#define ENTRY_EMAILTIME "emtime"
#define ENTRY_CUSERNAME "cuser"
#define ENTRY_MUSERNAME "muser"


extern QString QString_dashes;

class Entry : DataStorageObject
{
    friend class XML;

    DATASTORAGE;
public:
    /* Functions for the entry */
    Entry(const QString &text);
    ~Entry();
    void    setText(const QString &str,bool loading=false);
    bool    match(const QString &str,bool fulltext);
    inline  const QString &text(void);
    QString line2n(void);
    void    Export(FILE *f,int format);
    int	    compare(Entry *);
    bool    operator<(Entry *);
    bool    operator==(Entry &);
    int     lines();

    void    ExportString(FILE *f,const char *str,int delim);
    void    ExportString(FILE *f,const QString &str,int delim);
    void    ExportStringD(FILE *f,const QString &str,int delim); // string and delim
    void    ExportDelimited(FILE *f,int delim);	  // 
    void    ExportPalmCSV(FILE *f);	  // 

public:
    /* Data that is archived each entry */

    time_t  ctime;		/* when created */
    time_t  mtime;		/* when last modified */
    time_t  atime;		/* when last accessed */

    /* serial number for this entry */
    /* combine with ctime to get a unique 64bit val*/
    int	    SN;			

    NXAtom cusername;	/* person who created entry */
    NXAtom musername;	/* last person who modified entry */

    time_t calltime;		/* time last called */
    time_t envtime;		/* time last envelope was sent */
    time_t emailtime;		/* time last email sent */


    /* Data that is derrived for each entry */
    NXAtomList *atoms;				  // atoms for each name in first line 
    NXAtomList *metaphones;			  // atoms for metaphones for each name 

    /* Parse info */
    bool    shouldParse;	/* should I parse this entry */
    int	    dontParseFlag;

    // Stuff for handling names and sorting 
    // sortKey is +1 for first, +2 for second, -1 for last,
    // -2 for second to last, and SORTKEY_SMART for smart sort
    const   QString *line1(void);		  // 
    const   QString *line1Display(void);	  // first line as it is displayed
    bool    firstLineHasSpace();
    QString firstName();			  // first name of line 1
    QString restName();				  // rest of line 1
    bool    isCompany();			  // are we a company?
    QString getLine(int line);			  // get line. line==0 for first line
    NXAtom  atom(unsigned int n);		  // returns the nth atom from line1
    u_int   numAtoms();

    void    setSortKey(int aKey);
    int	    sortKey;				  // with the offset

    NXAtom  sortName();				  // name to use for sort key
    NXAtom  cachedSortName;			  // 0 if there is no cached name

    /* Some things for parsing */
    QString	addressN(unsigned n);
    QString	emailN(unsigned n);
    QString	telephoneN(unsigned n);



private:
    QString theText;				  // the entire text
    QString theLine1;				  // a copy of line1
    QString restLines();			  // lines other than line1
    bool    line1IsBlank;			  // true if the first line is only whitespace
    void    setLine1(const QString &str);
    bool    palmquotes;				  // for exporting
};

#define FORMAT_XML 0
#define FORMAT_SBOOK_ASCII 1
#define FORMAT_PALM_CSV 2
#define FORMAT_CSV 3
#define FORMAT_TAB 4
#define FORMAT_IG 5

#define DONT_PARSE_AFTER_BLANK 0x0001


inline const QString & Entry::text(void)
{
    atime = time(0);
    return theText;
}

inline void Entry::setSortKey(int aKey)
{
    sortKey = aKey;
}

inline const QString *Entry::line1()
{
    return &theLine1;
}

inline const QString *Entry::line1Display()
{
    return line1IsBlank ? &QString_dashes : &theLine1;
}

inline u_int Entry::numAtoms()
{
    return atoms->count();
}

inline NXAtom Entry::atom(unsigned int i)
{
    return (*atoms)[i];
}



#endif
