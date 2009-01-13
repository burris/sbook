/*
 * (C) Copyright 2001,2002 by Simson Garfinkel.
 *
 * All Rights Reserved.
 *
 */
#include <stdio.h>


/*
 * match.m:
 *
 */

#include "libsbook.h"
#include <ctype.h>
#include <string.h>
#ifdef WIN32
#include <malloc.h>
#endif

//#define DEBUG_SORT
//#define DEBUG_MATCH

static bool iswordchar[256];
static unsigned char mytoupper_[256];

static unsigned char mytoupper(char x)
{
    int i = (unsigned char)x;
    if(i>=0 && i<=255) return mytoupper_[i];
    return '?';
}

/* Return true if the word has an inner-cap */
extern "C" 
int isInnerCap(const char *str)
{
    unsigned int i;
    unsigned len = strlen(str);
    for(i=0;i<len-1;i++){
	if(islower(str[i]) && isupper(str[i+1])){
	    return true;
	}
    }
    return false;
}

/* Return true if the word looks like a title or roman numeral.
 * This should be replaced with something in flex.
 */
extern "C"
int isRomanOrTitle(const char *str)
{
    if(strcmp(str,"II")==0) return true;
    if(strcmp(str,"III")==0) return true;
    if(strcmp(str,"IV")==0) return true;
    if(strcmp(str,"V")==0) return true;
    if(strcmp(str,"VI")==0) return true;
    if(strcmp(str,"VII")==0) return true;
    if(strcmp(str,"VIII")==0) return true;
    if(strcmp(str,"IX")==0) return true;
    if(strcmp(str,"X")==0) return true;
    if(strcmp(str,"JR")==0) return true;
    if(strcmp(str,"SR")==0) return true;
    if(strcmp(str,"MD")==0) return true;
    if(strcmp(str,"DDS")==0) return true;
    if(strcmp(str,"ESQ")==0) return true;
    if(strcmp(str,"DVM")==0) return true;
    if(strcmp(str,"PHD")==0) return true;
    if(strcmp(str,"PhD")==0) return true;
    if(strcmp(str,"USA")==0) return true;
    if(strcmp(str,"USN")==0) return true;
    if(strcmp(str,"USCG")==0) return true;
    if(strcmp(str,"USAF")==0) return true;
    if(strcmp(str,"USMC")==0) return true;
    return false;
}


extern "C"
int onlyBlankChars(const char *str)
{
    if(str==0) return true;		// by definition
    while(*str){
	if(!isspace(*str)) return false;
	str++;
    }
    return true;
}

extern "C"
int isOnlyDigits(const char *str)
{
    while(*str){
	if(!isdigit(*str)) return false;
	str++;
    }
    return true;
}

static int wordchar_init = 0;
static void init_wordchar()
{
    int i;

    /* Build the wordchar array */
    memset(iswordchar,0,sizeof(iswordchar));
    for(i=0;i<256;i++){
	iswordchar[i] = isalnum(i);
    }
    iswordchar[(u_char)'\''] = true;
    iswordchar[(u_char)'*'] = true;
    
    for(i=192;i<=246;i++){ 
	iswordchar[i] = true;
    }
    for(i=248;i<=255;i++){
	iswordchar[i] = true;
    }
    
    /* Build on mytoupper array */
    memset(mytoupper_,0,sizeof(mytoupper_));
    for(i=0;i<128;i++){
	mytoupper_[i] = toupper(i);
    }
    for(i=192;i<224;i++){
	mytoupper_[i] = i;
	mytoupper_[i+32] = i;
    }
    
    wordchar_init = 1;
}

NXAtomList *atomsForNames(const char *str,bool keepDots)
{

    if(wordchar_init==0){
	init_wordchar();
    }

    NXAtomList *names   = new NXAtomList;
    
    bool inWord = false;
    int length = strlen(str);
    int i;
    int lastWordStart=0;

    for(i=0;i<length;i++){
	unsigned char cc = str[i];
	int   isWordChar = iswordchar[cc];

	if(cc=='.' && keepDots) isWordChar=true; // if we keepDots, the '.' keeps up in the 

	if(cc=='.' && !keepDots){		 // check for .COM, .NET, .ORG, .GOV, .EDU
	    char buf[5];
	    strncpy(buf,str+i,4);

	    for(int i=0;i<4;i++){
		buf[i] = mytoupper(buf[i]);
	    }
	    buf[4] = 0;
	    if(strcmp(buf,".COM")==0 ||
	       strcmp(buf,".NET")==0 ||
	       strcmp(buf,".ORG")==0 ||
	       strcmp(buf,".GOV")==0 ||
	       strcmp(buf,".EDU")==0
	       ){
		isWordChar=true;
	    }
	}


	if(inWord==false && isWordChar){
	    lastWordStart = i;
	    inWord = true;
	}
	if(inWord==true && ((i==length-1) || !isWordChar)){
	    char *buf = (char *)malloc(length+1);

	    if(buf){
		int len = i-lastWordStart + (isWordChar?1:0);
		
		for(int j=0;j<len;j++){
		    buf[j] =mytoupper( str[lastWordStart+j] );
		}
		buf[len] = 0;
		
		names->append(NXUniqueString(buf));
		free(buf);
	    }
	    else{
		fprintf(stderr,"match: cannot allocate %d bytes\n",length+1);
	    }
	    inWord = false;
	}
    }
    return names;
}
	

/* Compare two atoms, doing a numeric comparison, and if that doesn't work,
 * doint a regular string comparison.
 */

int compareAtoms(NXAtom a1,NXAtom a2)
{
    if(isOnlyDigits(a1)==false || isOnlyDigits(a2)==false){
	return strcmp(a1,a2);
    }

    int i1 = atoi(a1);
    int i2 = atoi(a2);

    if(i1<i2) return -1;
    if(i1>i2) return 1;
    return 0;
}

/*
 * for comparing two entries
 */
int compareAtomLists(NXAtomList *l1,NXAtom sortName1,
		     NXAtomList *l2,NXAtom sortName2)
{
#ifdef DEBUG_SORT
    printf("compareAtomLists(%d,'%s',%d,'%s')\n",l1->count(),sortName1,l2->count(),sortName2);
#endif    



    unsigned int numAtoms1 = l1->count();
    unsigned int numAtoms2 = l2->count();

    if(numAtoms1==0) 	return -1;
    if(numAtoms2==0)	return 1;

    /* See if we can figure it out from the first atoms */

    if(isOnlyDigits(sortName1) && isOnlyDigits(sortName2)){
	int i1 = atoi(sortName1);
	int i2 = atoi(sortName2);

	if(i1<i2) return -1;
	if(i1>i2) return 1;
    }
    else{
	int comp = strcmp(sortName1,sortName2);
#ifdef DEBUG_SORT
	    printf("  strcmp(%s,%s)=%d  \n",sortName1,sortName2,comp);
#endif	    
	if(comp!=0){
	    return comp;
	}
    }

    /* Now go through each of the words in the word lists and compare them.
     * This used to skip over the sort key, but I'm not sure that is the right
     * thing to do anymore, so it doesn't do it. 
     */
    for(unsigned int i=0;i<numAtoms1 && i<numAtoms2;i++){
	NXAtom  a1 = (*l1)[i];
	NXAtom  a2 = (*l2)[i];
	int comp = compareAtoms(a1,a2);
#ifdef DEBUG_SORT
	printf("   compareAtoms(%s | %s)=%d\n",a1,a2,comp);
#endif	
	if(comp!=0) return comp;
    }
    return 0;
}

bool	sbookIncrementalMatch(NXAtomList *entry,NXAtomList *mlist)
{
    unsigned int i,j;

#ifdef DEBUG_MATCH
    fprintf(stderr,"sbookIncrementalMatch(");
    entry->print(stderr);
    fprintf(stderr," | ");
    mlist->print(stderr);
    fprintf(stderr,")\n");
#endif    

    bool *matchable	 = (bool *)alloca(sizeof(bool *)*(entry->count()));
    
    /* see if there is a match for each word in names
     */

    for(i=0;i<entry->count();i++){
	matchable[i] = true;
    }

    /* If only one atom in the match list has been provided,
     * first check for an match of initials, so "MIT" would match
     * "Massachusetts Institute of Technology"
     */
    if(mlist->count()==1){
	NXAtom M = (*mlist)[0];
	for( i = 0; M[i]; i++){
	    for( j = 0; j<entry->count();j++){
		if(matchable[j] && 
		   M[i] == (*entry)[j][0]){
		    matchable[j] = 0;	// matched
		    break;		
		}
	    }
	    if(j==entry->count()){	// No match was found
		goto step2;
	    }
	}
#ifdef DEBUG_MATCH
	fprintf(stderr,"  => ** initial match **\n");
#endif
	return true;
    }

    /* see if there is a match for each word in names
     */

 step2:;
    for(i=0;i<entry->count();i++){
	matchable[i] = true;
    }

    /*
     * The way this algorithm works: We search through for each atom
     * in the search list to see if it is match for the first N characters
     * of any of the entry in the ncopy list. If it isn't, we return NO, becuase
     * we didn't match. If it is, then we remove that name from the ncopy list
     * and we try again...
     */

    for ( i = 0; i < mlist->count(); ++i ) {
	NXAtom  I = (*mlist)[i];
	bool	matched	    = false;

	for( j = 0; j < entry->count() && matched==false; j++){
	    if(matchable[j]){
		NXAtom J = (*entry)[j];
		int k;

		for(k=0;I[k];k++){
		    if(I[k] != J[k]) break;	// doesn't match
		}
		if(I[k]==0){		  // if we got to the end
		    matched=true;		  // it matched
		    matchable[j] = 0;		  // don't match this name again
		    break;
		}
	    }
	}
	if(matched==false){
#ifdef DEBUG_MATCH
	    fprintf(stderr,"  => no match\n");
#endif	    
	    return false;
	}
    }
#ifdef DEBUG_MATCH
    fprintf(stderr,"  => ** matches **\n");
#endif
    return true;				  // each one must have matched.
}

bool	sbookIncrementalMatch(NXAtomList *entry,const char *str)
{
    NXAtomList	    *mlist= atomsForNames(str,false);   // match list

    bool	res = sbookIncrementalMatch(entry,mlist);
    delete mlist;
    return res;
}
