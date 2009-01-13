/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law.
 *
 */

#ifndef IDENTIFIER_LIST_H
#define IDENTIFIER_LIST_H

#include <qptrlist.h>
#include "Identifier.h"

class IdentifierList:public QPtrList<Identifier>
{
    bool debug;
public:
    IdentifierList();
    void addPattern(const char *aPattern,bool fold=false,bool space=false);
    void setDebug(bool debug);
    bool match(const char *string);
};
  
#endif
