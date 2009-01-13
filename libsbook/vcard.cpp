/*
 * (C) Copyright 2002 Simson L. Garfinkel.
 * All rights reserved.
 * 
 * Parse some text.
 */


#include "libsbook.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>



static void str_qcat(char *base,const char *str,int buflen)
{
    int baselen = strlen(base);
    char *cc;
    const char *dd;

    for(cc=base+baselen,dd=str;*dd && cc<base+buflen;){
	if(*dd==',' || *dd==';'){	// these characters must be quoted
	    *cc++ = '\\';
	    *cc++ = *dd++;
	    continue;
	}
	if(*dd=='\n'){			// this needs a different kind of quoting
	    *cc++ = '\\';
	    *cc++ = 'n';
	    dd++;
	    continue;
	}
	if(*dd=='\r'){			// ignore these
	    dd++;
	    continue;
	}
	*cc++ = *dd++;			// nothing special
    }
    *cc++ =  '\000';			// null-terminate
}

static void strncat2(char *base,const char *name,const char *val,int buflen)
{
    if(name) strncat(base,name,buflen);
    if(val)  str_qcat(base,val,buflen);
    strncat(base,"\n",buflen);
}

static void strncat3(char *base,const char *name,const char *qval,const char *suffix,int buflen)
{
    if(name) strncat(base,name,buflen);
    if(qval)  str_qcat(base,qval,buflen);
    if(suffix)   strncat(base,suffix,buflen);
}

/* We should do better on this one */
static bool istitle(const char *buf)
{
    if(isalpha(buf[0]) && isalpha(buf[1]) && buf[2]=='.' && buf[3]==0) return true;
    if(isalpha(buf[0]) && isalpha(buf[1]) && isalpha(buf[2]) && buf[3]=='.' && buf[4]==0) return true;
    if(isalpha(buf[0]) && buf[1]=='.' && isalpha(buf[2]) && buf[3]=='.') return true;
    if(isalpha(buf[0]) && buf[1]=='.' && isalpha(buf[2]) && buf[3]=='.' && isalpha(buf[4]) && buf[5]=='.') return true;
    return false;
}


    

extern "C"
void parse_block_to_vcard(const char *inbuf,unsigned int entryFlags,char *vcard,unsigned int buflen)
{
    char  **lines=0;
    unsigned int   *results=0;
    unsigned int   numLines=0;
    unsigned int   i,j;
    char *label=0;			// current label

    vcard[0] = 0;
    strncat(vcard,"BEGIN:VCARD\n",buflen);
    strncat(vcard,"VERSION:3.0\n",buflen);
    //strncat(vcard,"PRODID:-//Simson L. Garfinkel//NONSGML SBook5//EN\n",buflen);

    parse_block(inbuf,&lines,&results,&numLines,0,0);

    if(numLines==0) goto done;


    /* Process the first two lines. */

    strncat2(vcard,"FN:",lines[0],buflen);

    /* Grab out the names
     * From RFC 2426:
     * Type special note: The structured type value corresponds, in
     * sequence, to the Family Name, Given Name, Additional Names, Honorific
     * Prefixes, and Honorific Suffixes. The text components are separated
     * by the SEMI-COLON character (ASCII decimal 59). Individual text
     * components can include multiple text values (e.g., multiple
     * Additional Names) separated by the COMMA character (ASCII decimal
     * 44). This type is based on the semantics of the X.520 individual name
     * attributes. The property MUST be present in the vCard object.
     *
     * Type example:
     * 
     * N:Public;John;Quinlan;Mr.;Esq.
     *
     * N:Stevenson;John;Philip,Paul;Dr.;Jr.,M.D.,A.C.P.
     *
     * N:FamilyName;GivenName;Additional Names;Honorific Prefixes;Honorific Suffixes
     */

    if((results[0] & P_BUT_MASK)!=P_BUT_PERSON){
	strncat3(vcard,"N:",lines[0],";;;;\n",buflen);
    }

    if((results[0] & P_BUT_MASK)==P_BUT_PERSON){
	int entryFlags = 0;
	NXAtomList *list = atomsForNames(lines[0],true);
	NXAtom familyName = smartSortName(lines[0],entryFlags,*list,0);
	NXAtom givenName  = 0;
	char *prefixes = (char *)malloc(strlen(lines[0])+64);prefixes[0] = 0;
	char *suffixes = (char *)malloc(strlen(lines[0])+64);suffixes[0] = 0;
	unsigned int i;

	/* Find prefixes */
	for(i=0; i<list->count(); i++){
	    if(istitle((*list)[i])){
		if(prefixes[0]) strcat(prefixes,",");
		strcat(prefixes,(*list)[i]);
		(*list)[i] = 0;
	    }
	    else {
		break;
	    }
	}

	/* See if we can find the givenName */
	for(i=0;i<list->count();i++){
	    NXAtom a = (*list)[0];
	    if(a && a!=familyName){
		givenName = a;
		break;
	    }
	}

	/* Find suffixes */
	for(i=list->count()-1; i>=0; i--){
	    if(istitle((*list)[i])){
		if(suffixes[0]) strcat(suffixes,",");
		strcat(suffixes,(*list)[i]);
		(*list)[i] = 0;
	    }
	    else {
		break;
	    }
	}
	
	strcat(vcard,"N:");
	strncat3(vcard,0,familyName,";",buflen);
	strncat3(vcard,0,givenName,";",buflen);

	for(i=0;i<list->count();i++){
	    NXAtom a = (*list)[i];
	    if(a==givenName) continue;
	    if(a==familyName) continue;
	    if((*list)[i]) strncat3(vcard,0,(*list)[i]," ",buflen);
	}
	strncat(vcard,";",buflen);

	strncat3(vcard,0,suffixes,0,buflen);
	strncat(vcard,"\n",buflen);
	free(suffixes);
	free(prefixes);
	delete list;
    }

    /* Scan first three lines for a company. If we find it, throw out
     * and ORG...
     */

    for(i=0;i<numLines && i<3;i++){
	//printf("parse_company(%s)=%d\n",lines[i],parse_company(lines[i]));

	if(parse_company(lines[i])){
	    strncat2(vcard,"ORG:",lines[i],buflen);
	    break;
	}
    }

    /* Now go down the list and pull out all of the icons that we find
     * using the standard icon rules...
     */
    for(i=1;i<numLines;i++){
	char *cc = 0;
	char *block = 0;

	if(onlyBlankChars(lines[i]))  continue;

	/* Special handling of an address.
	 * Find the end, then pass it off to the address_block_parser...
	 */
	if(results[i] & P_FOUND_ASTART){
	    block = (char *)malloc(strlen(inbuf)*2+64);
	    block[0] = 0;

	    for(j=i; j<numLines;j++){
		if(results[i] & P_FOUND_AEND){
		    break;		// found the end
		}

		/* Add this line */
		if(j>i){
		    strncat(block,"\n",buflen);
		}
		strncat(block,lines[j],buflen);
		i = j;		    // this line has now been appended
	    }

	    /* Now add to vcard */
	    strncat(vcard,"ADR:",buflen);
	    if(label){
		strncat(vcard,"TYPE=",buflen);
		str_qcat(vcard,label,buflen);
		strncat(vcard,";",buflen);
	    }

	    /* If we can find a city, state and zip on the last line, then
	     * use that information and kill the last line.
	     * Otherwise, just put in in as a buffer
	     */

	    char *city=0;
	    char *state=0;
	    char *zip=0;
	    find_cityStateZip(lines[i],&city,&state,&zip);

	    if(city && state && zip){
		char *cc = strrchr(block,'\n');	// find where the last line ended
		
		if(cc){
		    *cc = '\000';
		    str_qcat(vcard,block,buflen);
		    strncat(vcard,";;;",buflen);
		    if(city) str_qcat(vcard,city,buflen);
		    strncat(vcard,";",buflen);

		    if(state)str_qcat(vcard,state,buflen);
		    strncat(vcard,";",buflen);

		    if(zip) str_qcat(vcard,zip,buflen);
		    strncat(vcard,"\n",buflen);
		}
		else {
		    if(city) free(city);
		    city = 0;		//  we couldn't put them on

		    if(state) free(state);
		    state = 0;

		    if(zip) free(zip);
		    zip = 0;
		}
	    }
	    
	    if(city==0 && state==0 && zip==0){
		/* just add the free-format text */
		str_qcat(vcard,block,buflen);
		strncat(vcard,";;;;;\n",buflen); // should be line0;line1;line2;city;state;zip
	    }
	    if(city)  free(city); city = 0;
	    if(state) free(state);state = 0;
	    if(zip)   free(zip);  zip = 0;
	    free(block);block = 0;
	    continue;
	}

	if(results[i] &  P_FOUND_LABEL){
	    if(label) free(label);
	    label = strdup(lines[i]);
	    cc = strchr(label,':');
	    if(cc) *cc = '\000';	// remove ':'
	}

	switch(results[i] & P_BUT_MASK){
	case P_BUT_EMAIL:
	    strncat2(vcard,"EMAIL;TYPE=INTERNET:",lines[i],buflen);
	    break;
	case P_BUT_LINK:
	    strncat2(vcard,"URL:",lines[i],buflen);
	    break;
	case P_BUT_TELEPHONE:
	    /* TK: pick out fax, etc. */
	    strncat2(vcard,"TEL;TYPE=VOICE:",lines[i],buflen);
	    break;
	default:
	    strncat2(vcard,"NOTE:",lines[i],buflen);
	    break;

	}
    }

    if(label){
	free(label);
	label = 0;
    }
	
 done:;

    free_block(lines,results);
}
