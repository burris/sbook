#ifndef XML_H
#define XML_H

#include <stdio.h>
#include <qstring.h>
#include <qlist.h>
#include <qstrlist.h>
#include <qprogressbar.h>


#include "entry.h"
#include "entries.h"

#define Parsing_Nothing 0
#define Parsing_Entries 1
#define Parsing_Entry 2

#include "buffer.h"

class XML
{
private:
    class SBookWidget	*frame;			  // frame to modify?
    QProgressBar *progress;			  // how are we doing?
    FILE    *outFile;				  // output file
    Buffer buf;				  // input buffer

    bool getTokenPos(uint &pos,uint end,uint &tokenPos,uint &tokenEnd);
    bool getTagValue(uint &pos,uint end,NXAtom *retTag,uint &valPos,uint &valEnd);

    bool process(Entries *entries,const QString &tag,const QString &value);
    bool process(Entry *entry,const QString &tag,const QString &value);

    bool read(uint &pos,uint end,uint reading,Entries *e1,Entry *e2);

    bool writeTag(const char *name,const char *value);
    bool writeTag(const char *name,int value);
    bool writeTag(const char *name,unsigned int value);
    bool writeTag(const char *name,time_t value);
    bool writeTag(const char *name,bool value);
    bool writeTag(const char *name,const QRect &value);
    bool writeTag(const char *name,const QFont &font);
    bool writeTag(const char *name,const QString &value);
    bool writeEntryCount(Entries *entries);
    bool writeTag(const char *name,Entry *entry);
    bool writeTag(const char *name,Entries *entries);
public:
    XML();
    ~XML();
    int  readFile(const char *name,Entries *entries,class SBookWidget *frame,QProgressBar *pbar);
    bool writeFile(const char *name,Entries *entries,QProgressBar *pbar);
};


#endif
