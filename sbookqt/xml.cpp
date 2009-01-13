/*
 * xml.cpp:
 * 
 * Handles SBook's XML import & export.
 * SBook doesn't use real XML, just something that looks like XML.
 * We map the full XML file into memory, then we keep a pointer as
 * to where we are reading
 */

#include "xml.h"
#include "assert.h"

#ifdef WIN32
#include <crtdbg.h>  // For Heap Assertion Bug
#include <io.h>
#endif

#include <fcntl.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "sbookwidget.h"
#include "qapplication.h"

//#define DEBUG_XML

static NXAtom entries_atom = NXUniqueString("entries");
static NXAtom entry_atom   = NXUniqueString("entry");
static NXAtom ENTRIES_ENTRYCOUNT_atom = NXUniqueString(ENTRIES_ENTRYCOUNT);
static NXAtom ENTRIES_FRAME_atom = NXUniqueString(ENTRIES_FRAME);

XML::XML()
{
}

XML::~XML()
{
}

/* Find the next token, either an <xml> thing, a </xml> thing,
 * or stuff between things.
 */



bool XML::getTokenPos(uint &pos,uint end,uint &tokenPos,uint &tokenEnd)
{
    if(pos>=end) return FALSE;
    
    tokenPos = pos;

    /* If this is the start of an XML tag, search for where it ends */
    if(buf.at(pos)=='<'){
	pos = buf.find('>',pos);
	if(pos!=-1 && pos<end){			  
	    tokenEnd = ++pos;
	    return TRUE;			  // found
	}
	return FALSE;
    }

    /* Otherwise, find the beginning of the next tag, and return
     * everything between where we are and the next tag.
     */
    pos = buf.find('<',pos);
    if(pos!=-1 && pos<end){
	tokenEnd = pos;
	return TRUE;
    }
    return FALSE;				  // couldn't find it
}

/*
 * getTagValue:
 * search for the next <tag> [value] </tag> pair, and
 * returns "tag" and the location (and length) of the value.
 *
 * Returns TRUE if successful, FALSE if it reaches EOF first.
 */

bool XML::getTagValue(uint &pos,uint end,
		      NXAtom *retTag,uint &valpos,uint &valend)
{
    uint tagpos,tagend;

    // assert( _CrtCheckMemory( ) );

    do{
	if(getTokenPos(pos,end,tagpos,tagend)==FALSE){
	    return FALSE;		// EOF
	}
    } while(buf.at(tagpos)!='<');	// scan until we find a tag start

    // assert( _CrtCheckMemory( ) );

    Buffer tag = buf.mid(tagpos,tagend-tagpos);

    /* See if it is one of those empty elements with the <empty/> syntax */
    if(tag.length()>4 &&
       tag.at(tag.length()-2)=='/' &&
       tag.at(tag.length()-1)=='>'){
	
	*retTag = NXUniqueString(tag.mid(1,tag.length()-3).latin1());
	valpos = pos;
	valend = pos;				  // 0 length
	return TRUE;
    }
    
    /* Note that the value of this tag starts right where the tag ends */
    *retTag = NXUniqueString(tag.mid(1,tag.length()-2).latin1());
    valpos = pos;

    /* Turn <tag> into </tag>, which is the tag we are looking for */

    char *wantTag = (char *)alloca(tag.length()+4);
    int  tlen = tag.length()-2;
    unsigned int  wantTag_len = tag.length()+1;

    wantTag[0] = '<';
    wantTag[1] = '/';
    memcpy(wantTag+2,tag.buf+1,tlen);
    wantTag[tlen+2] = '>';
    wantTag[tlen+3] = '\000';

    //printf("tag=%s  wantTag=%s\n",tag.latin1(),wantTag);

    /* Now keep looking at the tokens we get until we find
     * the closing tag.
     */
    while(getTokenPos(pos,end,tagpos,tagend)){
	/* See if what we got is the right size; if it is, then
	 * do the full string compare.
	 */

	if(wantTag_len == tagend-tagpos){
	    Buffer foundTag = buf.mid(tagpos,tagend-tagpos);
	    
	    if(foundTag.compare(wantTag)==0){
		valend = tagpos;
		return TRUE;
	    }
	}
    }

    return FALSE;		// ran off the end of the input
}

/* Process an XML tag/value pair */



/* Read:
 * Read the next <tag>value</tag> pair from source.
 * If buf is null, read it from the input file.
 */

bool XML::read(uint &pos,uint end,uint reading,
	       Entries *currentEntries,Entry *currentEntry)
{
    NXAtom	tag;				  // this one is slowing us down...
    uint	valpos;
    uint	valend;

    while(getTagValue(pos,end,&tag,valpos,valend)==TRUE){
      //printf("tag=%s\n",tag);

	// assert( _CrtCheckMemory( ) );
	Buffer value = buf.mid(valpos,valend-valpos);
	switch(reading){
	case Parsing_Nothing:
	    if(tag == entries_atom){
#ifdef DEBUG_XML
		printf("found entries tag\n");
#endif		
		return read(valpos,valend,Parsing_Entries,currentEntries,0);
	    }
	    debug("Expecting '%s' (%x). found '%s' (%x)\n",entries_atom,entries_atom,tag,tag);
#ifdef DEBUG_XML
	    int i;
	    for(i=0;i<10;i++){
		printf("NXUniqueString('simson')=%x\n",NXUniqueString("simson"));
	    }
	    
#endif		
	    return FALSE;
	case Parsing_Entries:
	    if(tag == entry_atom){
#ifdef DEBUG_XML
		printf("found entry tag\n");
#endif		

		/* Found an entry. Read it and then add it to the list */
		Entry *newEntry = new Entry("");
		read(valpos,valend,Parsing_Entry,currentEntries,newEntry);

		currentEntries->add(newEntry);
#ifdef DEBUG_XML
		printf("added entry %d\n",currentEntries->count());
#endif	
		int count = currentEntries->count();
		if(progress && (count%50==49 || count==progress->totalSteps()-2)){
		    progress->setProgress(count);
		    //qApp->processEvents();
		}
		break;
	    }
	    if(tag == ENTRIES_ENTRYCOUNT_atom){
		/* We only use the entrycount in the file for informing the user */
		if(progress){
		    progress->setTotalSteps(value.toInt());
		}
		break;
	    }
	    /* Otherwise, set the property value */
	    if(!currentEntries->setPropertyValue(tag,value.latin1())){
		/* If we set the frame, move the window */
		if(tag == ENTRIES_FRAME_atom){
		    frame->setGeometry(currentEntries->frame);
		}
	    }
	    break;
	case Parsing_Entry:
	    if(!currentEntry->setPropertyValue(tag,value.latin1())){
		return FALSE;
	    }
	    break;
	}
    }
    return TRUE;
}

/* Read a file into the buffer, unquote it, and process the XML entries. */
int XML::readFile(const char *name,Entries *entries,SBookWidget *frame_,QProgressBar *pbar)
{    
    QString readBuf;

    entries->setLoading(true);			  // we are loading

    frame	= frame_;
    progress	= pbar;
    if(progress){
	pbar->setProgress(0);
    }

    FILE *f = fopen(name,"r");
    if(!f) return -1;

    /* Stat the file */
    struct stat st;
    if(fstat(fileno(f),&st)==0){
	entries->file_mtime = st.st_mtime;
    }

    while(!feof(f)){
	int c = fgetc(f);
	if(c=='&'){
	    QString quoteString;
	    int c2;
	    while((c2=fgetc(f))!=EOF){
		if(c2==';') break;
		quoteString += (char)c2;
	    }
	    if(quoteString.compare("lt")==0) c='<';
	    if(quoteString.compare("gt")==0) c='>';
	    if(quoteString.compare("amp")==0) c='&';
	}
	readBuf += (char)c;
	continue;
    }
    fclose(f);
    buf.setBuf(readBuf.latin1());
    
    /* Now we have the file in buf, and it's unquoted */
    uint pos = 0;
    uint end = buf.length();
    uint tokenPos,tokenEnd;

    /* Get the first token to verify that it is an XML token */

    if(getTokenPos(pos,end,tokenPos,tokenEnd)==0){
	entries->setLoading(false);
	return false;		// couldn't read document
    }

    QString head = buf.mid(tokenPos,tokenEnd-tokenPos).qstring();
    if(head.find("<?xml ",0,TRUE)!=0){
	entries->setLoading(false);
	return -1;		// not XML
    }

    /* Ge the second token to make sure it is a DOCTYPE token */
    pos=tokenEnd+1;
    if(getTokenPos(pos,end,tokenPos,tokenEnd)==0){
	entries->setLoading(false);
	return false;		// couldn't read document
    }

    head = buf.mid(tokenPos,tokenEnd-tokenPos).qstring();
    if(head.find("<!DOCTYPE ",0,TRUE)!=0){
      printf("head=%s\n",head.latin1());
      puts("not a doctype");
      entries->setLoading(false);
      return -1;		// not XML
    }

    /* Now read the file */

    if(read(pos,end,Parsing_Nothing,entries,0)==false){
	entries->setLoading(false);
	return -1;
    }
    entries->setLoading(false);
    return entries->count();
}


/*================================================================*/

bool XML::writeTag(const char *name,const char *value)
{
    int namelen = strlen(name);

    fputc('<',outFile);
    fwrite(name,1,namelen,outFile);
    fputc('>',outFile);

    const char *c;
    for(c=value;*c;c++){
	switch(*c){
	case '<':
	    fwrite("&lt;",1,4,outFile);
	    break;
	case '>':
	    fwrite("&gt;",1,4,outFile);
	    break;
	case '&':
	    fwrite("&amp;",1,5,outFile);
	    break;
	default:
	    fputc(*c,outFile);
	    break;
	}
    }

    fputc('<',outFile);
    fputc('/',outFile);
    fwrite(name,1,namelen,outFile);
    fputc('>',outFile);
    fputc('\n',outFile);
    return TRUE;
}

bool XML::writeTag(const char *name,int value)
{
    char buf[64];
    if(value==0) return true;			  // no reason to write 0s

    itoa(value,buf,10);
    return writeTag(name,buf);
}

bool XML::writeTag(const char *name,unsigned int value)
{
    char buf[64];
    if(value==0) return true;			  // no reason to write 0s

    itoa(value,buf,10);
    return writeTag(name,buf);
}

bool XML::writeTag(const char *name,bool value)
{
    if(value==0) return true;

    QString val;
    val.setNum(value);
    return writeTag(name,val);
}

bool XML::writeTag(const char *name,time_t value)
{
    if(value==0) return true;

    QString val;
    val.setNum(value);
    return writeTag(name,val);
}

bool XML::writeTag(const char *name,const QRect &frame)
{
    char buf[1024];
    sprintf(buf,"%d,%d,%d,%d",
		frame.x(),frame.y(),
		frame.width(),frame.height());
    return writeTag(name,buf);
}

bool XML::writeTag(const char *name,const QFont &font)
{
    //char buf[1024];
    //sprintf(buf,"%s,%d",font.family().latin1(),font.pointSize());
    //return writeTag(name,buf);
	return true;
}

bool XML::writeTag(const char *name,const QString &value)
{
    return writeTag(name,value.latin1());
}

bool XML::writeTag(const char *name,Entry *entry)
{
    if(entry->theText.length()==0){		  // don't write 0-length entries
	return true;
    }

    fputc('<',outFile);
    fputs(name,outFile);
    fputs(">\n",outFile);

    if(!writeTag(ENTRY_TEXT,entry->theText))	return FALSE;
    if(!writeTag(ENTRY_SN,entry->SN))	return FALSE;
    if(!writeTag(ENTRY_SORTKEY,entry->sortKey)) return FALSE;
    if(!writeTag(ENTRY_CTIME,entry->ctime)) return FALSE;
    if(!writeTag(ENTRY_MTIME,entry->atime)) return FALSE;
    if(!writeTag(ENTRY_ATIME,entry->mtime)) return FALSE;
    if(!writeTag(ENTRY_SHOULDPARSE,entry->shouldParse)) return FALSE;
    if(!writeTag(ENTRY_CUSERNAME,entry->cusername)) return FALSE;
    if(!writeTag(ENTRY_MUSERNAME,entry->musername)) return FALSE;
    if(!writeTag(ENTRY_CALLTIME,entry->calltime)) return FALSE;
    if(!writeTag(ENTRY_ENVTIME,entry->envtime)) return FALSE;
    if(!writeTag(ENTRY_EMAILTIME,entry->emailtime)) return FALSE;

    fputs("</",outFile);
    fputs(name,outFile);
    fputs(">\n",outFile);
    return TRUE;
}

bool XML::writeEntryCount(Entries *entries)
{
    QString entryCount;
    entryCount.sprintf("%d",entries->list.count());
    return writeTag(ENTRIES_ENTRYCOUNT,entryCount);
}

bool XML::writeTag(const char *name,Entries *entries)
{
    fputc('<',outFile);
    fputs(name,outFile);
    fputs(">\n",outFile);

    if(!writeEntryCount(entries))			return FALSE;

    if(!writeTag(ENTRIES_FRAME,entries->frame))		return FALSE;
    if(!writeTag(ENTRIES_DIVIDER,entries->divider))		return FALSE;
    if(!writeTag(ENTRIES_SORTFLAG,entries->sortFlag)) return FALSE;
    if(!writeTag(ENTRIES_PARSEFLAG,entries->parseFlag)) return FALSE;
    if(!writeTag(ENTRIES_SEARCHMODE,entries->searchMode))	return FALSE;
    if(!writeTag(ENTRIES_TEMPLATE,entries->template_))	return FALSE;
    if(!writeTag(ENTRIES_FILECREATIONDATE,entries->fileCreationDate)) return FALSE;
    if(!writeTag(ENTRIES_DEFAULTSORTKEY,entries->defaultSortKey)) return FALSE;
    if(!writeTag(ENTRIES_LISTFONT,entries->listFont))	return FALSE;
    if(!writeTag(ENTRIES_ENTRYFONT,entries->entryFont))	return FALSE;

    Entry *ent;
    int count=0;
    for(ent = entries->list.first();
	ent != 0;
	ent = entries->list.next()){
	writeTag("entry",ent);
	if(progress && (count%50==49 || count==progress->totalSteps()-2)){
	    progress->setProgress(count);
	    //qApp->processEvents();
	}
	count++;
    }

    fputs("</",outFile);
    fputs(name,outFile);
    fputc('>',outFile);
    return TRUE;
}


/* writeFile:
 * Write to a temporary file. Then delete the backup file,
 * rename the old file to the backup file, then rename the
 * temporary file to the current file
 */

#ifdef WIN32
#define mktemp(x) _mktemp(x)
#endif

bool XML::writeFile(const char *fn,Entries *entries,QProgressBar *pbar)
{
    char temp_filename[1024];
    char bak_filename[1024];

    strcpy(temp_filename,fn);
    strcat(temp_filename,"XXXXX");
    mktemp(temp_filename);

    strcpy(bak_filename,fn);
    strcat(bak_filename,".bak");

    progress = pbar;
    outFile = fopen(temp_filename,"w");
    if(outFile){
	if(pbar){
	    pbar->setProgress(0);
	    pbar->setTotalSteps(entries->count());
	}
	fprintf(outFile,"<?xml version=\"1.0\"?>\n");
	fprintf(outFile,"<!DOCTYPE article\nPUBLIC \"-//Simson L. Garfinkel//DTD SBook XML 1.0//EN\"\n\"http://www.simson.net/sbook/1.0/sbook.dtd\">");

	bool res = writeTag("entries",entries);
	fclose(outFile);

	if(!res){
	    unlink(temp_filename);
	    return false;
	}

	unlink(bak_filename);
	rename(fn,bak_filename);
	unlink(fn);
	if(rename(temp_filename,fn)){
	    return false;
	}
	return true;
    }
    return false;
}


