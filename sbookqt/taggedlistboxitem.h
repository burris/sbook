#ifndef TAGGEDLISTBOXITEM_H
#define TAGGEDLISTBOXITEM_H

#include <qlistbox.h>
#include <qstring.h>
#include "entry.h"

class Q_EXPORT TaggedListBoxText : public QListBoxText
{
public:
    TaggedListBoxText(const QString *text=0);
    virtual void setText(const QString *text);
    int tag;
    Entry *entry;
};
#endif
