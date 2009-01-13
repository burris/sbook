#include "taggedlistboxitem.h"

TaggedListBoxText::TaggedListBoxText(const QString *text)
    : QListBoxText()
{
    setText(text);
}

void TaggedListBoxText::setText(const QString *text)
{
    QListBoxText::setText(text ? *text : QString(""));
}
