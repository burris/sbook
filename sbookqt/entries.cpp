#include "xml.h"
#include "entries.h"
#include "sbook.h"

#include <fcntl.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <qfile.h>
#include <qtextstream.h>
#include <qmessagebox.h>


NXAtom ENTRIES_ENTRYCOUNT_atom = NXUniqueString(ENTRIES_ENTRYCOUNT);
NXAtom ENTRIES_FRAME_atom = NXUniqueString(ENTRIES_FRAME);
NXAtom ENTRIES_DIVIDER_atom = NXUniqueString(ENTRIES_DIVIDER);
NXAtom ENTRIES_SORTFLAG_atom = NXUniqueString(ENTRIES_SORTFLAG);
NXAtom ENTRIES_PARSEFLAG_atom = NXUniqueString(ENTRIES_PARSEFLAG);
NXAtom ENTRIES_SEARCHMODE_atom = NXUniqueString(ENTRIES_SEARCHMODE);
NXAtom ENTRIES_TEMPLATE_atom = NXUniqueString(ENTRIES_TEMPLATE);
NXAtom ENTRIES_DEFAULTSORTKEY_atom = NXUniqueString(ENTRIES_DEFAULTSORTKEY);
NXAtom ENTRIES_FILECREATIONDATE_atom = NXUniqueString(ENTRIES_FILECREATIONDATE);
NXAtom ENTRIES_LISTFONT_atom = NXUniqueString(ENTRIES_LISTFONT);
NXAtom ENTRIES_ENTRYFONT_atom = NXUniqueString(ENTRIES_ENTRYFONT);
NXAtom ENTRIES_NEXTSN_atom	= NXUniqueString(ENTRIES_NEXTSN);

/****************************************************************/

Entries::Entries()
    :listFont("arial",10)
{
    /* Set the defaults */
    list.setAutoDelete( true );		  // autodelete
    sortFlag    = true;			  // sort by default
    parseFlag   = true;			  // parse by default
    fileCreationDate = time(0);
    template_	= "New Name %d\nAddress\n";		  // default
    //listFont	= QFont("arial",10);
    entryFont	= QFont("arial",12);
    loading = false;
    filename	= NXUniqueString("");
    nextSN	= 0;
}

bool Entries::setPropertyValue(NXAtom property,const char *v)
{
    if(property == ENTRIES_FRAME_atom ){
	if(xset(frame,v)){
	    return true;
	}
	return false;
    }
    if(property == ENTRIES_DIVIDER_atom )   return xset(divider,v);
    if(property == ENTRIES_SORTFLAG_atom )	return xset(sortFlag,v);
    if(property == ENTRIES_PARSEFLAG_atom )	return xset(parseFlag,v);
    if(property == ENTRIES_SEARCHMODE_atom ) return xset(searchMode,v);
    if(property == ENTRIES_TEMPLATE_atom )	return xset(template_,v);
    if(property == ENTRIES_DEFAULTSORTKEY_atom ) return xset(defaultSortKey,v);
    if(property == ENTRIES_FILECREATIONDATE_atom ) return xset(fileCreationDate,v);
    if(property == ENTRIES_LISTFONT_atom )	return xset(listFont,v);
    if(property == ENTRIES_ENTRYFONT_atom )	return xset(entryFont,v);
    if(property == ENTRIES_NEXTSN_atom)		return xset(nextSN,v);
    fprintf(stderr,"Unknown Entires property: '%s'\n",property);
    return TRUE;				  // unknown tags are non-fatal
}

/* Empty:
 * Remove all of the entries from the list,
 * deleting them in the process.
 */
void Entries::Empty()
{
    while(!list.isEmpty()){
	Entry *entry = list.first();
	list.removeFirst();
	//delete entry;
    }
}

/* add:
 * Add an entry. If we are sorting, then sort it unless we are loading.
 */
void Entries::add(Entry *entry)
{
    /* If this entry doesn't have a serial number, assign one.
     * If it has a SN that is higher than others in the entrylist,
     * adjust the entry list.
     */
    if(entry->SN==0){
	entry->SN = getNextSN();
    }
    else{
	if(entry->SN > nextSN){
	    nextSN = entry->SN+1;
	}
    }

    list.append(entry);
}

void Entries::remove(Entry *entry)
{
    list.remove(entry);
}

/* 
 * LoadSBookASCIIFromFile:
 * Clears current list.
 * Returns the number improted, -1 if failure.
 */

int Entries::ImportSBookASCII(const QString &fn)
{
    int	count=0;
    QFile f(fn);

    if ( !f.open(IO_ReadOnly)){
	return -1;
    }

    QTextStream t(&f);
    
    QString text;

    while ( !t.eof()){
	QString line = t.readLine();
	if(line.latin1()[0]=='=' || t.eof()){
	    if(text.length()>0){
		list.append(new Entry(text));
		text.truncate(0);
		count++;
	    }
	}
	else{
	    text.append(line);			  // else append the text
	    text.append("\n");			  // add a newline
	}
    }
    return count;
}

/* Import a Macintosh InfoGenie database */

int Entries::ImportIG(const QString &fn)
{
    QString text;
    int count=0;

    FILE *f;
    f = fopen(fn,"r");
    if(!f) return -1;
    while(!feof(f)){
	int c = fgetc(f);
	if(c=='\r') c='\n';			  // Macintosh stuff
	if(c==6 || feof(f)){
	    if(text.length()>0){
		list.append(new Entry(text));
		text.truncate(0);
		count++;
	    }
	}
	else{
	    text.append((char)c);
	}
    }
    fclose(f);
    return count;
}

static QString readNextField(QTextStream &t,QString &data,int delim)
{
    QChar theDelim = (delim==TAB_DELIM ?QChar::QChar('\t'):QChar::QChar(','));
    QString ret;
    QChar quote = QChar::QChar('"');
    QChar slash = QChar::QChar('\\');

    if(data.length()==0){
	return ret;
    }

    if(data.at(0)!=quote){
	/* It's not a quoted string, so just find the position of the delimiter
	 */
	int pos = data.find(theDelim);
	if(pos==-1){				  // end of string
	    ret = data;				  // return all the data
	    data.truncate(0);			  // truncate this
	    return ret;
	}
	ret = data.left(pos);			  // read to the delim
	data.remove(0,pos+1);			  // remove up to delim
	return ret;
    }

    /* Need to find the trailing quote, removing escaped quotes,
     * and dealing with escapes.
     */

    data.remove(0,1);				  // remove the quote
 again:;
    for(unsigned int pos=0;pos<data.length();pos++){
 	if(data.at(pos)==quote){		  // found the end!
	    data.remove(0,pos+1);		  // remove the data to the quote 
	    int d = data.find(theDelim);	  // look for the delimiter
	    if(d!=-1){
		data.remove(0,d+1);		  // remove to the delim
	    }
	    return ret;
	}
	if(data.at(pos)==slash){		  // escape
	    ret += data.at(pos+1);		  // get the char
	    pos += 1;				  // space past it
	    continue;
	}
	ret += data.at(pos);			  // append the character
    }

    // Woah! Ran off the need of the string while reading a quoted string. 
    // We must have an embedded newline.
    // Now get another line and try again.
    ret  += QChar::QChar('\n');
    data = t.readLine();
    goto again;
}

int Entries::ImportDelimited(const QString &fn,int delim)
{
    QFile f(fn);
    if ( !f.open(IO_ReadOnly)){
	return -1;
    }

    QTextStream t( &f );        // use a text stream
    int	    count = 0;
    while ( !t.eof() ) {        // until end of file...
	QString s = t.readLine();       // line of text excluding '\n'
	QString text;

	int field=0;

	while(s.length()>0){
	    text += readNextField(t,s,delim);
	    if(++field == 1){
		text += " ";
	    }
	    else{
		text += "\n";			  // don't put \n between first and last name
	    }
	}

	list.append(new Entry(text));
	count++;
    }
    f.close();

    return count;
}


int Entries::Export(const char *fn,int format)
{
    FILE *f = fopen(fn,"w");
    
    if(!f){
	QMessageBox::warning(0,APP_NAME ": Export","Export Failed");
	return -1;
    }
	
    Entry *ent;

    for ( ent=list.first(); ent != 0; ent=list.next() ){
	ent->Export(f,format);
    }
    fclose(f);
    return 0;
}

/* setDefaultSortKey:
 * Sets the sortKey. If it is different then what we had, do a resort.
 */

int EntryList::compareItems(QCollection::Item c1,QCollection::Item c2)
{
    Entry *e1 = (Entry *)c1;
    Entry *e2 = (Entry *)c2;

    return e1->compare(e2);
}

void Entries::setDefaultSortKey(int sortOrder)
{
    if(defaultSortKey == sortOrder) return;
    defaultSortKey = sortOrder;
}

void Entries::sortEntries()
{
    if(!sortFlag) return;			  //  we do not sort
    list.sort();				  // sort the list!
}

void Entries::setSortFlag(bool newFlag)
{
    if(sortFlag==newFlag) return;		  // no action
    sortFlag = newFlag;
    if(sortFlag) sortEntries();			  // and sort
}

/* setLoading:
 * Tells the object if we are loading or not. If we reset the flag and the
 * file is suposed to be sorted, then sort it.
 */
void Entries::setLoading(bool flag)
{
    if(flag==loading) return;			  // no change
    loading = flag;
    if(loading==false && sortFlag){
	sortEntries();
    }
}

int Entries::loadFile(const char *filename_,class SBookWidget *frame,QProgressBar *bar)
{
    XML xml;

    Empty();				  // get rid of what we have
    filename = NXUniqueString(filename_);
    if(xml.readFile(filename,this,frame,bar)==false){
	return -1;
    }
    return 0;
}

/*
 * checkForReload: check to see if file was modified.
 * If it was, reload.
 */

void Entries::checkForReload()
{
    struct stat st;

    if(stat(filename,&st)==0){
	if(st.st_mtime > file_mtime){
	    loadFile(filename,0,0);
	}
    }
}
