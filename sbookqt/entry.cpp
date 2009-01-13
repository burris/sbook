#include <ctype.h>
#include <stdio.h>

#include <malloc.h>
#include "entry.h"
#include "parser.h"

#include <qfile.h>
#include <qstring.h>
#include <qtextstream.h>

QString QString_dashes("----------");

NXAtom ENTRY_TEXT_atom		= NXUniqueString(ENTRY_TEXT);
NXAtom ENTRY_SORTKEY_atom	= NXUniqueString(ENTRY_SORTKEY);
NXAtom ENTRY_SHOULDPARSE_atom	= NXUniqueString(ENTRY_SHOULDPARSE);
NXAtom ENTRY_SN_atom		= NXUniqueString(ENTRY_SN);
NXAtom ENTRY_CTIME_atom		= NXUniqueString(ENTRY_CTIME);
NXAtom ENTRY_MTIME_atom		= NXUniqueString(ENTRY_MTIME);
NXAtom ENTRY_ATIME_atom		= NXUniqueString(ENTRY_ATIME);
NXAtom ENTRY_CALLTIME_atom	= NXUniqueString(ENTRY_CALLTIME);
NXAtom ENTRY_ENVTIME_atom	= NXUniqueString(ENTRY_ENVTIME);
NXAtom ENTRY_EMAILTIME_atom	= NXUniqueString(ENTRY_EMAILTIME);
NXAtom ENTRY_CUSERNAME_atom	= NXUniqueString(ENTRY_CUSERNAME);
NXAtom ENTRY_MUSERNAME_atom	= NXUniqueString(ENTRY_MUSERNAME);


Entry::Entry(const QString &aText)
    :sortKey(SORTKEY_SMART),			  // default is smart sort
    ctime(0),
    mtime(0),
    atime(0),
    shouldParse(true),
    cusername(""),
    musername(""),
    calltime(0),
    envtime(0),
    emailtime(0),
    cachedSortName(0),
    dontParseFlag(0)
{
    mtime = ctime = time(0);
    setText(aText,false);
}

Entry::~Entry()
{
    
}

/* 
 * Compare two entries, being smart about the sortName and whether they are numbers
 * and things like that.
 */
int Entry::compare(Entry *that)
{
    u_int	numAtoms1 = this->numAtoms();
    u_int	numAtoms2 = that->numAtoms();

    if(numAtoms1==0) 	return -1;
    if(numAtoms2==0)	return 1;

    /* See if we can figure it out from the first atoms */

    NXAtom	s1 = this->sortName();
    NXAtom	s2 = that->sortName();
    
    if(isOnlyDigits(s1) && isOnlyDigits(s2)){
	int i1 = atoi(s1);
	int i2 = atoi(s2);

	if(i1<i2) return -1;
	if(i1>i2) return 1;
    }
    else{
	int comp = strcmp(s1,s2);
	if(comp!=0) return comp;
    }

    /* Now go through each of the words in the word lists and compare them.
     * This used to skip over the sort key, but I'm not sure that is the right
     * thing to do anymore, so it doesn't do it. 
     */
    for(u_int i=0;i<numAtoms1 && i<numAtoms2;i++){
	int comp = compareAtoms(this->atom(i),that->atom(i));
	if(comp!=0) return comp;
    }
    return 0;
}



bool Entry::operator<(Entry *e2)
{
    return compare(e2) < 0;
}

bool Entry::operator==(Entry &e2)
{
    return compare(&e2)==0;
}


bool Entry::setPropertyValue(NXAtom property,const char *v)
{
    if(property==ENTRY_TEXT_atom)	{setText(v,true);return TRUE;}
    if(property==ENTRY_SN_atom)		return xset(SN,v);
    if(property==ENTRY_SORTKEY_atom)	return xset(sortKey,v);
    if(property==ENTRY_SHOULDPARSE_atom)return xset(shouldParse,v);
    if(property==ENTRY_CTIME_atom)	return xset(ctime,v);
    if(property==ENTRY_MTIME_atom)	return xset(mtime,v);
    if(property==ENTRY_ATIME_atom)	return xset(atime,v);
    if(property==ENTRY_CALLTIME_atom)	return xset(calltime,v);
    if(property==ENTRY_ENVTIME_atom)	return xset(envtime,v);
    if(property==ENTRY_EMAILTIME_atom)	return xset(emailtime,v);
    if(property==ENTRY_CUSERNAME_atom)	return xset(cusername,v);
    if(property==ENTRY_MUSERNAME_atom)	return xset(musername,v);

    fprintf(stderr,"Unknown entry property: '%s'\n",property);
    return TRUE;				  // unknown tags are non-fatal
}

/* setText:
 * Sets the entire text of the entry.
 */
void Entry::setText(const QString &aText,bool loading)
{
    theText = aText;
    if(!loading) mtime   = time(0);				  
    setLine1(theText.left(theText.find('\n')));
}

/* setLine1:
 * sets just the first line of the entry.
 */
void Entry::setLine1(const QString &str)
{
    if(theLine1.compare(str)==0) return;	  // no change

    theLine1= str;				  // 
    cachedSortName = 0;				  // delete the cached name
    atoms = atomsForNames(str);			  // atomize the name

    /* Figure out if the entry is blank or not */
    line1IsBlank = true;
    unsigned int i;
    for(i=0;i<theLine1.length();i++){
	if(theLine1.at(i).isSpace()==false){
	    line1IsBlank = false;
	    break;
	}
    }
}

/* Returns everything but line 1 */
QString Entry::line2n()
{
    int pos = theText.find('\n');

    if(pos==-1) theText.mid(0,0);		  // empty string
    return theText.mid(pos+1,theText.length());
}

void Entry::Export(FILE *f,int format)
{
    const char *buf = theText.latin1();

    palmquotes = false;				  // default
    switch(format){
    case FORMAT_SBOOK_ASCII:
	fputs(buf,f);
	if(theText.right(1).compare("\n")!=0){	  // terminate with \n
	    fputc('\n',f);
	}
	fputs("================\n",f);
	break;
    case FORMAT_IG:
	const char *cc;
	for(cc=buf;*cc;cc++){
	    switch(*cc){
	    case '\n':
		fputc('\r',f);
		break;
	    default:
		fputc(*cc,f);
		break;
	    }
	}
	fputc((char)0x06,f);
	return;
    case FORMAT_PALM_CSV:
	palmquotes = true;
	ExportPalmCSV(f);
	break;
    case FORMAT_CSV:
	ExportDelimited(f,',');
	break;
    case FORMAT_TAB:
	ExportDelimited(f,'"');
	break;
    }
}


/* Lame attempt at an exporter */

void Entry::ExportString(FILE *f,const char *str,int delim)
{
    const char *cc;

    fputc('\"',f);
    for(cc=str;cc && *cc;cc++){
	switch(*cc){
	case '"':
	    if(palmquotes){
		fputs("\"\"",f);
	    }
	    else {
		fputs("\\\"",f);
	    }
	    break;
	case '\\':
	    fputs("\\\\",f);
	    continue;
	default:
	    fputc(*cc,f);
	}
    }
    fputc('\"',f);
}

void Entry::ExportString(FILE *f,const QString &str,int delim)
{
    ExportString(f,str.latin1(),delim);
}

void Entry::ExportStringD(FILE *f,const QString &str,int delim)
{
    ExportString(f,str.latin1(),delim);
    fputc(delim,f);
}

void Entry::ExportDelimited(FILE *f,int delim)
{
    int len = theText.length();

    /* First send through the name in two fields
     * --- this should probably deal with company properly
     */
    if(firstLineHasSpace()){
	/* No space */
	ExportStringD(f,firstName(),delim);
	ExportStringD(f,restName(),delim);
    }
    else{
	/* space */
	ExportStringD(f,theLine1,delim);
	ExportStringD(f,"",delim);
    }

    /* Now send all of the rest as 'notes' */
    ExportString(f,theText.mid(theLine1.length()+1,len),delim);
    fputs("\n",f);
}


QString Entry::restLines()
{
    return theText.mid(theLine1.length()+1);
}

/* Palm format:
 * last name, first name, title, company,
 * work, home, fax, other, email, address,
 * city, state, zip, country, custom1, custom2,
 * custom3, custom 4, note, private, category
 */

void Entry::ExportPalmCSV(FILE *f)
{
    int delim = ',';
    QString fn;
    QString ln;
    QString company;

    if(isCompany()==false){
	fn = firstName();
	ln  = restName();
    }
    else{
	company = theLine1;
    }

    ExportStringD(f,ln,delim);			  // last name
    ExportStringD(f,fn,delim);			  // first name
    ExportStringD(f,"",delim);			  // title
    ExportStringD(f,company,delim);		  // company
    ExportStringD(f,telephoneN(0),delim);	  // work
    ExportStringD(f,"",delim);			  // home
    ExportStringD(f,"",delim);			  // fax
    ExportStringD(f,"",delim);			  // other
    ExportStringD(f,emailN(0),delim);		  // email
    ExportStringD(f,"",delim);			  // address
    ExportStringD(f,"",delim);			  // city
    ExportStringD(f,"",delim);			  // state
    ExportStringD(f,"",delim);			  // zip
    ExportStringD(f,"",delim);			  // country
    ExportStringD(f,"",delim);			  // custom1
    ExportStringD(f,"",delim);			  // custom2
    ExportStringD(f,"",delim);			  // custom3
    ExportStringD(f,"",delim);			  // custom4
    ExportStringD(f,restLines(),delim);		  // note
    ExportStringD(f,"",delim);			  // private
    ExportString(f,"",delim);			  // category
    fputs("\n",f);
}


bool	Entry::firstLineHasSpace()
{
    int space = theLine1.findRev(' ');
    return space>0 ? true : false;
}

QString Entry::firstName()
{
    int space = theLine1.findRev(' ');

    if(space!=-1){
	return theLine1.left(space);
    }
    return theLine1;
}

QString Entry::restName()
{
    int space = theLine1.findRev(' ');

    if(space!=-1){
	return theLine1.mid(space+1);
    }
    return "";
}

bool Entry::isCompany()
{
    return parse_company(theLine1.latin1());
}

bool Entry::match(const QString &str,bool fulltext)
{
    if(fulltext) return theText.contains(str,0); // full-text search is easy

    NXAtomList	    *mlist= atomsForNames(str);   // match list
    bool *matchable	 = (bool *)alloca(sizeof(bool *)*(atoms->count()));
    
    /* see if there is a match for each word in names
     * The way this algorithm works: We search through for each atom
     * in the search list to see if it is match for the first N characters
     * of any of the atoms in the ncopy list. If it isn't, we return NO, becuase
     * we didn't match. If it is, then we remove that name from the ncopy list
     * and we try again...
     */

    u_int i;
    for(i=0;i<atoms->count();i++){
	matchable[i] = true;
    }

    for ( i = 0; i < mlist->count(); ++i ) {
	NXAtom  I = (*mlist)[i];
	bool	matched	    = false;
	int	search_len  = strlen(I);

	for( unsigned int j = 0; j < atoms->count() && matched==false; j++){
	    if(matchable[j]){
		NXAtom J = (*atoms)[j];
		int k;

		for(k=0;k<search_len;k++){
		    if(I[k] != J[k]) break;	// doesn't match
		}
		if(k==search_len){		  // if we got to the end
		    matched=true;		  // it matched
		    matchable[j] = 0;		  // don't match this name again
		    break;
		}
	    }
	}
	if(matched==false){
	  delete mlist;
	  return false;
	}
    }
    delete mlist;
    return true;				  // each one must have matched.
}

/*
 * sortName:
 * Return the sortName, possibly calculating the smartSort name
 */

NXAtom Entry::sortName()
{
    if(cachedSortName==0){
	/* Make sure there is data */
	if(atoms->count()==0){			  
	    return atom_blank;
	}

	if(sortKey==SORTKEY_SMART){		  // check for SmartSort
	    cachedSortName = smartSortName(theLine1.latin1(),*atoms);
	}
	else{					  // name is an offset
	    int retName =0;
	    if(sortKey==0) retName = 0;
	    if(sortKey>0)  retName = sortKey;
	    if(sortKey<0)  retName = atoms->count() + sortKey;
	    
	    /* Make sure it is valid */
	    
	    if(retName < 0)	retName = 0;
	    if((unsigned)retName >= atoms->count())	retName = atoms->count()-1;
	    cachedSortName = (*atoms)[retName];
	}
    }
    return cachedSortName;
}

int Entry::lines()
{
    int i;
    int len = theText.length();
    int l=1;

    for(i=0;i<len;i++){
	if(theText.at(i)=='\n'){
	    l++;
	}
    }
    return l;
}

QString Entry::getLine(int line)
{
    int len = theText.length();
    int p1=0;

    while(line>0 && p1<len){
	if(theText.at(p1)=='\n'){
	    line--;
	}
	p1++;
    }
    if(p1>=len) return "";

    int p2;

    for(p2=p1+1;p2<len;p2++){
	if(theText.at(p2)=='\n'){
	    break;
	}
    }

    return theText.mid(p1,p2-p1);
}

/****************************************************************
 * PARSER-RELATED FUNCTIONS
 * RIGHT NOW: HACK. DO WE NEED TO CREATE A SEPERATE
 * PARSER FOR EACH ENTRY?
 ****************************************************************/

QString Entry::addressN(unsigned n)
{
    theParser->setEntryAndParse(this);
    return theParser->addressN(n);
}

QString Entry::emailN(unsigned n)
{
    theParser->setEntryAndParse(this);
    return theParser->emailN(n);
}

QString Entry::telephoneN(unsigned n)
{
    theParser->setEntryAndParse(this);
    return theParser->telephoneN(n);
}






