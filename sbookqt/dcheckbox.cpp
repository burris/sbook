#include "dcheckbox.h"
#include <stdio.h>

static Defaults *def=0;

DCheckBox::DCheckBox( QWidget *parent, const char *name )
    :QCheckBox(parent,name)
{
    /* Get the global default object if we don't have it */
    if(def==0) def=Defaults::globalDefaultObject();
    
    /* Now set our state */
    setChecked(def->getBool(name));
}

DCheckBox::DCheckBox( const QString &text, QWidget *parent, const char* name )
    :QCheckBox(text,parent,name)
{
    /* Get the global default object if we don't have it */
    if(def==0) def=Defaults::globalDefaultObject();
    
    /* Now set our state */
    setChecked(def->getBool(name));

    connect(this,SIGNAL(stateChanged(int)),
	    this,SLOT(doStateChanged(int)));

}

/* SLOT to handle state changes. Save change in the registry */
void DCheckBox::doStateChanged(int state)
{
    def->set(name(),state);
}
