%{
/* Time parser built entirely out of flex
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

#include <time.h>
#include <ctype.h>


enum {
	AMERICAN=1,
	EUROPEAN=2
};
static 	int	year,month,day,hour,minute,sec;
static	long	gmtoff;
int	date_format = AMERICAN;
static  int     adebug=0;


%}

%option noyywrap
%option 8bit
%option batch
%option case-insensitive
%option pointer
%option prefix="yytime"


YEAR	(([0-9][0-9])?([0-9][0-9]))
NUM 	([0-9][0-9]?)
NN 	([^0-9])

JAN	(JAN(UARY)?)
FEB	(FEB(RUARY)?)
MAR	(MAR(CH)?)
APR	(APR(IL)?)
MAY	(MAY)
JUN	(JUN(E)?)
JUL	(JUL(Y)?)
AUG	(AUG(UST)?)
SEP	(SEP(TEMBER)?)
OCT	(OCT(OBER)?)
NOV	(NOV(EMBER)?)
DEC	(DEC(EMBER)?)

AMONTH	({JAN}|{FEB}|{MAR}|{APR}|{MAY}|{JUN}|{JUL}|{AUG}|{SEP}|{OCT}|{NOV}|{DEC})


DATE1	({NUM}-{AMONTH}-{YEAR})
DATE2	({AMONTH}[ \t]*{NUM}[ ,\t]*{YEAR})

%%

{DATE1}|{DATE2}			{
				char	*cc;

				adebug = 1;

				month	= parse_month(yytext);
				for(cc=yytext;*cc && !isdigit(*cc);cc++){
				}
				day	= atoi(cc);
				for(;*cc && isdigit(*cc);cc++){
				}
				for(;*cc && !isdigit(*cc);cc++){
				}
				year	= atoi(cc);
				}
				

{NUM}[ \t]*{AMONTH}[ \t]*{YEAR}	{
				char *cc;

				adebug = 2;


				for(cc=yytext+strlen(yytext)-1;
					isdigit(*cc);
					cc--){
				}	
				day	= atoi(yytext);
				year	= atoi(cc+1);
				month	= parse_month(yytext);
				}

{NUM}"/"{NUM}	{
							int first,second,count;

				adebug = 3;

				count = sscanf(yytext,"%d/%d",&first,&second);
				if(count==2){
 				  date_format = AMERICAN;            // default
				  if(first>12)	date_format = EUROPEAN;
				  if(second>12)	date_format = AMERICAN;
				  if(first>31 && second>31) date_format = 0;
				  if(date_format==AMERICAN){
					month	= first;
					day	= second;
				  }
				  if(date_format==EUROPEAN){
					month 	= second;
					day	= first;
				  }
				}
			}


{NUM}"/"{NUM}"/"{YEAR}	{
				int first,second,third,count;

				adebug = 4;


				count = sscanf(yytext,"%d/%d/%d",&first,&second,&third);
				if(count==3){
				  date_format = AMERICAN;            // default
				  if(first>12)	date_format = EUROPEAN;
				  if(second>12)	date_format = AMERICAN;
				  if(first>31 && second>31) date_format = 0;
				  if(date_format==AMERICAN){
					month	= first;
					day	= second;
					year    = third;
				  }
				  else{
					month 	= second;
					day	= first;
					year   = third;
				  }
				  }
				}


{NUM}":"{NUM}(":"{NUM})?[ \t]*[aA]/{NN}	{
				adebug = 5;


				/* handle a time with an a.m.  We have to
				 * special case 12:01 a.m. and the link
				 */
				sscanf(yytext,"%d:%d:%d",&hour,&minute,&sec);
				if(hour==12) hour=0;
				}

{NUM}":"{NUM}(":"{NUM})?[ \t]*[pP]/{NN}	{
				adebug = 6;


				/* handle a time with a p.m.
				 */
				sscanf(yytext,"%d:%d:%d",&hour,&minute,&sec);
				hour+=12;
				}

{NUM}":"{NUM}(":"{NUM})?/{NN}	{
				adebug = 7;
				sscanf(yytext,"%d:%d:%d",&hour,&minute,&sec);
				}

"GMT"?("+"|"-")[0-9][0-9][0-9][0-9]	{


				char	c;
				int	offhours,offmin;

				adebug = 8;


				sscanf(yytext,"%c%2d%2d",
					&c,&offhours,&offmin);

				gmtoff	= (offhours*60+offmin)*60;
				if(c=='-') gmtoff = -gmtoff;
				}

[0-9][0-9][0-9][0-9]"-"/([A-Z][SD]"T")	{
				adebug = 9;

				sscanf(yytext,"%2d%2d",&hour,&minute);
				}
				

[jJeEpPmMcCbB][sSdD][tT]	{
				adebug = 10;

				switch(toupper(yytext[0])){
					case 'E': gmtoff = -5; break;
					case 'C': gmtoff = -6; break;
					case 'M': gmtoff = -7; break;
					case 'P': gmtoff = -8; break;
					case 'B': gmtoff = -8; break;
						/* Berkeley */
					case 'J': gmtoff =  9; break;
						/* Japan    */
				}
				if(toupper(yytext[1])=='D') gmtoff -= 1;
				gmtoff  *= 60*60;
			
				}

.				{
				/* null rule --- ignore */
				}
%%
unsigned int	parse_time(const char *buf,struct tm *tm)
{
	struct tm mtm;
	char	*mbuf	= (char *)alloca(strlen(buf)+16);

	if(tm==0) tm = &mtm;  // use local copy

	strcpy(mbuf,buf);
	strcat(mbuf," ");

	year 	= -1;
	month   = -1;
	day     = -1;
	hour    = -1;
	minute     =  -1;
	sec     = -1;
	gmtoff	= -1L;

	PSETUP(mbuf,strlen(mbuf));
	yylex();		/* do it */
	PSHUTDOWN;
	

	if(year>1900){
		year -= 1900;
	}

	if(year 	!= -1)	tm->tm_year	= year;
	if(month	!= -1)	tm->tm_mon	= month-1;
	if(day  	!= -1)	tm->tm_mday	= day;
	if(hour 	!= -1)  tm->tm_hour	= hour;
	if(minute		!= -1)	tm->tm_min	= minute;
	if(sec		!= -1)	tm->tm_sec	= sec;
#ifdef __FreeBSD__
        if(gmtoff	!= -1L) tm->tm_gmtoff	= gmtoff;
#endif

	/* See if we are confident enough to return the time flag */
	if(hour!=-1 && minute!=-1) return P_DATE;
	if(year!=-1 && month!=-1) return P_DATE;
	if(month!=-1 && day!=-1) return P_DATE;
	
	return 0;
}

