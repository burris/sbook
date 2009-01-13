#include <ctype.h>
#include <stdio.h>

#include "libsbook.h"
#include "base64.h"

#define TIMET_FMT "%d"

#ifdef __APPLE__
#undef TIMET_FMT
#define TIMET_FMT "%ld"
#endif


Entry::Entry()
    :sortKey(ENTRY_SMART_SORT_TAG),			  // default is smart sort
     c_time(0),
     m_time(0),
     a_time(0),
     calltime(0),
     envtime(0),
     cusername(""),
     musername(""),
     names(0),
     metaphones(0),
     sortName(0),
     theSmartSortName(0),
     isPerson(0),
     parsed(false),
     tp(0),
     results(0)
{
}

Entry::~Entry()
{
    if(names) delete names;
}

bool Entry::hasCommaBeforeSpace(const sstring &str)
{
    bool foundComma=0;
    for(unsigned int i=0;i<str.size();i++){
	switch(str.at(i)){
	case ' ':
	    if(foundComma) return 1;
	    return false;
	case ',':
	    foundComma = 1;
	}
    }
    return 0;
}

void Entry::setCellName(const sstring &str)
{
    cellName_   = str;
    if(names) delete names;
    names = atomsForNames(cellName_.c_str(),false);

    theSmartSortName = smartSortName(cellName_.c_str(),entryFlags,*names,&isPerson);
    cellNameLF_ = cellName_;

    if(isPerson && names->count()>1 && hasCommaBeforeSpace(str)==false){
	int i;
	for(i=cellName_.size()-1;i>=0;i--){
	    if(isspace(cellName_.at(i))){
		cellNameLF_ = cellName_.substr(i+1) + ", " + cellName_.substr(0,i);
	    }
	}
    }
}

// ASCII must always be provided
void Entry::setData(const sstring *ascii,
		    const sstring *rtfd,
		    const sstring *base64rtfd,bool updateMTime) 
{
    bool setAscii=false;

    if(ascii){
	if(&asciiString != ascii){
	    asciiString = *ascii;
	    setAscii=true;
	}
    }
    else{
	asciiString = "";
	setAscii = false;
    }

    if(rtfd){
	if(&rtfdString != rtfd){
	    rtfdString = *rtfd;
	}
    }
    else{
	rtfdString = "";
    }

    if(base64rtfd){
	if(&base64rtfdString != base64rtfd){
	    base64rtfdString = *base64rtfd;
	}
	rtfdString = "";		// because base64 has been set
    }

    if(updateMTime) m_time = time(0);

    if(setAscii){
	/* Now set the cell name */
	unsigned int pos = asciiString.find('\n');	// what? No \n?
	if(pos==std::string::npos){
	    asciiString.append("\n");	// append the \n
	    pos = asciiString.find('\n');
	}
	
	/* Now get the cellname */
	setCellName(asciiString.substr(0,pos));


	/* Now set the names and metaphones */
	names = atomsForNames(cellName_.c_str(),false);
	metaphones = metaphonesForNames(cellName_.c_str());
    }
}

void Entry::setSortKey(int key)
{
    sortKey = key;
}

sstring Entry::cellName(bool lastNameFirstFlag)
{
    return lastNameFirstFlag ? cellNameLF_ : cellName_;
}



void Entry::xml_make(sstring *xml,class EntryList *el)
{
    char entrysn[16];
    sprintf(entrysn,"%ld",entrySN);

    (*xml) += "<entry gid=\"" + gid + "\" entrysn=\"" + entrysn + "\">\n";

    /* Get out the text. If there are any special characters, we need to do special things */
    (*xml) += "<text>";
    for(unsigned int i=0;i<asciiString.size();i++){
	unsigned char ch = asciiString[i];
	switch(ch){
	case '&':
	    (*xml).append("&amp;");
	    break;
	case '<':
	    (*xml).append("&lt;");
	    break;
	case '>':
	    (*xml).append("&gt;");
	    break;
	case '\n':
	    (*xml).append("\n");
	    break;
	default:
	    if(ch<32) break;		// don't put it in
	    char s2[2] = {ch,0};
	    (*xml).append(s2);	// just take the data
	    break;
	}
    }
    (*xml) += "</text>\n";
    

    /* Don't put out the RTFD if the template needs to be applied */

    if(queryFlag(ENTRY_NEEDS_TEMPLATE_APPLIED_FLAG)==false){
	/* If Base64RTFDString is not present, calculate it. */
	if(base64rtfdString.size() == 0){
	    /* calculate the base64rtfdstring if we can */
	    if(rtfdString.size()>0){
		sstring *tmp = b64stringForSString(rtfdString);
		base64rtfdString = *tmp;
		delete tmp;
	    }
	}
	if(base64rtfdString.size() > 0){
	    (*xml) += "<rtfd>" + base64rtfdString + "</rtfd>\n";
	}
    }

    char buf[1024];

    /* Only put out the sort key if it is different from the default */
    if(!el || el->defaultSortKey != sortKey){
	sprintf(buf,"<sk>%d</sk>\n",sortKey); 
	(*xml) += buf;
    }

    /* Only put out the flags if different form the default */
    if(!el || el->defaultEntryFlags!=flags){
	sprintf(buf,"<flags>%ld</flags>\n",flags);
	(*xml) += buf;
    }

    /* Only put out he ctime if it exists and if it is not the same as mtime */
    if(c_time && c_time != m_time){
	sprintf(buf,"<ctime>" TIMET_FMT "</ctime>\n",c_time);
	(*xml) += buf;
    }

    /* Only put out the atime if it exists */
    if(a_time){
	sprintf(buf,"<atime>" TIMET_FMT "</atime>\n",a_time);
	(*xml) += buf;
    }

    /* Only put out the mtime if it exists and is not the same as atime */
    if(m_time && m_time != a_time){
	sprintf(buf,"<mtime>" TIMET_FMT "</mtime>\n",m_time);
	(*xml) += buf;
    }
	
    /* only put out the cusername if it is different from musername */
    if(cusername && cusername[0] && cusername != musername){
	sprintf(buf,"<cuser>%s</cuser>\n",cusername);
	(*xml) += buf;
    }

    if(musername && musername[0]){
	sprintf(buf,"<muser>%s</muser>\n",musername);
	(*xml) += buf;
    }

    (*xml) += "</entry>\n";
}


std::ostream & operator<< (std::ostream &os,const Entry &ent)
{
    os << ent.asciiString;
    return os;
}
