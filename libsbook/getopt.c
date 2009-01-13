/*
 * UNIX getopt()
 * Modified for Sandstorm by Simson L. Garfinkel.
 */

#ifndef linux
#include "string.h"

/* @(#)getopt.c	1.1 87/07/06 3.2/4.3NFSSRC */
/* @(#)getopt.c	1.3 87/01/05 NFSSRC */

#undef NULL

#ifdef WIN32
#pragma warning( disable: 4210 )
#pragma warning( disable: 4244 )
#endif

/*LINTLIBRARY*/
#define NULL	0
#define EOF	(-1)
#define ERR(s, c)	if(opterr){\
	extern int write();\
	char errbuf[2];\
	errbuf[0] = c; errbuf[1] = '\n';\
	(void) write(2, argv[0], (unsigned)strlen(argv[0]));\
	(void) write(2, s, (unsigned)strlen(s));\
	(void) write(2, errbuf, 2);}

extern int strcmp();
#define SYSTEM_V
#ifdef SYSTEM_V
extern char *strchr();
#else
#define strchr index
extern char *index();
#endif 

int	opterr = 1;
int	optind = 1;
int	optopt;
char *optarg;

int	getopt(int argc, char * const *argv, const char *opts)
{
	static int sp = 1;
	register int c;
	register char *cp;

	if(sp == 1){
	    if(optind >= argc ||
	       argv[optind][0] != '-' || argv[optind][1] == '\0')
		return(EOF);
	    else if(strcmp(argv[optind], "--") == NULL) {
		optind++;
		return(EOF);
	    }
	}
	optopt = c = argv[optind][sp];
	if(c == ':' || (cp=strchr(opts, c)) == NULL) {
		ERR(": illegal option -- ", c);
		if(argv[optind][++sp] == '\0') {
			optind++;
			sp = 1;
		}
		return('?');
	}
	if(*++cp == ':') {
		if(argv[optind][sp+1] != '\0')
			optarg = &argv[optind++][sp+1];
		else if(++optind >= argc) {
			ERR(": option requires an argument -- ", c);
			sp = 1;
			return('?');
		} else
			optarg = argv[optind++];
		sp = 1;
	} else {
		if(argv[optind][++sp] == '\0') {
			sp = 1;
			optind++;
		}
		optarg = NULL;
	}
	return(c);
}
#endif 
