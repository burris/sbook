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

#include "IdentifierList.h"
#include "Identifier.h"


IdentifierList::IdentifierList()
{
}

void IdentifierList::addPattern(const char *aPattern,bool fold,bool space)
{
    append(new Identifier(aPattern,fold,space));
}

bool IdentifierList::match(const char *aString)
{
    Identifier *id;

    for(id=first();id!=0;id=next()){
	if(id->match(aString)){
	    return true;
	}
    }
    return false;
}

void IdentifierList::setDebug(bool debug)
{
    Identifier *id;

    for(id=first();id!=0;id=next()){
	id->setDebug(debug);
    }
}
