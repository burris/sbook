/*
 * The datastorageobject implements an object which knows how to set
 * named properties. Property values are passed in with char * strings.
 */

#ifndef DATASTORAGEOBJECT_H
#define DATASTORAGEOBJECT_H

#include <stdio.h>
#include <stdlib.h>
#include <qrect.h>
#include <qstring.h>
#include <qfont.h>

#include "nxatom.h"

#define DATASTORAGE public:\
    bool    setPropertyValue(NXAtom propertyName,const char *value);\
    QString *getValue(const char *name);\

class DataStorageObject
{
    DATASTORAGE;
protected:
    bool xset(QPoint &pt,const char *val);
    bool xset(QRect &qr,const char *val);
    bool xset(QFont &font,const char *val);
    bool xset(int &i,const char *val);
    bool xset(unsigned int &i,const char *val);
    bool xset(bool &i,const char *val);
    bool xset(time_t &i,const char *val);
    bool xset(QString &i,const char *val);
    bool xset(NXAtom &i,const char *val);
};

inline bool DataStorageObject::xset(QPoint &pt,const char *val)
{
    int x,y;
    sscanf(val,"%d,%d",&x,&y);
    pt.setX(x);
    pt.setY(y);
    return true;
}

inline bool DataStorageObject::xset(QRect &qr,const char *val)
{
    int x,y,w,h;
    sscanf(val,"%d,%d,%d,%d",&x,&y,&w,&h);
    qr.setRect(x,y,w,h);
    return TRUE;
}
    
inline bool DataStorageObject::xset(QFont &font,const char *val)
{
    char fname[1024];
    int	 size;

    if(strlen(val)<sizeof(fname)){
	fname[0] = 0;
	sscanf(val,"%[^,],%d",fname,&size);
	font = *(new QFont(fname,size));
	return true;
    }
    return false;
}

inline bool DataStorageObject::xset(int &i,const char *val) {i = atoi(val); return true;}
inline bool DataStorageObject::xset(unsigned int &i,const char *val){i= atoi(val);return true;}
inline bool DataStorageObject::xset(bool &i,const char *val) { i = atoi(val); return true; }
inline bool DataStorageObject::xset(time_t &i,const char *val) { i = atoi(val);return true; }
inline bool DataStorageObject::xset(QString &i,const char *val) { i = val;return true;}
inline bool DataStorageObject::xset(NXAtom &i,const char *val) { i = NXUniqueString(val);return true;}

inline bool DataStorageObject::setPropertyValue(NXAtom propertyName,const char *value)
{
    printf("can't set %s\n",propertyName);
    return false;
}

inline char *getValue(const QString &name)
{
    return 0;					  // not implemented
}



#endif
