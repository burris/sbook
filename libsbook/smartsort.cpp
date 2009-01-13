/*
 * (C) Copyright 2001,2002 by Simson Garfinkel.
 *
 * All Rights Reserved.
 *
 */
#include <stdio.h>
#include <ctype.h>
#include <string.h>

#ifdef WIN32
#include <malloc.h>
#endif

#include "libsbook.h"


int	smartsort_iscorp(const char *line)
{
    int a;

    if(parse_company(line)) return true;

    a = parse_address(line) ;
    if((a & (P_COUNTRY | P_CITY | P_STATE | P_ORG)) &&
       (a & P_WEAK)==0){
	return true;
    }
    return false;
}


const char *wordBeforeComma(const char *theLine)
{
    const char *comma = strchr(theLine,',');
    const char *before;
    for(before=comma;before>theLine;before--){
	if(*before == ' '){
	    before++;
	    break;
	}
    }
    
    int  len = comma-before;
    if(len<1) return 0;
    
    char *buf = (char *)alloca(len);
    
    int  j;
    for(j=0;j<len;j++){
	buf[j] = toupper(before[j]);
    }
    buf[len] = 0;
    return NXUniqueString(buf);
}

int hasCommaBeforeSpace(const char *str,unsigned *loc)
{
    bool foundComma=false;
    unsigned where;
    int i = 0;

    for(;*str;str++,i++){
	switch(*str){
	case ' ':
	    if(foundComma){
		*loc = where;
		return true;
	    }
	    return false;
	case ',':
	    foundComma = true;
	    where = i;
	}
    }
    return false;
}



/* smartSortName:
 * Returns the name that we are sorting upon and whether or not the person is a compnay.
 */

NXAtom smartSortName(const char *theLine,int entryFlags,const NXAtomList &atoms,int *isPerson)
{
    bool forcedPerson = false;		// we haven't forced to be a person
    if(isPerson) *isPerson = 1;	// but assume we are a person unless otherwise

    switch(entryFlags & ENTRY_FORCE_MASK){
    case ENTRY_FORCE_PERSON:
	forcedPerson = true;
	if(atoms.count()==0) return NXUniqueString("");
	break;
    case ENTRY_FORCE_COMPANY:
	if(isPerson) *isPerson = 0;
	if(atoms.count()==0) return NXUniqueString("");	// return the empty atom
	return atoms[0];		// return the first atom
	break;
    default:
	break;
    }


    if(atoms.count()==0){
	if(isPerson) *isPerson = 0;
	return NXUniqueString("");
    }

    /* Very special case.  if we are U. S. <something> return US... */
    if(theLine[0]=='U' && theLine[1]=='.' && theLine[2]=='S' && theLine[3]=='.'){
	if(isPerson && !forcedPerson) *isPerson = 0;
	return atom_US;
    }
    if(theLine[0]=='U' && theLine[1]=='.' && theLine[2]==' '
       && theLine[3]=='S' && theLine[4]=='.'){
	if(isPerson && !forcedPerson) *isPerson = 0;
	return atom_US;
    }

    /* Second very special case:
     * If there is text and something in <angle brackets>
     * (like an email address), remove the angle brackets and apply recursively
     */
    char *b1 = strchr(theLine,'<');
    if(b1 && b1>theLine+2){
	char *b2 = strchr(theLine,'>');
	if(b2 && b1<b2){
	    int len = b1 - theLine;
	    char *temp = (char *)alloca(len+1);
	    memcpy(temp,theLine,len);
	    temp[len]='\000';
	    NXAtomList *tempList = atomsForNames(temp,false);
	    NXAtom res = smartSortName(temp,entryFlags,*tempList,isPerson);
	    delete tempList;
	    return res;
	}
    }

    const char *comma = strchr(theLine,',');
    /* If there is a comma and after it is a title, return the word before the comma */
    if(comma && comma[1] && comma[2] && isRomanOrTitle(comma+2)){
	const char *before = wordBeforeComma(theLine);
	if(before){
	    return before;
	}
    }

    if(!forcedPerson && smartsort_iscorp(theLine)){
	/* It's a company.
	 * If the first word is the definate article, don't sort on it.
	 */
	if(isPerson) *isPerson = 0;
	if(atoms.count()>1 && atoms[0]==atom_THE){
	    return atoms[1];
	}

	if(atoms.count()>3 && atoms[0]==atom_U && atoms[1]==atom_S){
	    return atom_US;
	}

	return atoms[0];	/* a company */
    }

    /* If there is the word "and" that is not the first or last, and it is
     * not preeceded with a Mr. or Mrs., then this is probably a company,
     * so sort on the last name...
     */
    unsigned int i;
    for(i=1;i<atoms.count()-1;i++){
	if(atoms[i]==atom_AND){
	    /* If there is a comma, return the first name */
	    if(comma) return atoms[0];

	    /* If it is "x and y", return the first */
	    if(atoms.count()==3) return atoms[0];
	    
	    /* otherwise, return on the last name */
	    return atoms.last();
	}
    }

    /* If the first word is an innercap word, then it must be the
     * the sortname
     */
    if(strlen(atoms[0])>3 && isInnerCap(atoms[0])){
	return atoms[0];
    }
	

    /* If we find a comma, grab the word before it, even if that
     * word isn't one of the atoms...
     */
    if(comma){
	const char *before = wordBeforeComma(theLine);
	if(before) return before;
    }
		
    /* Otherwise, return the last word that isn't a single-character
     * and isn't a roman numeral or a title.
     */
    for(i=atoms.count()-1;i>0;i--){
	if(atoms[i][1]==0) continue;
	if(isRomanOrTitle(atoms[i])) continue;
	return atoms[i];
    }
    /* Return the first */
    if(isPerson && !forcedPerson) *isPerson = 0;
    return atoms[i];
}

