/*
 * (C) Copyright 2002 Simson L. Garfinkel.
 * All rights reserved.
 * 
 * Parse some text.
 */


#include "libsbook.h"
#include <stdio.h>
#include <ctype.h>

int sbook_parser_debug=0;

/*
 * identify_line():
 * Run the line through the flex identifiers
 */
extern "C"
unsigned int identify_line(const char *line)
{
    int res = 0;
    
    if(onlyBlankChars(line)){
	return P_BLANKLINE;
    }

    if(strlen(line)>80){
	return res;			// not much to say; it's too long
    }

    res |= parse_address(line);
    res |= parse_email(line);
    res |= parse_telephone(line,0);
    res |= parse_case(line);
    res |= parse_time(line,0);
    res |= parse_extra(line);

    if(res & P_NOT_TELEPHONE){
	res &= ~P_TELEPHONE;		/* remove phone */
    }

    /* fix the bug with Office */
    if(res & P_OFFICE &&
       res & P_TELEPHONE){
	res	&= ~P_ADDRESS;
	res	|= P_TELEPHONE;
    }

    return res;
}

/*
 * parse_lines:
 * parses a block of lines. Returns an array of where buttons should be
 * Need to add - don't parse after blank line, don't parse bold, don't parse itallic
 */

extern "C"
void parse_lines(unsigned int numLines,
		 const char * const *lines,
		 void *atoms_,
		 const int unsigned * attributes,
		 unsigned int *results,
		 unsigned int parseControlFlag,
		 unsigned int entryFlags)
{
    unsigned int i=0;
    NXAtomList *atoms  = (NXAtomList *)atoms_;
    NXAtomList *atoms0 = 0;

    if(numLines==0) return;		// not much to do

    /* Erase the results */
    for(i=0;i<numLines;i++){
	results[i] = 0;
    }

    if(parseControlFlag & SLIST_DONT_PARSE_ANYTHING){
	return;
    }

    if((entryFlags & ENTRY_FLAGS_SET) && !(entryFlags & ENTRY_SHOULD_PARSE_FLAG)){
	return;				// this entry should not be parsed
    }

    assert(lines[0]!=0);

    /* Make a temp space */

    int *temp = (int *)calloc(sizeof(int),numLines+1);

    /* Find out if this is a person or company.
     * For this, we need an atomsList. If we weren't given one, create it.
     */

    if(atoms==0){
	atoms0 = atomsForNames(lines[0]);
	atoms  = atoms0;
    }
    int isPerson;
    smartSortName(lines[0],entryFlags,*atoms0,&isPerson);
    results[0] = isPerson ? P_BUT_PERSON: P_BUT_COMPANY;

    if(atoms0){				// delete if we allocated
	delete atoms0;
    }
    atoms = 0;				// and do not use atoms after this
    

    /* Run identify line on each */
    for(i=1;i<numLines;i++){
	temp[i] = identify_line(lines[i]);

	if(sbook_parser_debug){
	    fprintf(stderr,"temp[%d] = identify_line(%s) = 0x%x\n",i,lines[i],temp[i]);
	}
	results[i] = 0;
    }



    /* Previously, we simply killed a telephone flag if it was on the same line as an
     * address flag. Now we kill the telephone flag if it is on the same line as
     * and address flag if the following line is not blank.
     */
    for(i=0;i<numLines;i++){
	if((temp[i] & P_ADDRESS)
	   && !(temp[i] & P_WEAK)
	   && i<numLines-1
	   && (temp[i+1] & P_BLANKLINE)==0){
	    temp[i] &= ~P_TELEPHONE;
	}
    }


    /* Now scan and parse... */
    for(i=1;i<numLines;i++){
	/* Handle attributes */
	if(attributes){
	    if(parseControlFlag & (SLIST_DONT_PARSE_ITALIC|SLIST_DONT_PARSE_BOLD)){
		if((attributes[i] & P_ATTRIB_BOLD)
		   && (parseControlFlag & SLIST_DONT_PARSE_BOLD)) continue;

		if((attributes[i] & P_ATTRIB_ITALIC)
		   && (parseControlFlag & SLIST_DONT_PARSE_ITALIC)) continue;
	    }
	}

	/* Look at label; it is not exclusive */
	if(temp[i] & P_LABEL){
	    results[i] |= P_FOUND_LABEL;
	}

	/* These are exclusive */
	if(temp[i] & P_TELEPHONE){
	    results[i] = (results[i] & ~P_BUT_MASK) | P_BUT_TELEPHONE;
	    continue;
	}

	/* Check URL before EMAIL because sometimes URLs have Email addresses */
	if(temp[i] & P_URL){
	    results[i] = (results[i] & ~P_BUT_MASK) | P_BUT_LINK;
	    continue;
	}

	if(temp[i] & P_EMAIL){
	    results[i] = (results[i] & ~P_BUT_MASK) | P_BUT_EMAIL;
	    continue;
	}

	if(temp[i] & P_IM){
	    results[i] = (results[i] & ~P_BUT_MASK) | P_BUT_IM;
	    continue;
	}

	if(temp[i] & P_FILE){
	    results[i] = (results[i] & ~P_BUT_MASK) | P_BUT_FILE;
	    continue;
	}

	if((temp[i] & P_BLANKLINE) && (parseControlFlag & SLIST_DONT_PARSE_AFTER_BLANK)) break;

	/* Hm... Haven't identified this line.  Could be address
	 * or blank.
	 *
	 * Scan for the last line that is either blank or address in
	 * this block.  Then, if two lines are addresses, delcare this
	 * an address...
	 */
	{
	    float alines=0;
	    unsigned int ziplines=0;
	    unsigned int countryLine=0;
	    unsigned int stateCountry=0;
	    unsigned int countlines=0;
	    int	dirlines = 0;
	    int datecount = 0;
	    unsigned int j,k;

	    for(j=i;j<numLines;j++){
		int mr = results[i] & P_BUT_MASK;
		int flag = temp[j];
		int not_address = 0;

		/* CHECK FOR THINGS WHICH MAKE IT NOT AN ADDRESS */
		if(strlen(lines[j])>60){
		    not_address = 1;
		}
		if(flag & (P_NOT_ADDRESS|P_NAME|P_TELEPHONE|
			   P_EMAIL|P_LABEL|P_BLANKLINE|P_URL)){
		    not_address = 1;
		}
		
		if(mr==P_BUT_EMAIL||
		   mr==P_BUT_TELEPHONE||
		   mr==P_BUT_LINK||
		   mr==P_BUT_PERSON||
		   mr==P_BUT_COMPANY ||
		   mr==P_BUT_IM ){
		    not_address = 1;
		}
		
		if(not_address){
		    j--;
		    break;			/* not address or blank */
		}
		countlines++;
		if(flag & P_ZIP)	ziplines++;
		if(flag & P_COUNTRY)	countryLine = j;
		if(flag & (P_STATE|P_COUNTRY))	stateCountry = j;
		if(flag & P_DIRECTIONS)	dirlines++;
		if(flag & P_ADDRESS) 	alines += 1.0;
		if(flag & P_DATE)	datecount++;
	    }
#if 1
	    if(dirlines<2 && datecount<3){		// make sure we are not in a directions or date block
		if(((countryLine>i) && (countlines>2))
		   || ((stateCountry==j) && (countlines>2))
		   || alines>1
		   || (alines==1 && ziplines==1)
		   || (alines && countlines==2 && dirlines==0)){

#if 0
		    printf("countryLine=%d  stateCountry=%d alines=%f "
			   "ziplines=%d dirlines=%d countlines=%d\n",
			   countryLine,stateCountry,alines,ziplines,
			   dirlines,countlines);
		    printf("adding address to %d (j=%d)\n",i,j);
#endif
		    for(k=i;k<=j && k<numLines;k++){
			assert(k<numLines);
			results[k] = P_BUT_ADDRESS;
		    }
		    if(i>=numLines) i = numLines-1;
		    if(j>=numLines) j = numLines-1;

		    assert(i<numLines);
		    assert(j<numLines);
		    results[i] |= P_FOUND_ASTART;
		    results[j] |= P_FOUND_AEND;
		}
	    }
	    if(j>i) i = j;
#endif
	}
    }
    free(temp);  
}


extern "C"
void	extract_label(const char *line,char *label)
{
    const char *cc = line;
    label[0] = 0;			// start with an empty string

    while(*cc && isspace(*cc)) cc++;
    if(*cc == 0) return;
    while(*cc && (*cc != ':')){
	*label++ = *cc++;
    }
    *label = 0;			// null terminate
}

extern "C"
void		parse_block(const char *buf_,char ***lines_,unsigned int **results_,
			    unsigned int *numLines_,unsigned int parseControlFlag,unsigned int entryFlags)
{
    char *buf = strdup(buf_);		// make private copy
    char **lines = (char **)malloc(sizeof(char *)); // allocate space for line pointer
    unsigned int  numLines = 0;			// start off with one line.
    char *cc = buf;

    /* Now seed the first line */
    numLines = 1;
    lines[0] = buf;

    /* Now see if we can find other lines */
    do {
	if(cc[0]=='\n'){	// if end of the string
	    cc[0] = '\000';		// terminate the string
	    if(cc[1]!='\000'){		// if more, start another line
		lines = (char **)realloc(lines,sizeof(char *) * (numLines+1));
		assert(lines!=0);
		lines[numLines] = cc+1;
		numLines++;
	    }
	}
	cc++;
    } while(cc[0]!='\000');

    *results_ = (u_int *)calloc(numLines,sizeof(int));
    *lines_ = lines;
    *numLines_ = numLines;
    assert(lines[0]!=0);
    parse_lines(numLines,(const char **)lines,0,0,*results_,parseControlFlag,entryFlags);
}

extern "C"
void		free_block(char **lines,unsigned int *results)
{
    free(lines[0]);
    lines[0] = 0;
    free(lines);
    free(results);
}


