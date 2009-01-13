/*
 * libsbook.h
 * Copyright (C) 1992, 1992, 2000 Simson L. Garfinkel
 * All rights reserved.
 *
 * The SBook matching routines
 */


#ifndef _LIBSBOOK_H
#define _LIBSBOOK_H

/* Entry flags */
#define ENTRY_FLAGS_SET				0x01 // this entry has flags
#define ENTRY_LOCKED_FLAG			0x02
#define ENTRY_SHOULD_PARSE_FLAG			0x04 // parse this entry
#define ENTRY_NEEDS_TEMPLATE_APPLIED_FLAG	0x08
#define ENTRY_PRIVATE_FLAG			0x10 // don't sync it
#define ENTRY_DIAL_EXACT_FLAG			0x20 // dial the items exactly!
#define ENTRY_ME_FLAG			        0x40 // !
#define ENTRY_FORCE_MASK                      0x0700 // Mask for forced
#define ENTRY_FORCE_PERSON		      0x0100 // force to be a person
#define ENTRY_FORCE_COMPANY		      0x0200 // force to be a person
#define ENTRY_DELETED_FLAG		      0x1000 // this entry was deleted

#define ENTRY_SMART_SORT_TAG			1001 /* sort key; not hex */


/* Parse flags/ List flags */
#define	SLIST_DONT_PARSE_ITALIC			0x0001
#define SLIST_DONT_PARSE_BOLD			0x0002
#define SLIST_DONT_PARSE_ANYTHING		0x0004
#define SLIST_DONT_PARSE_AFTER_BLANK		0x0008
#define SLIST_PARSE_FLAGS			0x000F

#define	SLIST_DIAL_EXACT_FLAG			0x0010
#define SLIST_DIAL_BOLD_EXACT_FLAG		0x0020
#define SLIST_SORT_FLAG				0x0040
#define SLIST_ENCRYPTED_FLAG			0x0080
#define SLIST_SPLIT_VERTICAL_FLAG		0x0100
#define SLIST_AUTOSYNC_FLAG			0x0200


/* search modes */
#define SEARCH_AUTO		0
#define SEARCH_WORD_MATCH	1
#define SEARCH_FULL_TEXT	2
#define SEARCH_PHONETIC		3

#define TAB_DELIM 1
#define CSV_DELIM 2



#include "nxatom.h"
#include <sys/types.h>
#include <time.h>


/* match.h */
#ifdef __cplusplus

#include <string>
#include <map>
#include <list>
#include <vector>
typedef std::string sstring;		// sstring is the SBook string type


#include "entry.h"
#include "entrylist.h"

#define EXTERN_C extern "C" {
#define EXTERN_C_END }
#else
#define EXTERN_C 
#define EXTERN_C_END
#endif

extern long nxatom_from_cache;
extern long nxatom_alloc;


EXTERN_C
/* match.cpp */
int	isInnerCap(const char *str);
int	isRomanOrTitle(const char *str);
int	onlyBlankChars(const char *str);
int	isOnlyDigits(const char *str);
EXTERN_C_END

int	compareAtoms(NXAtom a1,NXAtom a2); // for sorting

#ifdef __cplusplus
int	compareAtomLists(NXAtomList *l1,NXAtom sortName1, // for sorting entries
			 NXAtomList *l2,NXAtom sortName2);
bool	sbookIncrementalMatch(NXAtomList *l1,NXAtomList *mlist);
bool	sbookIncrementalMatch(NXAtomList *l1,const char *str);
NXAtomList *metaphonesForNames(const char *str);
NXAtomList *atomsForNames(const char *str,bool keepDots=false);	// if keepDots==true, keep the dots

/* first line parsing ---
 * Take the line, break it into atoms, tell us if it a person or not.
 */

/* smartsort.cpp */

NXAtom	   smartSortName(const char *theLine,int entryFlag,
			 const NXAtomList &atoms,int *isPerson);
#endif

/* smartsort.cpp */
int	smartsort_iscorp(const char *line);
const char *wordBeforeComma(const char *theLine);
int     hasCommaBeforeSpace(const char *str,unsigned *loc);




/* end of match.cpp */



// Parser results
// These are decisions that the parser makes. They get turned into buttons
// Only one button can be on a result. They are not bitfields
// They can be stored in the SBook XML file
// Button decisions are made by the sbook_parse.cpp file.

#define P_BUT_MASK	(unsigned)0x0000000f
#define P_BUT_EMAIL	(unsigned)0x00000001
#define P_BUT_ADDRESS	(unsigned)0x00000002 // puts on every line of the address
#define P_BUT_TELEPHONE	(unsigned)0x00000003
#define P_BUT_LINK	(unsigned)0x00000004 // www links
#define P_BUT_PERSON	(unsigned)0x00000005
#define P_BUT_COMPANY	(unsigned)0x00000006
#define P_BUT_TASK_DO   (unsigned)0x00000007
#define P_BUT_TASK_DONE (unsigned)0x00000008
#define P_BUT_IM	(unsigned)0x00000009
#define P_BUT_FILE	(unsigned)0x0000000a
#define P_BUT_MAX	(unsigned)0x0000000b // maximum button number+1

// These results are not part of the mask, but are bitfields

#define P_FOUND_ASTART    (unsigned)0x00000100 // start of the address
#define P_FOUND_AEND      (unsigned)0x00000200 // end of the address
#define P_FOUND_LABEL	  (unsigned)0x00000400 // a label

/* Passed in attributes for parsing */
#define P_ATTRIB_BOLD	          0x0001
#define P_ATTRIB_ITALIC	          0x0002
#define P_ATTRIB_FLAGS		  0x0007



//
//	Parser flags
//
#define P_TELEPHONE		       0x001 
#define P_EMAIL 		       0x002 
#define P_LABEL			       0x004 
#define P_ZIP			       0x008 
#define P_BLANKLINE		       0x010
#define P_ADDRESS		       0x020
#define P_NOT_ADDRESS                  0x040
#define P_WEAK			       0x080		/* not as strong; ignore P_ADDRESS as corp if weak */
#define P_COUNTRY		       0x100
#define P_CITY			       0x200		/* a state or country abbreviation */
#define P_STATE			       0x400
#define P_DATE			       0x800	        /* a date, not a phone */
#define P_DIRECTIONS		      0x1000		/* probably directions, not definate */
#define P_STREET		      0x2000  
#define P_ORG			      0x4000		/* looks like an organization */
#define P_NEWS			      0x8000		/* north, south, east or west */
#define P_OFFICE		     0x10000		/* office, company, one of those names */
#define P_NAME			     0x20000
#define P_NOT_TELEPHONE		     0x40000
#define P_URL	                     0x80000	        /* written post-1993 */
#define P_COMPANY		    0x100000  // definately a company
#define P_NOT_COMPANY	            0x200000  // definately not a company
#define P_TITLE                     0x400000  // Looks like a person's job title */
#define P_FIRST_NAME		    0x800000 // looks like a first name
#define P_IM			   0x1000000 // looks like an IM address
#define P_FILE			   0x2000000 // looks like an IM address


/* internal functions */
unsigned int	parse_address(const char *buf);
unsigned int	parse_email(const char *buf);
unsigned int	parse_telephone(const char *buf,unsigned int *arg);
unsigned int	parse_case(const char *buf);
unsigned int	parse_extra(const char *buf);
int		parse_month(const char *buf);
unsigned int	parse_time(const char *buf,struct tm *tm);

/* IM brands */
#define P_IM_AIM          1
#define P_IM_Jabber       2
#define P_IM_MSN          3
#define P_IM_ICQ          4
#define P_IM_Yahoo        5



unsigned int	parse_company0(const char *buf); // just do the parse company
int	parse_stocks(const char *buf);	// all the stocks; returns stock number, neg for weak number
unsigned int	parse_company(const char *buf);	// both company and stocks - return true if we think it's a company

extern unsigned int pt_debug;

// returns start of zip code if contains 00000 or 00000-1111

/* Higher-level things */

/* sbook_parser.cpp */

EXTERN_C
extern int	sbook_parser_debug;
unsigned int    identify_line(const char *buf);
void		parse_lines(unsigned int numLines,
			    const char * const *lines,
			    void *atoms, // may be 0, which causes it to be allocated; NXAtomList *
			    const unsigned int *attributes, 
			    unsigned int *results,
			    unsigned int parseControlFlag,
			    unsigned int entryFlags);
void	extract_label(const char *line,char *label); // copies the label from line to label;
                                                     // label must be large enough to hold it

/* Allocates a block and parses it */
void	parse_block(const char *buf,char ***lines,unsigned int **results,
		    unsigned *numLines,unsigned int parseControlFlag,unsigned int entryFlags);
void	free_block(char **lines,unsigned int *results); // free the block
/* end of sbook_parser.cpp */



/* vcard.cpp */
void str_init();
int  str_freeall();
int  str_alloc(const char *strbuf);
int  str_allocq(const char *strbuf);
int  vcardparse();
const char *str_num(int i);
extern int vcardlex();
extern void vcarderror(const char *buf);
extern int vcard_lval;

void parse_block_to_vcard(const char *inbuf,unsigned int entryFlags,
			  char *vcardbuf,unsigned int vcard_buflen);	
struct sbook_creator {
    char *person_data;
    char *gid;
};
void	parse_vcards(FILE *infile,void (*create)(struct sbook_creator *));

EXTERN_C_END



#ifdef __cplusplus
extern "C" {
#endif
#ifdef NEVER_DEFINED
}
#endif
	
void	find_cityStateZip(const char *buf,char **city,char **state,char **zip);
const char *find_zip(const char *buf,int *len);

#ifdef NEVER_DEFINED
{
#endif
#ifdef __cplusplus
}
#endif

#include "fakecocoa.h"

#ifdef __cplusplus
sstring *stringForB64SString(const sstring &str);
sstring *b64stringForSString(const sstring &str);

inline NSRect	NSRectFromSString(const sstring &str) {
    NSRect r;
    memset(&r,0,sizeof(r));
    sscanf(str.c_str(),"{{%g, %g}, {%g, %g}}",&r.origin.x,&r.origin.y,&r.size.width,&r.size.height);
    return r;
}
#endif



#endif
