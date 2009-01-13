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

#include "Identifier.h"
#include <ctype.h>

/* I'll do the folding, rather than have it done by regex.
 * regex doesn't do it very well ...
 */

Identifier::Identifier(const char *pat,bool foldFlag,bool spaceFlag)
{
    char	*cc;
    char	*work;

    space	= spaceFlag;
    fold	= foldFlag;

    work	= (char *)alloca(strlen(pat)+1);
    strcpy(work,pat);

    if(fold){
	for(cc=work;*cc;cc++){
	    *cc	= tolower(*cc);
	}
    }
	
    pattern	= NXUniqueString(work);

    regex	= new QRegExp(pattern,!foldFlag);
    debug = false;
}


bool Identifier::match(const char *string)
{
    char	*str;
    char	*cc;
    int	res;

    str = (char *)alloca(strlen(string)+4);
    str[0]	= '\000';
    if(space) strcpy(str," ");
    strcat(str,string);
    if(space) strcat(str," ");
    if(fold){
	for(cc=str;*cc;cc++){
	    *cc	= tolower(*cc);
	}
    }
    for(cc=str;*cc;cc++){
	if(*cc == '\t') *cc = ' ';
    }
    res = regex->search(str) != -1;
#ifdef DEBUG
    if(debug){
	printf("match<%s><%s> = %d\n",str,pattern,res);
    }
#endif
    return res;
}

void Identifier::setDebug(bool flag)
{
    debug = flag;
}


