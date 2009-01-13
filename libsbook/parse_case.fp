%{
//
//	Copyright (C) 1991, 1992, 2000, 2001, 2002, 2003 Simson L. Garfinkel
//	All rights reserved.
//
//	parse_case: the case-sensetive parser

#include "libsbook.h"
#include "flexhdr.h"

static	unsigned int	aflag;

%}

%option noyywrap
%option 8bit
%option batch
%option case-sensitive
%option pointer
%option prefix="case"


S	[ ]
END	[^a-zA-Z]
P	[., ]
ZIP	[0-9]{5}((-[0-9]{4})?)
USA_STATES	((AL)|(AK)|(AS)|(AZ)|(AR)|(BC)|(CA)|(CZ)|(CO)|(CT)|(DE)|(DC)|(FL)|(GA)|(GU)|(HI)|(ID)|(IL)|(IN)|(IA)|(KS)|(KY)|(LA)|(ME)|(MD)|(MA)|(MI)|(MN)|(MS)|(MO)|(MT)|(NE)|(NB)|(NH)|(NJ)|(NM)|(NV)|(NY)|(NC)|(ND)|(CM)|(OH)|(OK)|(OR)|(OT)|(PA)|(PR)|(RI)|(SC)|(SD)|(TN)|(TX)|(TT)|(UT)|(VT)|(VA)|(VI)|(WA)|(WV)|(WI)|(WY))

AU_STATES	((NSW)|(QLD)|(SA)|(VIC)|(TAS)|(ACT)|(NT)|(WA))

%%

\001[^0-9]*[0-9]{1,2}"/"[0-9]{1,2}" "*\032	{aflag|=P_DATE;}

{S}[A-Z][A-Za-z]+,?[ ]+{USA_STATES}/{END}		{aflag=P_ADDRESS|P_STATE;}
{S}[A-Z][A-Za-z]*[,. ]*[0-9][0-9][0-9][0-9][0-9]	{aflag=P_ADDRESS|P_STATE;}
{S}[A-Z][0-9][A-Z][ ][0-9][A-Z][0-9]			{aflag=P_ADDRESS|P_STATE|P_ZIP;/*canada 1*/}
{S}[A-Z][0-9][A-Z][0-9][A-Z]				{aflag=P_ADDRESS|P_STATE|P_ZIP;/*canada 2*/}
{S}[A-Z][A-Z][0-9][A-Z][ ][0-9][A-Z][A-Z]		{aflag=P_ADDRESS|P_STATE|P_ZIP;/*UK*/}

{S}[A-Z][A-Za-z]+,?[ ]+{AU_STATES}			{aflag=P_ADDRESS|P_STATE|P_ZIP;/*Australia*/}
{S}{AU_STATES}[ ]+[0-9]{4}/{END}			{aflag=P_ADDRESS|P_STATE|P_ZIP;/*Australia*/}

.							{} /* Ignore, but look for more stuff */

{S}NeXT/{END}						{aflag=P_COMPANY;}
{S}URL[sS]?/{END}					{aflag=P_COMPANY;}

%%



unsigned int	parse_case(const char *buf)
{
	char	*mbuf	= (char*)alloca(strlen(buf)+16);
	char	*cc;
	const	char *dd;

	cc	= mbuf;
	*cc++	= ' ';
	for(dd=buf;*dd;dd++,cc++){
		*cc = *dd;
		if(*cc == '\t') *cc = ' ';
	}
	*cc++	= ' ';
	*cc++	= ' ';
	*cc++	= ' ';
	*cc++	= EOF;
	*cc++	= '\000';
	
	aflag	= 0;


	/* initialize flex static variables */
	PSETUP(mbuf,strlen(mbuf));
	yylex();		/* DO IT! */
	PSHUTDOWN;

	return aflag;
}
