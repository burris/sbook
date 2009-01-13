/*
 * Entry object:
 * Each address entry.
 * line1 is the first line (the name)
 * text is all of the entry
 */



#ifndef BOOK_Entry_H
#define BOOK_Entry_H

#include "flagobject.h"
#include "nxatom.h"
#include <time.h>
#include <iostream>

class Entry  : public FlagObject
{
public:
    /* Functions for the entry */
    Entry();
    ~Entry();

    void setData(const sstring *ascii,
		 const sstring *rtfd,
		 const sstring *base64rtfd,bool updateMTime);// ASCII must always be provided

    sstring	gid;
    unsigned long entrySN;

    int		sortKey;	/* word to start sorting at; may be -1 for last word */
    time_t	c_time;		/* when created */
    time_t	m_time;		/* when last modified */
    time_t	a_time;		/* when last accessed */
    time_t	calltime;	/* last called */
    time_t	envtime;	/* last envelope time */
    time_t	emailtime;	/* last envelope time */

    NXAtom	cusername;	/* person who created entry */
    NXAtom	musername;	/* last person to modify entry */
    
    /* The data. You may have either or both.
     * Set rtfdString to be "" if not present. This takes advantage of the
     * fact that an rtfdencoding can never be 0-length
     */
    sstring	asciiString;	/* Alternatively the ASCII string; must always be present */
    sstring	rtfdString;	/* RTFD data to be displayed */
    sstring	base64rtfdString;/* Base64-encoded RTFD; superseeds rtfdData if present */

    /* Derrived Information */
    NXAtomList	*names;		/* each name in first line */
    NXAtomList	*metaphones;	/* metaphones; one for each name */
    NXAtom	sortName;	/* just computing */
    NXAtom	theSmartSortName;
    int		isPerson;
    bool	parsed;
    struct TextParagraphs *tp;		// paragraphs that were found
    int		*results;
    int		entryFlags;


    /* accessors */
    void setGid(const sstring &g) {gid = g;}
    void setSortKey(int aKey);

    sstring cellName(bool lastNameFirstFlag);			//
    sstring cellName() {return cellName(false);}
    bool	hasText(const sstring &str); // do we have the text?

    /* Creates a new XML object; you must free it */
    void xml_make(sstring *str,class EntryList *el=0); // if you provide an entryList, defaults will be honored

private:
    sstring	cellName_;	/* first line as displayed in matrix */
    static bool hasCommaBeforeSpace(const sstring &str);
    void	setCellName(const sstring &str);
    sstring	cellNameLF_;	// cellName, last name first


};
typedef std::vector<Entry *> EntryVector;
typedef EntryVector::iterator EntryIterator;

/* I/O stream */
/* << outputs the text of the entry */
std::ostream & operator<< (std::ostream &os,const Entry &ent);

#endif
