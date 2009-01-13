#ifndef ENTRYLIST_H
#define ENTRYLIST_H

#include <string>
#include <map>
#include <vector>
#include <list>


#include "fakecocoa.h"

/*
 * EntryList.h:
 * The precise information that is saved in the SBookXML file.
 */

#include "flagobject.h"

#define SBOOK_DTD "<!DOCTYPE entries PUBLIC \"-//Simson L. Garfinkel// DTD SBook5 //EN//XML\" \"http://www.simson.net/sbook/1.0/sbook.dtd\">"

class Entry;
class EntryList : public FlagObject {
public:

    static EntryList *EntryList::xmlread(const char *buf,int buflen,
					 EntryList *refresh,void (*errorfunc)(const char *));
    /* EntryList is the main SBookXML reader.
     * If refresh is null, it will read attempt to decode the buffer.
     * If refresh is not null, it will refresh an existing XML document from the SList.
     */

    /* Types */
    typedef std::map<sstring,Entry *>	gidmap ;
    typedef std::map<sstring,sstring>	proplist ;

    /* Accessors and functionality */
    Entry	*entryWithGid(const sstring &gid); 
    void	addEntry(Entry *ent);
    void	removeEntry(Entry *ent);
    unsigned int numEntries();
    Entry	*entryAt(unsigned num);
    EntryIterator begin();;
    EntryIterator end();
    EntryVector   *doSearch(sstring str,int mode); // result must be deleted

    /* Instance variables */
    NSRect	frame;
    float	divider;		/* divider height */
    int		searchMode;	
    int		defaultSortKey;
    unsigned int defaultEntryFlags;

    NXAtom	defaultUsername;	// of saved XML file
    sstring	asciiTemplate;
    sstring	rtfTemplate;		

    proplist	addressBookInfo;      // settings for the address book
    proplist	labelsInfol;		// settings for the labels
    int		lastSuccessfulSearchMode; // last mode that we did a search in

    /* Appends my XML Creates an XML representation; you must free it */
    void	xml_make(sstring *str);

private:
    long	flags;			
    
    /* Internal Implementation */

    EntryVector	entries; // points to all current entries
    gidmap	entriesByGid; // points to all current entries by GID



};

#endif
