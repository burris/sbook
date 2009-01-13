/*
 * sbook_xmlread:
 *
 * Read a SBOOK XML file.
 */

#include "xmlparse.h"
#include "nxatom.h"
#include "libsbook.h"
#include "entry.h"
#include "entrylist.h"
#include <err.h>

/****************************************************************
 *** tre stuff
 ****************************************************************/

template <typename T>
class tre {
public:
    tre(bool debugFlag) {
	memset(next,0,sizeof(next));
	debug = debugFlag;
    };
    void reg(const char *buf,void (*action)(T person,const char *data)){
	reg((const u_char *)buf,action);
    }
    void reg(const u_char *buf,void (*action)(T person,const char *data)){
	class tre *where  = this;

	while(buf[0]){
	    unsigned char b0 = buf[0];
	    if(where->next[b0]==0){
		/* Need to create a new node */
		where->next[b0] = new tre(debug);
	    }
	    /* Now there is a node at buf[0]. Change our vantage point*/
	    where = where->next[b0];
	    buf++;			// go to the next character
	}
	/* At this point, we have walked through buf */
	where->action = action;
    }

    void run(const char *buf,T person,const char *data){
	run((const u_char *)buf,person,data);
    }
    void run(const u_char *buf,T person,const char *data){
	class tre *where = this;
	char *b2 = (char *)buf;
	
	while(buf[0]){
	    unsigned char b0 = buf[0];
	    if(where->next[b0]==0){
		if(debug) printf("%s Not in data structure\n",b2);
		return;
	    }
	    where = where->next[b0];
	    buf++;
	}
	(*where->action)(person,data);
    }
    class tre *next[256];		// where to go next
    bool debug;
    void (*action)(T person,const char *data);	// what to do when you get here
};




/* the data structure used for the reader */

struct SBookXML {
    EntryList	*list;		// list we are building
    Entry	*person;	// person we are reading
    char	*buf;
    int		buflen;
    EntryList::gidmap	*refreshGids;	// all of the GIDs, when we are doing a refresh
    
    int		depth;
    int		list_flags;	// set at end to prevent sorting on each addition
    int		process;	// do we want this element?
    int		level1;
    int		level2;
    int		level3;
    int		personCount;

    EntryList	*refresh;	// are we refreshing another SList ?
};

/* These are the keys for the individual types */

#define isentry(x) (x[0]=='e' && x[1]=='n' && x[2]=='t' && x[3]=='r' && x[4]=='y' && x[5]=='\000')
#define isgid(x) (x[0]=='g' && x[1]=='i' && x[2]=='d' && x[3]=='\000')
#define isentrysn(x) (x[0]=='e' && x[1]=='n' && x[2]=='t' && x[3]=='r' && x[4]=='y' && x[5]=='s' && x[6]=='n' && x[7]=='\000')


#ifdef __APPLE__
#define SIZE_FMT "%ld"
#else
#define SIZE_FMT "%d"
#endif




/****************************************************************
 *** old SBook stuff.
 ****************************************************************/

class tre<EntryList *>tentrylist(false);
class tre<Entry *> tentry(false);					// the reader


static int initialized = 0;


void entrylist_set_frame(EntryList *list,const char *buf)
{
    list->frame = NSRectFromSString(buf);
}

void entrylist_set_divider(EntryList *list,const char *buf)
{
    list->divider = atof(buf);
}

void entrylist_set_flags(EntryList *list,const char *buf)
{
    list->setFlags(atoi(buf));
}

void entrylist_set_searchmode(EntryList *list,const char *buf)
{
    list->searchMode = atoi(buf);
}

void entrylist_set_defaultsortkey(EntryList *list,const char *buf)
{
    list->defaultSortKey = atoi(buf);
}

void entrylist_set_defaultpersonflags(EntryList *list,const char *buf)
{
    list->defaultEntryFlags = atoi(buf);
}

void entrylist_set_defaultusername(EntryList *list,const char *buf)
{
    list->defaultUsername = NXUniqueString(buf);
}

void entrylist_set_template(EntryList *list,const char *buf)
{
    list->asciiTemplate = buf;
}

void entrylist_set_rtftemplate(EntryList *list,const char *buf)
{
    sstring *s = stringForB64SString(buf);
    if(s){
	list->rtfTemplate = *s;
	delete s;
    }
}

/****************************************************************/


void entry_set_text(Entry *person,const char *buf)
{
    sstring b2(buf);
    person->setData(&b2,&person->rtfdString,&person->base64rtfdString,false);
}

void entry_set_rtfd(Entry *person,const char *buf)
{
    sstring b2(buf);
    person->setData(&person->asciiString,0,&b2,false);
}

void entry_set_gid(Entry *person,const char *buf)
{
    person->gid = *buf;
}

void entry_set_entrysn(Entry *person,const char *buf)
{
    person->entrySN = atoi(buf);
}

void entry_set_sk(Entry *person,const char *buf)
{
    person->setSortKey(atoi(buf));
}

void entry_set_ctime(Entry *person,const char *buf)
{
    person->c_time = atoi(buf);
}

void entry_set_atime(Entry *person,const char *buf)
{
    person->a_time = atoi(buf);
}

void entry_set_mtime(Entry *person,const char *buf)
{
    person->m_time = atoi(buf);
}

void entry_set_flags(Entry *person,const char *buf)
{
    person->flags = atoi(buf);
}

void entry_set_cuser(Entry *person,const char *buf)
{
    person->cusername = NXUniqueString(buf);
}

void entry_set_muser(Entry *person,const char *buf)
{
    person->musername = NXUniqueString(buf);
}

void entry_ignore(Entry *person,const char *buf)
{
}



static void initialize_parser()
{
    if(initialized) return;

    //tentrylist.reg("entries",entrylist_set_entries);
    //tentrylist.reg("entrycount",entrylist_set_entrycount);
    tentrylist.reg("frame",entrylist_set_frame);
    tentrylist.reg("divider",entrylist_set_divider);
    tentrylist.reg("flags",entrylist_set_flags);
    tentrylist.reg("searchmode",entrylist_set_searchmode);
    tentrylist.reg("template",entrylist_set_template);
    tentrylist.reg("rtftemplate",entrylist_set_rtftemplate);
    tentrylist.reg("defaultsortkey",entrylist_set_defaultsortkey);
    tentrylist.reg("defaultpersonflags",entrylist_set_defaultpersonflags);
    tentrylist.reg("defaultusername",entrylist_set_defaultusername);
    //tentrylist.reg("searchentrymode",entrylist_set_searchentrymode);
    //tentrylist.reg("entrycount",entrylist_set_entrycount);
    //tentrylist.reg("entry",entrylist_set_entry);
    //tentrylist.reg("filecreationdate",entrylist_set_filecreationdate);


    tentry.reg("text",entry_set_text);
    tentry.reg("t",entry_set_text);
    tentry.reg("rtfd",entry_set_rtfd);
    tentry.reg("gid",entry_set_gid);
    tentry.reg("sk",entry_set_sk);
    tentry.reg("ctime",entry_set_ctime);
    tentry.reg("mtime",entry_set_mtime);
    tentry.reg("atime",entry_set_atime);
    tentry.reg("cuser",entry_set_cuser);
    tentry.reg("muser",entry_set_muser);
    tentry.reg("entrysn",entry_set_entrysn);

    tentry.reg("textmd5",entry_ignore);
    tentry.reg("synctime",entry_ignore);
    tentry.reg("syncsource",entry_ignore);
    tentry.reg("syncuid",entry_ignore);
    initialized=1;
}


static void startDoc(void *userData,const XML_Char *doctypeName)
{
}

static void endDoc(void *userData)
{
}

/* Handle the data between tags */
static void characterDataHandler(void *userData,const XML_Char *s,int len)
{
    struct SBookXML *data = (struct SBookXML *)userData;

    if(data->buf==0 && data->process!=0){
	data->buf = (char *)malloc(len+1);
	memcpy(data->buf,s,len);
	data->buflen = len;
    }
    else {
	data->buf = (char *)realloc(data->buf,data->buflen+len+1);
	memcpy(data->buf+data->buflen,s,len);
	data->buflen += len;
    }

    data->buf[data->buflen] = 0;

}

static void startElement(void *userData, const char *name_, const char **atts)
{
    struct SBookXML *data = (struct SBookXML *)userData;
    EntryList *slist=data->list;

    data->depth ++;
    data->buf   = 0;
    data->process = 1;			// by default, do not ignore the element

    /* Special stuff that needs to be done at the beginning of an element */
    switch(data->depth){
    case 1:				// outermost
	data->level1++;			// count the number of these elements
	data->process   = 1;		// keep all top level elements
	if(!strcmp(name_,"entries")){
	    data->list = new EntryList; // create a new list!
	    data->list->setFlags(0);
	    return;
	}
	return;
    case 2:				// inside <entries>
	data->level2++;

	if(isentry(name_)){
	    sstring gid;		// gid for this person
	    unsigned long entrySN=0;		// sn for this person

	    /* Pick up the attributes */
	    while(*atts){
		if(isgid(atts[0])){
		    gid=atts[1];
		    atts+=2;
		}
		if(isentrysn(atts[0])){
		    entrySN = atoi(atts[1]);
		    atts+=2;
		}
	    }

	    /* If we are refreshing */
	    if(data->refresh){

		/* Get the person who matches who is being refreshed */
		Entry *per = data->refresh->entryWithGid(gid);

		/* Remove from the refreshGids */
		data->refreshGids->erase(gid);

		if(per){		// this person already exists
		    if(per->entrySN==entrySN){
			data->process = 0;	 // don't grab the data
			data->person  = 0; // don't remember the person
			return;
		    }
		    
		    /* Otherwise, turn on reading and set the person we are reading
		     * to be the person from the slist... (forget the text.)
		     */
		    data->process = 1;
		    data->person = per;
		    //data->person->setAsciiData:[NSData data] releaseRtfdData:YES andUpdateMtime:NO];
		    return;
		}
	    }

	    /* If we are not refreshing, or if we are refreshing and this is a newperson,
	     * just create this person and get ready to roll
	     */
	    data->person = new Entry();	 // create a new person!
	    data->person->setGid(gid);
	    data->person->entrySN = entrySN;

	    if(data->refresh){
		data->refresh->addEntry(data->person);
	    }
	    else{
		slist->addEntry(data->person); // add to the list if we are not refreshing
		data->personCount++;
	    }
	    return;
	}
	return;
    case 3:				// inside the <entry>
    default:
	data->level3++;
	if(data->person==0){
	    data->process=0;
	    return;	// we are not remembering the person, so don't remember
	}
	data->process=1;		// get the data
    }
}

static void endElement(void *userData, const char *name_)
{
    struct SBookXML *data = (struct SBookXML *)userData;
    EntryList *slist          = data->list;

    if(data->depth==1 && isentry(name_)){
	/* End of the <entries> */
#if 0
	if(data->refresh){
	    /* If we are refreshing, remove entries that were not referenced */
	    NSEnumerator *en = [data->refreshGids keyEnumerator];
	    id obj;

	    while(obj = [en nextObject]){
		Person *person = [data->refresh personWithGid:obj];
		[person	setFlag:ENTRY_DELETED_FLAG toValue:YES]; // note that it was deleted
		[data->refresh removePerson:person];
	    }
	}
#endif
    }
    if(data->depth==2 && isentry(name_)){
	Entry *person = data->person;
	/* Clean up the entry */

	/* If musername is not set, it is defaultusername */
	if(person->musername==0){
	    person->musername = slist->defaultUsername;
	}

	/* If we have an musername but not a cusername, set the cusername to be the musername */
	if(person->musername!=0 && person->cusername==0){
	    person->cusername = person->musername;
	}

	/* If we do not have a sort key, set to the default */
	if(person->sortKey==0){
	    person->sortKey = slist->defaultSortKey;
	}

	/* If we do not have a flags, set to the default */
	if(person->flags==0){
	    person->flags = slist->defaultEntryFlags;
	}

	/* If we have an atime but not mtime, set the mtime to be the atime */
	if(person->a_time==0 && person->m_time!=0){
	    person->m_time = person->a_time;
	}

	/* If we have an mtime but not ctime, set the ctime to be mtime */
	if(person->m_time==0 && person->c_time!=0){
	    person->c_time = person->m_time;
	}
    }

    if(data->buflen>0){		// if we got data
	switch(data->depth){
	case 2:
	    // if we are refreshing and in SList, ignore options
	    if(data->refresh && data->list) break;

	    // nothing to do for </entry>
	    if(isentry(name_)) break;	

	    tentrylist.run(name_,data->list,data->buf);
	    break;

	case 3:				// within an entry
	    if(data->person == 0) break;	// we are not remembering this person; skip;

	    tentry.run(name_,data->person,data->buf);
	}
    }

    if(data->buf){
	free(data->buf);
	data->buf = 0;
	data->buflen = 0;
    }
    data->depth --;
}

EntryList *EntryList::xmlread(const char *buf,int buflen,
			      EntryList *refresh,void (*errorfunc)(const char *))
{
    XML_Parser parser = XML_ParserCreate(NULL);
    struct SBookXML data;

    initialize_parser();

    /* Set up the parser */
    memset(&data,0,sizeof(data));
    data.refresh = refresh;

#if 0
    /* Special logic for refreshing.
     * If we are refreshing, we want to create an array with all GIDs for the
     * newly-read file.
     */

    if(refresh){			// if we are refreshing, get all the GIDs
	NSArray *array = [refresh allPeopleGids];
	NSEnumerator *en = [array objectEnumerator];
	id obj;

	data.refreshGids = [NSMutableDictionary dictionary];

	while(obj = [en nextObject]){
	    [data.refreshGids setObject:obj forKey:obj]; // list of the GIds
	}
    }
#endif

    XML_SetUserData(parser, &data);
    XML_SetDoctypeDeclHandler(parser, startDoc, endDoc);
    XML_SetElementHandler(parser, startElement, endElement);
    XML_SetCharacterDataHandler(parser,characterDataHandler);

    if (!XML_Parse(parser, buf, buflen, 1)) {
	char buf[2048];
	sprintf(buf,"XML Error: %s at line %d",
		XML_ErrorString(XML_GetErrorCode(parser)),
		XML_GetCurrentLineNumber(parser));
	errorfunc(buf);
	return 0;
    }
    XML_ParserFree(parser);

    /* If we got an SList, set it up and return it */
    if(data.list){
	data.list->setFlags(data.list_flags); // now set the flags; will sort if needed
	return data.list;
    }

    return 0;				// not sure what we got
}


/****************************************************************
 ** Service Routines
 ****************************************************************/

void EntryList::addEntry(Entry *ent)
{
    entries.push_back(ent);
    entriesByGid[ent->gid] = ent;

    /* May need to sort */
}

Entry *EntryList::entryWithGid(const sstring &gid)
{
    return entriesByGid[gid];
}

void EntryList::removeEntry(Entry *ent)
{
    for(EntryIterator it = entries.begin();
	it != entries.end();
	it++){
	if((*it) == ent){
	    entries.erase(it);
	    entriesByGid.erase(ent->gid);
	    return;
	}
    }
}

unsigned EntryList::numEntries()
{
    return entries.size();
}

Entry *EntryList::entryAt(unsigned num)
{
    if(num>=entries.size()){
	err(1,"entryAt(%d) but there are only %d entries\n",num,entries.size());
    }
    return entries[num];
}

EntryVector *EntryList::doSearch(sstring str,int mode)
{
    EntryVector *ret = new EntryVector;		// create what we will be returning
    
    NXAtomList	*mlist = atomsForNames(str.c_str(),false);	// get the mlist
    for(EntryIterator it = entries.begin(); it != entries.end(); it++){
	bool matched = false;
	Entry *e = *it;
	switch(mode){
	default:
	    fprintf(stderr,"invalid search mode '%d'\n",mode);
	    exit(1);
	case SEARCH_WORD_MATCH:
	    matched = sbookIncrementalMatch( e->names,mlist);
	    break;
	case SEARCH_PHONETIC:
	    matched = sbookIncrementalMatch( e->metaphones,mlist);
	    break;
	case SEARCH_FULL_TEXT:
	    //matched = e->hasText(str);
	    break;
	}
	if(matched){
	    ret->push_back(*it);
	}
    }
    delete mlist;
    return ret;
}

void EntryList::xml_make(sstring *xml)
{
    char buf[1024];
    
    (*xml) = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" SBOOK_DTD "\n";
    (*xml) += "<entries>\n";

    if(frame.size.width != 0 && frame.size.height!=0){
	sprintf(buf,"<frame>{{%g, %g}, {%g, %g}}</frame>\n",
		frame.origin.x,frame.origin.y,
		frame.size.width,frame.size.height);
	(*xml) += buf;
    }
    if(divider!=0){
	sprintf(buf,"<divider>%.0f</divider>\n",divider);
	(*xml) += buf;
    }
    sprintf(buf,"<flags>%ld</flags>\n<defaultsortkey>%d</defaultsortkey>\n"
	    "<searchmode>%d</searchmode>\n",
	    flags, defaultSortKey, searchMode);
    (*xml) += buf;

    if(asciiTemplate.size()>0){
	(*xml) += "<template>" + asciiTemplate + "</template>\n";
    }
    if(rtfTemplate.size()>0){
	sstring *tmp64 = b64stringForSString(rtfTemplate);

	(*xml) += "<rtftemplate>" + (*tmp64) + "</rtftemplate>\n";
	delete tmp64;
    }

    sprintf(buf,"<entrycount>" SIZE_FMT " </entrycount>\n",entries.size());
    (*xml) += buf;

    sprintf(buf,"<defaultpersonflags>%d</defaultpersonflags>\n",defaultEntryFlags);
    (*xml) += buf;

    

    for(EntryIterator it = entries.begin(); it != entries.end(); it++){
	(*it)->xml_make(xml,this);
    }
    (*xml) += "</entries>\n";
}

EntryIterator EntryList::begin()
{
    return entries.begin();
}

EntryIterator EntryList::end()
{
    return entries.end();
}
