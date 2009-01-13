%{
//
// Copyright (C) 1991, 1992, 2000,2001,2002 Simson L. Garfinkel
// All rights reserved.
// email  parser
//
#include "libsbook.h"
#include "flexhdr.h"

static	unsigned int	aflag=0;
unsigned int pe_debug=0;
%}

%option noyywrap
%option 8bit
%option batch
%option case-insensitive
%option pointer
%option prefix="yyemail"

N	[0-9]
S	[ \-\001]
H	[a-zA-Z0-9\.\-_=+]
W	[ ][A-Z]+[ ]+
END	[^a-zA-Z]
P	[., ]
USZIP	[0-9]{5}(-[0-9]{4})?
CANADAZIP	([a-z][0-9][a-z]" "[0-9][a-z][0-9])
CZECHZIP	([0-9]{3}[ ]?[0-9]{2})

UKZIPA	([A-Z][A-Z][0-9]([0-9]?)" "[0-9][A-Z]([A-Z]?))
UKZIPB	([A-Z][A-Z][0-9][0-9])
UKZIP	({UKZIPA}|{UKZIPB})


.
. "virginia" is not in the STATE below, as it needs to be P_WEAK
.

STATE	((alabama)|(alaska)|(arizona)|(arkansas)|(california)|(canal[ ]zone)|(colorado)|(connecticut)|(delaware)|(florida)|(georgia)|(guam)|(hawaii)|(idaho)|(illinois)|(indiana)|(iowa)|(kansas)|(kentucky)|(louisiana)|(maine)|(maryland)|(massachusetts)|(michigan)|(minnesota)|(minn)|(mississippi)|(missouri)|(montana)|(nebraska)|(nevada)|(new[ ]hampshire)|(new[ ]jersey)|(new[ ]mexico)|(new[ ]york)|(north[ ]carolina)|(north[ ]dakota)|(ohio)|(oklahoma)|(oregon)|(pennsylvania)|(penn)|(puerto[ ]rico)|(rhode[ ]island)|(south[ ]carolina)|(south[ ]dakota)|(tennessee)|(texas)|(utah)|(vermont)|(virgin[ ]islands)|(washington)|(west[ ]virginia)|(wisconsin)|(wyoming))
WEAK_STATE	(virginia)

PROVENCE	((Manitoba))

EMAIL	([a-z0-9]([_+a-z0-9\-])*)
EMAILWITHDOT	({EMAIL}([.]{EMAIL})*)

ISO	(ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cf|cd|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|fi|fj|fk|fm|fo|fr|fx|ga|gb|gd|ge|gf|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|in|io|iq|ir|is|it|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nt|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|pt|pw|py|qa|re|ro|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zr|zw)

GTLD	(com|edu|net|org|mil|biz|info|int|gov)
DOMAIN	({GTLD}|{ISO})

%%

{EMAILWITHDOT}"@"{EMAIL}\.{EMAIL}\.{EMAIL}	{aflag |= P_EMAIL;}
{EMAILWITHDOT}"@"{EMAIL}\.{EMAIL}	{aflag |= P_EMAIL;}
{EMAILWITHDOT}" @"{EMAIL}.com		{aflag |= P_EMAIL;}


.					{} /* by default, ignore, but look for more stuff */

%%

unsigned int	parse_email(const char *buf)
{
	char	*mbuf	= (char*)alloca(strlen(buf)+16);
	char	*cc;
	const	char *dd;

	cc	= mbuf;
	*cc++	= 1;			/* begin with control-a */
	*cc++	= ' ';			/* Put in a space */
	for(dd=buf;*dd;dd++,cc++){	/* Copy the data, just the low bits */
		*cc = *dd;
		if(*cc == '\t') *cc = ' ';  /* Turn tabs to spaces */
	}
	*cc++	= ' ';			/* Put a space at the end */
	*cc++	= 26;			/* end with a control-z */
	*cc++	= EOF;			/* Put in the EOF character */
	*cc++	= '\000';

	aflag	= 0;			/* what we found */

	/* initialize flex static variables */

	PSETUP(mbuf,strlen(mbuf));
	yylex();		/* Do it! */
	PSHUTDOWN;
	return aflag;
}



