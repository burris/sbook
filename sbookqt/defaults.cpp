#include "defaults.h"
#include <stdio.h>
#include <windows.h>
#include <windowsx.h>

static Defaults *theGlobalDefaultObject=0;
static QString	globalVendor;
static QString	globalProgram;
static bool	globalsSet=false;

void setGlobalDefaults(const QString &vendor,const QString &program)
{
    globalVendor  = vendor;
    globalProgram = program;
    globalsSet	  = true;
}

Defaults *Defaults::globalDefaultObject()
{
    if(!globalsSet){
	fprintf(stderr,"Defaults: vendor and program name not set!\n");
	exit(1);
    }
    if(theGlobalDefaultObject==0){
	theGlobalDefaultObject = new Defaults(globalVendor,globalProgram);
    }
    return theGlobalDefaultObject;
}


Defaults::Defaults(const QString &vendor,const QString &program)
{
    QString path("Software\\" + vendor + "\\" + program);

    int rc = RegCreateKey(HKEY_CURRENT_USER,
		      path.latin1(),
		      (HKEY *)&hkMain);
    if(rc!=ERROR_SUCCESS){
	fprintf(stderr,"RegCreateKey failed\n");
	exit(0);
    }
}

Defaults::~Defaults()
{
    RegCloseKey((HKEY)hkMain);
}

void Defaults::set(const QString &name,const QString &value)
{
    int rc = RegSetValueEx((HKEY)hkMain,name.latin1(),0,REG_SZ,
			 (const unsigned char *)value.latin1(),
			 value.length());
    if(rc!=ERROR_SUCCESS){
	fprintf(stderr,"set: rc=%d\n",rc);
    }
}

void Defaults::set(const QString &name,bool value)
{
    QString val(value ? "TRUE" : "FALSE");
    set(name,val);
}



QString Defaults::get(const QString &name)
{
    char buffer[1024]= {0};
    unsigned long lpLen = sizeof(buffer);
    DWORD	lpType;

    int rc = RegQueryValueEx((HKEY)hkMain,
			     name.latin1(), 0, &lpType,
			     (unsigned char *)buffer, &lpLen);
    if(rc!=ERROR_SUCCESS){
	return QString("failure");
    }
    return QString(buffer);
}

bool Defaults::getBool(const QString &name)
{
    QString val = get(name);

    return val.compare("TRUE")==0;
}

