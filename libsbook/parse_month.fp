%{
/* month parser built out of flex.
 * Searches for a month string and returns its number.
 *
 * (C) 1990, 1991, 1992, 2000, 2001 Simson L. Garfinkel
 * All rights reserved.
 * Unrestricted use granted to Sandstorm Enterprises.
 */

#ifdef WIN32
#pragma warning( disable: 4127 )				  // conditional expression is constant
#pragma warning( disable: 4244 )			// Conversion from int to unsigned char
#pragma warning( disable: 4505 )			// unreferenced local function has been removed
#endif


#include "libsbook.h"
#include "flexhdr.h"

static 	int	month;
			
%}

END	[^a-zA-Z]

%option noyywrap
%option 8bit
%option batch
%option case-insensitive
%option pointer
%option prefix="yymonth"
%%

JAN(UARY)?{END}		{month=0;}
FEB(RUARY)?{END}	{month=1;}
MAR(CH)?{END}		{month=2;}
APR(IL)?{END}		{month=3;}
MAY{END}		{month=4;}
JUN(E)?{END}		{month=5;}
JUL(Y)?{END}		{month=6;}
AUG(UST)?{END}		{month=7;}
SEP(TEMBER)?{END}	{month=8;}
OCT(OBER)?{END}		{month=9;}
NOV(EMBER)?{END}	{month=10;}
DEC(EMBER)?{END} 	{month=11;}

.						{/* null rule --- ignore */}
%%
int	parse_month(const char *buf)
{
	char	*mbuf	= (char *)alloca(strlen(buf)+2);

	strcpy(mbuf,buf);
	strcat(mbuf," ");

	month	= -1;

	PSETUP(mbuf,strlen(mbuf));
	yylex();
	PSHUTDOWN;

	return(month);
}

