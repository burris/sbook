#ifndef IDENTIFIER_H
#define IDENTIFIER_H

#include <qregexp.h>
#include "nxatom.h"

class Identifier
{
    bool	space;
    bool	fold;
    bool	debug;
    QRegExp	*regex;
public:
    NXAtom	pattern;
    Identifier(const char *pattern, bool fold=false,bool space=false);
    bool match(const char *str);
    void setDebug(bool);
};

#endif
