%{
//
// Copyright (C) 1991, 1992, 2000,2001,2002,2003,2004 Simson L. Garfinkel
// All rights reserved.
// telephone & AIM parser
//

#include "libsbook.h"
#include "flexhdr.h"

#define yytelephonewrap() 0

static	unsigned int	aflag=0;
static	unsigned int	arg=0;
unsigned int pt_debug=0;

%}

%option noyywrap
%option 8bit
%option batch
%option case-insensitive
%option pointer
%option prefix="yytelephone"


S	[ \-\001.]{1,2}
H	[a-zA-Z0-9\.\-_=+]
W	[ ][A-Z]+[ ]+
END	[^a-zA-Z]
P	[., ]
N	[0-9]
N12	[0-9]{1,2}
N123	[0-9]{1,3}
N1234	[0-9]{1,4}
N2	[0-9][0-9]
N23	[0-9]{2,3}
N24	{N2}{N2}?
N3	[0-9]{3}
N4	[0-9]{4}
N5	[0-9]{5}
N6	[0-9]{6}
N9	[0-9]{9}
USZIP	{N}{5}(-{N4})?

%%


\(AIM\)" "*\032				{aflag|=P_IM; arg= P_IM_AIM;}
\(Jabber\)" "*\032			{aflag|=P_IM; arg= P_IM_Jabber;}
\(MSN\)" "*\032				{aflag|=P_IM; arg= P_IM_MSN;}
\(ICQ\)" "*\032				{aflag|=P_IM; arg= P_IM_ICQ;}
\(Yahoo\)" "*\032			{aflag|=P_IM; arg= P_IM_Yahoo;}

\001" "AIM:" "				{aflag|=P_IM; arg= P_IM_AIM;}
\001" "Jabber:" "			{aflag|=P_IM; arg= P_IM_Jabber;}
\001" "MSN:" "				{aflag|=P_IM; arg= P_IM_MSN;}
\001" "ICQ:" "				{aflag|=P_IM; arg= P_IM_ICQ;}
\001" "Yahoo:" "			{aflag|=P_IM; arg= P_IM_Yahoo;}



 /* Rooms are not phone numbers */
[rR][oO][oO][mM]			{aflag|=P_NOT_TELEPHONE;}

 /* ISBN numbers are not phone numbers */
"ISBN"					{aflag|=P_NOT_TELEPHONE;} 

 /* Japan is special */
(Tokyo|Japan)" "+{N3}"-"{N4}		{aflag|=P_NOT_TELEPHONE|P_ADDRESS;} 

 /* serial numbers are not telephones */
{S}(sn|serial|prop|property)[ #:]{1,3}[A-Z0-9]{2}	{aflag |= P_NOT_TELEPHONE|P_NOT_ADDRESS;} 
{S}(sn|serial|prop|property)		{aflag |= P_NOT_TELEPHONE;} 
{S}(s#)					{aflag |= P_NOT_TELEPHONE;} 
{S}employee" "?"#"			{aflag |= P_NOT_ADDRESS;}
{S}library" "card" "?"#"		{aflag |= P_NOT_ADDRESS;}

 /* Some activation code pattern */
{S}[0-9]{2}"-"[0-9]{4}"-"[0-9]{9}/{END}	{aflag |= P_NOT_TELEPHONE;} 


 /* Money is not serial numbers */
[$][0-9][0-9]*				{aflag|=P_NOT_TELEPHONE;}

  /* credit card numbers are not telephones */
{N4}[ \-]{N4}[ \-]{N4}[ \-]{N4}	{aflag |= P_NOT_TELEPHONE; /* credit-card numbers are not phones */}
{S}VISA/{END}				{aflag |= P_NOT_TELEPHONE;}
{S}MC/{END}				{aflag |= P_NOT_TELEPHONE;}
{S}Eurocard/{END}			{aflag |= P_NOT_TELEPHONE;}
{S}American{S}?Express/{END}		{aflag |= P_NOT_TELEPHONE;}

 /* SSNs are not telephoens */
{S}{N3}"-"{N2}"-"{N4}/{END}		{aflag |= P_NOT_TELEPHONE;}

 /* George's bank account is not a telephone number */
{S}{N4}" "{N6}/{END}			{aflag |= P_NOT_TELEPHONE;}

\001{N12}\/{N12}\/{N24}			{aflag |= P_DATE;}

{N24}"-"{N24}{S}{N}{3,5}		{aflag |= P_TELEPHONE;} /* 3/27/2002 */


[^0-9]{N}{3}[- ./]({N4})[^0-9]		{aflag |= P_TELEPHONE;pt_debug=1;}

\001[ ]*"("{N}{3,}")"{S}+{N}+{S}+{N}+{S}{N}+{S}*\032		{aflag |= P_TELEPHONE;pt_debug=2;}
\001[ ]*"("{N}{3,}")"{S}+{N}{4,}{S}+{N}{4,}[0-9 ]*\032		{aflag |= P_TELEPHONE;pt_debug=2;}
"("{N}{2,4}")"{S}{1,2}{N2}{S}{1,2}{N23}{S}{1,2}{N23}		{aflag |= P_TELEPHONE;pt_debug=2;}


 /* Some UK formats */
{N5}" "{N3}" "{N3}			{aflag |= P_TELEPHONE;pt_debug=2;}

 /* Special phone numbers in Austrilia */
[^0-9]"13"{N}" "{N3}[^-9]		{aflag |= P_TELEPHONE;pt_debug=2;}

\001[ ]*{N}{3,}[- ,./*]{N}{4,}[ ]*\032	 {aflag |= P_TELEPHONE;pt_debug=2;}
\001[ ]*[(]?"+"[)]?{N}+"-"{N}+[- '.]{N}+ {aflag |= P_TELEPHONE;pt_debug=3;} /* 3-29-94 */
\001[ ]*[(]?"+"[)]?({N2}[- '.]){4,6}	 {aflag |= P_TELEPHONE;pt_debug=4;} /* 3-29-94 */
\001[ ]*"+"{N2}[- ']{N3}[- ']{N3}	 {aflag |= P_TELEPHONE;pt_debug=5;} /* 3-29-94 */

\001[ ]*"+"?{N}[0-9\-\. ]{7,}{N2}\032		{aflag |= P_TELEPHONE;pt_debug=6;} /* 2002-03-01 - kind of a catch-all intl telephone */
\001[ ]*"["{N123}"]"[[0-9\-\. ]{8,}\032	{aflag |= P_TELEPHONE; pt_debug=7;} /* 2002-03-01 - another catch-all intl telephone */
\001[ ]*"+"{N123}"-"{N1234}[ -]	{aflag |= P_TELEPHONE; pt_debug=7;} /* another intl */

({N2}[ ']){4}					{aflag |= P_TELEPHONE; pt_debug=8;} /* 3-29-94 */
[^0-9][0-9A-Z][0-9A-Z]{N}[\- .]{N4}[^0-9]	{aflag |= P_TELEPHONE;pt_debug=9;} /* 3-1-02 */
[^0-9][0-9A-Z][0-9A-Z]{N}" - "{N4}[^0-9]	{aflag |= P_TELEPHONE;pt_debug=10;} /* 3-1-02 */
[ xX]{N12}-{N3}					{aflag |= P_TELEPHONE;pt_debug=11;} /* 3-1-02 */
{N4}[ ]*"ext"[. ]*{N2}			{aflag |= P_TELEPHONE;pt_debug=12;}

\001[ ]*"x"[ ]*{N}{2,}[ ]*\032		{aflag |= P_TELEPHONE;pt_debug=13;} /* 2002-03-01 - lines with just extensions */

"+"{N2}{S}+"("{N}+")"{S}+{N4}		{aflag |= P_TELEPHONE;pt_debug=14;} /* 2002-02-14 */
"+"{N2}{S}+{N4}				{aflag |= P_TELEPHONE;pt_debug=15;} /* 2002-02-14 */
"+"{S}?{N123}[ .\-][0-9 \.\-]{8}	{aflag |= P_TELEPHONE;pt_debug=16;} /* 2002-03-02 */
{N3}"/"{N3}.{N4}			{aflag |= P_TELEPHONE;pt_debug=17;} /* 2002-02-14 */

{S}"("{N}+")"{S}*{N}{3,}{S}+{N}{3,}	{aflag |= P_TELEPHONE;pt_debug=18;} /* 2002-03-19 */

{S}"("{N4}")"{S}?{N2}{S}{N2}{S}*\032	{aflag |= P_TELEPHONE;pt_debug=23;} /* Germany */
{S}"("{N4}")"{S}?{N3}{S}{N3}/{END}	{aflag |= P_TELEPHONE;pt_debug=23;} /* Australia */
{S}"("{N2}")"{S}?{N4}{S}{N4}/{END}	{aflag |= P_TELEPHONE;pt_debug=20;} /* Australia */
{S}{N2}{S}{N4}{S}{N4}/{END}		{aflag |= P_TELEPHONE;pt_debug=21;} /* Australia */
{S}{N4}{S}{N3}{S}{N3}/{END}		{aflag |= P_TELEPHONE;pt_debug=22;} /* Australia */
{S}{N4}{S}{N4}/{END}			{aflag |= P_TELEPHONE;pt_debug=19;} /* Australia */
{S}"13"{N}" "{N3}/{END}			{aflag |= P_TELEPHONE;pt_debug=13;} /* Australia */

{S}"("{N123}")"({S}*){N}{3,}{S}?{N}{2,}[0-9\- \.\/]*\032	{aflag |= P_TELEPHONE;pt_debug=24;} /* 2002-03-01 friendly Germany */

{S}Fon[\-+:0-9. ()/]{4,}*\032			{aflag |= P_TELEPHONE;}
{S}Mobile[\-+:0-9. ()/]{4,}*\032		{aflag |= P_TELEPHONE;}
{S}Fax[\-+:0-9. ()/]{4,}*\032		{aflag |= P_TELEPHONE;}



 /* Belgim numbers follow */
{S}{N2}"-"{N3}"."{N2}"."{N2}/{END}	 {aflag |= P_TELEPHONE;}
{S}{N4}"-"{N2}"."{N2}"."{N2}/{END}	 {aflag |= P_TELEPHONE;}
{S}{N4}"-"{N2}"-"{N2}"-"{N2}/{END}	 {aflag |= P_TELEPHONE;}
{S}{N2}"/"{N3}"."{N2}"."{N2}/{END}	 {aflag |= P_TELEPHONE;}
{S}{N2}"."{N2}"."{N2}"."{N2}"."{N2}/{END} {aflag |= P_TELEPHONE;}

.						{} /* by default, ignore, but look for more stuff */

 /* Rowanda, believe it or not */
{N2}" "{N9}/{END}			{aflag |= P_TELEPHONE;}
{N2}" "{N3}" "{N6}/{END}		{aflag |= P_TELEPHONE;}

%%


unsigned int	parse_telephone(const char *buf,unsigned int *arg_)
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
	arg	= 0;

	PSETUP(mbuf,strlen(mbuf));
	yylex();		/* Do it! */
	PSHUTDOWN;
	if(arg_) *arg_ = arg;

	return aflag;
}



