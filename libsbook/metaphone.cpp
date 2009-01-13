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

/*
**  Metaphone
**  Convert text into a metaphone form (similar to soundex)
**
**  Computer Language, December 1990  p.41
**  Converted from the original Pick BASIC to C by William Adams
**
**  Exceptions:
**	Initial  kn-, gn-, pn-, ae-, wr-		->	drop first letter
**	Initial  x					-> 	change to 's'
**	Initial  wh-					->	change to 'w'
**		This list is incomplete, but you can always looks
**		at the magazine article.  If you want to alter it to be more
**		accurate for a different language than english, go ahead.
*/
 
#include "libsbook.h"
#include <ctype.h>

#define METAPHLEN	4		/* length of a metaphone  */
 
static char *vowels = "AEIOU";		/*  regular vowels  */
static char *frontv = "EIY";		/* vowels when at the front of a word */
static char *varson = "CSPTG";		/* variable sound, changed by adding an 'h' */
 
static void strstripup(const char *p1,char *p2)
{
	for(;*p1;p1++){
		if(isalpha(*p1)){
			*p2++ = toupper(*p1);
		}
	}
	*p2 = '\0';
    
}
 
/*
**  Take a string 'name' and return the metaphone in 'metaph'
*/
char *metaphone(const char *name, char *metaph)
{
	char *ename = (char *)alloca(strlen(name)+16);
	char two[3];
	int len;
	int n,newm,silent,hard=0;
	char symb,symbuff[2];
	
	metaph[0]	= '\000';
	/* Delete non-alphanumeric characters and make all caps  */
	strstripup(name,ename);
	
	/* if the string is blank, return with metaphone empty  */
	if (!ename[0]){
		return "";
	}
 
	/* get the first two characters for testing  */
	strncpy(two,ename,2);
	two[2] = '\0';
	/* drop the first letter if necessary */
	if (!strcmp(two,"PN") || !strcmp(two,"AE") || !strcmp(two,"KN") ||
	    !strcmp(two,"GN") || !strcmp(two,"WR")){
		strcpy(ename,&ename[1]);
	}
	/* replace a leading 'x' with an 's'  */
	if (ename[0] == 'X'){
		ename[0] = 'S';
	}
	if (!strcmp(two,"WH")){
		char	*scratch = (char *)alloca(strlen(ename)+16);

		strcpy(scratch,ename+2);
		strcpy(ename+1,scratch);
	}
 
	/* convert to metaphone */
	len = strlen(ename);
	metaph[0] = '\0';
 	symbuff[1] = '\0';

	for (n=0;n<len &&(strlen(metaph) < METAPHLEN);n++){
		symb = ename[n];
		symbuff[0]=symb;
		if ((symb != 'C') && (n>1) && ename[n-1]==symb){
			newm = 0;
		}
		else {
			newm = 1;
		}
		if (newm) {
			switch (symb) {
			      case 'A':
			      case 'E':
			      case 'I':
			      case 'O':
			      case 'U':
				/* if it's a leading vowel then keep it. */
				if (n==0)
				  metaph[n] = symb;
				break;
 
			      case 'B':  /* trailing 'B' after 'M'  */
				if ((n == len-1)&&(ename[n-1] == 'M'))
				  silent = 1;
				else
				  silent = 0;
				if (!silent)
				  strcat(metaph,symbuff);
				break;
 
			      case 'C':
				if (!((n>0) && (ename[n-1] == 'S') && (n+1<= len-1)
				      && index(frontv,ename[n+1]))) {
					if ((n+2 <= len-1) && (ename[n+1] == 'I')
					    && (ename[n+2] == 'A'))
					  strcat(metaph,"S");
					else {
						if ((n<len-1) && index(frontv,ename[n+1]))
						  strcat(metaph,"S");
						else {
							if ((n>0) && (n<len-1)
							    && (ename[n+1] == 'H')
							    && (ename[n-1] =='S'))
							  strcat(metaph,"K");
							else {
								if ((n<len-1) &&
								    (ename[n+1] == 'H')) {
									if ((n==0)
									    && ((n+2) <= len-1)
									    && !index(vowels,ename[n+2] ))
									  strcat(metaph,"K");
									else
									  strcat(metaph,"X");
								}
								strcat(metaph,"K");
							}
						}
					}
				}
				break;
 
			      case 'D':
				if (((n+2) < len) && (ename[n+1] == 'G')
				    && index(frontv,ename[n+2]))
				  strcat(metaph,"J");
				else
				  strcat(metaph,"T");
				break;
 
			      case 'G':
                    // Silent for -gh-
		      if ((n < (len-1)) && (ename[n+1] == 'H') && (index(vowels,ename[n+2]) == 0))
		        silent = 1;
		    else
		        silent = 0;
	            // Silent for -gn, or -gned
		    if ((n>0) && (((n+1) == len-1) || ((ename[n+1] == 'N') && (ename[n+2] == 'E') &&
		        (ename[n+3] = 'D') && ((n+3) == len-1))))
		        silent = 1;
		    else
		        silent = 0;
            
                    // Silent for -dg<vowel>-
		    if ((n>0) && ((n+1)<=len-1) && (ename[n-1]=='D') && index(frontv,ename[n+1]))
		        silent = 1;
		    // Check for -gg-
		    if ((n>0) && (ename[n-1]=='G'))
		        hard = 1;
		    else 
		        hard = 0;
			
		    //  More stuff ...
		    if (!silent)
		    {
	                 if ((n < len-1) && index(frontv,ename[n+1]) && (!hard))
			     strcat(metaph,"J");
                         else
		             strcat(metaph,"K");
		    }
		break;
 
		case 'H':
		    if (!((n == len-1) || (n>0 && index(varson,ename[n-1]))))
			if (index(vowels,ename[n+1]))
			    strcat(metaph,"H");
		break;
 
		case 'F':
		case 'J':
		case 'L':
		case 'M':
		case 'N':
		case 'R':
		    strcat(metaph,symbuff);
		break;
 
		case 'K':
		    if (n>0 && ename[n-1] != 'C')
			strcat(metaph,"K");
		    else if (n==0)
			strcpy(metaph,"K");
		break;
 
		case 'P':
		    if (n < len-1 && ename[n+1] == 'H')
			strcat(metaph,"F");
		    else
			strcat(metaph,"P");
		break;
 
		case 'Q':
		    strcat(metaph,"K");
		break;
 
		case 'S':
		    if ((n>0) && (n+2 < len) && (ename[n+1] == 'I') &&
			((ename[n+2] =='O') || (ename[n+2] =='A')))
			    strcat(metaph,"X");
		    else 
		    {
		        if ((n < len-1) && (ename[n+1] == 'H'))
                             strcat(metaph,"X");
		        else
		            strcat(metaph,"S");
                      } 
		break;
 
		case 'T':
		    if ((n>0) && (n+2 < len) && (ename[n+1] == 'I') &&
			((ename[n+2] =='O') || (ename[n+2] =='A')))
			    strcat(metaph,"X");
		    else 
		    {
		        if ((n < len-1) && (ename[n+1] == 'H'))
                         {
		            if (!((n >0) && (ename[n-1] == 'T')))
			       strcat(metaph,"O");
                         } else if (!((ename[n+1] == 'C') && (ename[n+2] == 'H')))
		            strcat(metaph,"T");
                      }
		break;
 
		case 'V':
		    strcat(metaph,"F");
		break;
 
		case 'W':
		case 'Y':
		    if ((n<len-1) && index(vowels,ename[n+1]))
			strcat(metaph,symbuff);
		break;
 
		case 'X':
		    strcat(metaph,"KS");
		break;
 
		case 'Z':
		    strcat(metaph,"S");
		break;
	    }
	}
    }
    return metaph;
}
 
NXAtom	metaphoneName(const char *val)
{
	char	buf[256];

	if(val==0 || val[0]==0) return NXUniqueString("");
	memset(buf,0,sizeof(buf));
	metaphone(val,buf);
	return NXUniqueString(buf);
}

/* metaphonesForNames:
 * Find a list of atoms, then compute the metaphone for each.
 */

NXAtomList *metaphonesForNames(const char *str)
{
    unsigned int i;

    NXAtomList *res = atomsForNames(str,false);
    for(i=0;i<res->count();i++){
	(*res)[i] = metaphoneName((*res)[i]);
    }
    return res;
}

