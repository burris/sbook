%{
//
//	Copyright (C) 1992, 2001 Simson L. Garfinkel
//	All rights reserved.
//	$Id: parse_company.fp,v 1.1 2004/07/21 03:18:14 simsong Exp $
//
//	Company parser built out of flex.
//	Return TRUE if the name provided is probably a company...
//

#include "libsbook.h"
#include "flexhdr.h"

static	unsigned int	aflag;
			
%}

%option noyywrap
%option 8bit
%option batch
%option case-insensitive
%option pointer
%option prefix="yycompany"

S	[^A-Z]
END	[^A-Z]
WORD	([A-Z0-9]+)
HIS	(His|Her)
MOST	(Most|Right|Very)" "+
CONST	([BCDFGHJKLMNPQRSTVWXZ])

%%

\001[ ]*"The artist formerly known as Prince"		{aflag = 0;}
\001[ ]+The" "+{MOST}?Reverend/{END}			{aflag = 0;}
\001[ ]+The" "+{MOST}?(Honorable|Venerable)/{END}	{aflag = 0;}
\001[ ]+{HIS}" "+(All" "+)?Holiness/{END}		{aflag = 0;}
\001[ ]+{HIS}" "+(Excellency|Eminence)/{END}		{aflag = 0;}

\001[ ]+[A-Z0-9 \.]+","" "+(USA|USN|USCG|USAF|USMC)/{END}		{aflag = 0;}

\001[ ]*[A-Z]+"'S "[A-Z]+[ ]*\032	{aflag = P_COMPANY;}
{S}[A-Z]+"/"[A-Z]+{S}			{aflag = P_COMPANY;}
{S}for{S}				{aflag = P_COMPANY;}
{S}[A-Z]-[A-Z]*[ ]			{aflag = P_COMPANY;}
{S}U"."?[ ]*S"."?[ ]+			{aflag = P_COMPANY;}

[A-Z]\*[A-Z]				{aflag = P_COMPANY; }
[A-Z]"'S"/{END}				{aflag = P_COMPANY; }


"&"					{aflag = P_COMPANY;}

\.COM/{END}				{aflag = P_COMPANY;}
\.NET/{END}				{aflag = P_COMPANY;}
\.ORG/{END}				{aflag = P_COMPANY;}
\.MIL/{END}				{aflag = P_COMPANY;}
\.EDU/{END}				{aflag = P_COMPANY;}
\.INT/{END}				{aflag = P_COMPANY;}

{S}[WK][A-Z][A-Z][A-Z]?" "(9[0-9]\.[0-9])|(10[0-9]\.[0-9])|([5-9][0-9]0)|(1[0-7][0-9]0)	{aflag=20;}
{S}{CONST}{CONST}[0-9]{CONST}	{aflag = P_COMPANY;}

{S}DDS/{END}			{aflag = P_NOT_COMPANY;}
{S}D"."D"."S"."/{END}			{aflag = P_NOT_COMPANY;}

{S}GENESIS/{END}		{aflag = P_COMPANY;}
{S}EXODUS/{END}			{aflag = P_COMPANY;}
{S}NUMBERS?/{END}		{aflag = P_COMPANY;}

{S}PHD/{END}			{aflag = P_NOT_COMPANY;}

{S}[BCDFGHJKLMNPQRSTVWXZ][BCDFGHJKLMNPQRSTVWXZ][BCDFGHJKLMNPQRTVWXZ]/{END}	{aflag = P_COMPANY;}
{S}[BCDFGHJKLMNPQRSTVWXZ][BCDFGHJKLMNPQSTVWXZ][BCDFGHJKLMNPQRSTVWXZ]/{END}	{aflag = P_COMPANY;}
{S}[BCDFGHJKLNPQRSTVWXZ][BCDFGHJKLMNPQRSTVWXZ][BCDFGHJKLMNPQRSTVWXZ]/{END}	{aflag = P_COMPANY;}
{S}[BCDFGHJKLMNPQRSTVWXZ]{4}/{END} {aflag = P_COMPANY;}

\001{S}*p[. ]*o[. ]*b(ox)?		{aflag |= P_ADDRESS | P_NOT_COMPANY;}


XX				{aflag = P_COMPANY;}

{S}[A-Z]+" "+[0-9]+/{END}	{aflag = P_COMPANY;}

{S}TO/{END}			{aflag = P_COMPANY;}
{S}ON/{END}			{aflag = P_COMPANY;}
{S}UNDER/{END}			{aflag = P_COMPANY;}
{S}ABOVE/{END}			{aflag = P_COMPANY;}
{S}WITH/{END}			{aflag = P_COMPANY;}

{S}HYDROGEN/{END}	{aflag = P_COMPANY;}
{S}OXYGEN/{END}		{aflag = P_COMPANY;}
{S}IRON/{END}		{aflag = P_COMPANY;}
{S}LITHIUM/{END}	{aflag = P_COMPANY;}
{S}BORON/{END}		{aflag = P_COMPANY;}


[A-Z]{4,}[!]		{aflag = P_COMPANY;}

PLUS/{END}			{aflag = P_COMPANY;}
FILM/{END}			{aflag = P_COMPANY;}
POLIS/{END}			{aflag = P_COMPANY;}
WAREHOUSE/{END}			{aflag = P_COMPANY;}
{WORD}" "+RECORDS/{END}		{aflag = P_COMPANY;}
{WORD}" "+JUICE/{END}		{aflag = P_COMPANY;}
{S}{WORD}" "+TO" "+{WORD}/{END}	{aflag = P_COMPANY;}
WORLD/{END}			{aflag = P_COMPANY;}
BOARDS?/{END}			{aflag = P_COMPANY;}
[A-Z]*CODE/{END}		{aflag = P_COMPANY;}
[A-Z]*OGICS/{END}		{aflag = P_COMPANY;}
[A-Z]*OGIX/{END}		{aflag = P_COMPANY;}
[A-Z]*STAIRS/{END}		{aflag = P_COMPANY;}
[A-Z]*TION/{END}		{aflag = P_COMPANY;}
[A-Z]-?TECH/{END}		{aflag = P_COMPANY;}
[A-Z]-TEL/{END}			{aflag = P_COMPANY;}
[A-Z]WARE/{END}			{aflag = P_COMPANY;}
[A-Z]DATA/{END}			{aflag = P_COMPANY;}
{S}[A-Z][A-Z][0-9]{1,3}/{END}	{aflag = P_COMPANY;}
\-TV/{END}			{aflag = P_COMPANY;}
{S}"BLUE CROSS"/{END}		{aflag = P_COMPANY;}
{S}"BLUE SHIELD"/{END}		{aflag = P_COMPANY;}
{S}"GRATEFUL DEAD"/{END}	{aflag = P_COMPANY;}
{S}"HEWLETT PACKARD"/{END}	{aflag = P_COMPANY;}
{S}"POWER AND LIGHT"/{END}	{aflag = P_COMPANY;}
{S}19[0-9][0-9]/{END}		{aflag = P_COMPANY;}
{S}20[0-9][0-9]/{END}		{aflag = P_COMPANY;}
{S}ACCESS/{END}			{aflag = P_COMPANY;}
{S}ACCESSORIES?/{END}		{aflag = P_COMPANY;}
{S}ACCOMMODATIONS?/{END}	{aflag = P_COMPANY;}
{S}ACIDS?/{END}			{aflag = P_COMPANY;}
{S}ACLU/{END}			{aflag = P_COMPANY;}
{S}ACME/{END}			{aflag = P_COMPANY;}
{S}ACRES/{END}			{aflag = P_COMPANY;}
{S}ACTION/{END}			{aflag = P_COMPANY;}
{S}ACTIVATION/{END}		{aflag = P_COMPANY;}
{S}ACTIVE/{END}			{aflag = P_COMPANY;}
{S}ADDRESS/{END}		{aflag = P_COMPANY;}
{S}ADMINISTRATION/{END}		{aflag = P_COMPANY;}
{S}ADULT/{END}			{aflag = P_COMPANY;}
{S}ADVANCED?/{END}		{aflag = P_COMPANY;}
{S}ADVENTURES?/{END}		{aflag = P_COMPANY;}
{S}AFFAIRS?/{END}		{aflag = P_COMPANY;}
{S}AGENCY/{END}			{aflag = P_COMPANY;}
{S}AIDS/{END}			{aflag = P_COMPANY;}
{S}AIR/{END}			{aflag = P_COMPANY;}
{S}ALCOHOL/{END}		{aflag = P_COMPANY;}
{S}ALLIED/{END}			{aflag = P_COMPANY;}
{S}AMTRAK/{END}			{aflag = P_COMPANY;}
{S}ANIMATION/{END}		{aflag = P_COMPANY;}
{S}ANON/{END}			{aflag = P_COMPANY;}
{S}APS/{END}			{aflag = P_COMPANY;}
{S}AQUARIUM/{END}		{aflag = P_COMPANY;}
{S}ARMY/{END}			{aflag = P_COMPANY;}
{S}ASS/{END}			{aflag = P_COMPANY;}
{S}OUSTED/{END}			{aflag = P_COMPANY;}
{S}ASSOCIATES?/{END}		{aflag = P_COMPANY;}
{S}ASSOCIATION/{END}		{aflag = P_COMPANY;}
{S}AUCTION/{END}		{aflag = P_COMPANY;}
{S}AUDIO/{END}			{aflag = P_COMPANY;}
{S}AUTHORIT(Y|IES)/{END}	{aflag = P_COMPANY;}
{S}CONTINENTAL/{END}		{aflag = P_COMPANY;}
{S}AIRLINES?/{END}		{aflag = P_COMPANY;}
{S}STEAMSHIP/{END}		{aflag = P_COMPANY;}
{S}AUTHORIZED/{END}		{aflag = P_COMPANY;}
{S}AUTO(MOBILE)?S?/{END}	{aflag = P_COMPANY;}
{S}AVALON/{END}			{aflag = P_COMPANY;}
{S}AVIATION/{END}		{aflag = P_COMPANY;}
{S}ATTORN(EY|IES)/{END}		{aflag = P_COMPANY;}
{S}Androstenone			{aflag = P_COMPANY;}
{S}BANK/{END}			{aflag = P_COMPANY;}
{S}BT/{END}			{aflag = P_COMPANY;}
{S}3-D/{END}			{aflag = P_COMPANY;}
{S}BANKRUPTACY/{END}		{aflag = P_COMPANY;}
{S}BANNING/{END}		{aflag = P_COMPANY;}
{S}Baths?/{END}			{aflag = P_COMPANY;}
{S}BATTERY/{END}		{aflag = P_COMPANY;}
{S}BAY/{END}			{aflag = P_COMPANY;}
{S}BED/{END}			{aflag = P_COMPANY;}
{S}BEFORE/{END}			{aflag = P_COMPANY;}
{S}BEST/{END}			{aflag = P_COMPANY;}
{S}BICYCLES?/{END}		{aflag = P_COMPANY;}
{S}BIG/{END}			{aflag = P_COMPANY;}
{S}BIKES?/{END}			{aflag = P_COMPANY;}
{S}Adobe/{END}			{aflag = P_COMPANY;}
{S}BOARD/{END}			{aflag = P_COMPANY;}
{S}Cliq/{END}			{aflag = P_COMPANY;}
{S}Spirits?/{END}			{aflag = P_COMPANY;}
{S}BOOKS/{END}					{aflag = P_COMPANY;}
{S}BREAKFAST/{END}		{aflag = P_COMPANY;}
{S}BIRTH(DAY)?S?/{END}		{aflag = P_COMPANY;}
{S}BUGGIES			{aflag = P_COMPANY;}
{S}BUREAU			{aflag = P_COMPANY;}
{S}CABLE/{END}			{aflag = P_COMPANY;}
{S}CAFE/{END}			{aflag = P_COMPANY;}
{S}Sarticious/{END}		{aflag = P_COMPANY;}
{S}CHAT/{END}			{aflag = P_COMPANY;}
{S}CAFETERIAS?/{END}		{aflag = P_COMPANY;}
{S}CAMERA/{END}			{aflag = P_COMPANY;}
{S}CARGO/{END}			{aflag = P_COMPANY;}
{S}CASA/{END}			{aflag = P_COMPANY;}
{S}CATALYTIC/{END}		{aflag = P_COMPANY;}
{S}CELL(ULAR)?/{END}		{aflag = P_COMPANY;}
{S}CENTER/{END}			{aflag = P_COMPANY;}
{S}CHEAP/{END}			{aflag = P_COMPANY;}
{S}CHEMICAL/{END}		{aflag = P_COMPANY;}
{S}WEDDING/{END}		{aflag = P_COMPANY;}
{S}EXPENSIVE/{END}		{aflag = P_COMPANY;}
{S}CHEZ/{END}			{aflag = P_COMPANY;}
{S}Chevrolet/{END}			{aflag = P_COMPANY;}
{S}CYCLE/{END}			{aflag = P_COMPANY;}
{S}TOOLS/{END}			{aflag = P_COMPANY;}
{S}MAIL/{END}			{aflag = P_COMPANY;}
{S}EMAIL/{END}			{aflag = P_COMPANY;}
{S}VISUAL/{END}			{aflag = P_COMPANY;}
{S}EFFECTS/{END}			{aflag = P_COMPANY;}
{S}dewey{S}cheetam{S}and{S}howe		{aflag = P_COMPANY;}
{S}BUILDERS?/{END}			{aflag = P_COMPANY;}
{S}CHOICE/{END}			{aflag = P_COMPANY;}
{S}CIRCUITS/{END}		{aflag = P_COMPANY;}
{S}CIRCUS/{END}			{aflag = P_COMPANY;}
{S}CLEANERS?/{END}		{aflag = P_COMPANY;}
{S}CLICK/{END}			{aflag = P_COMPANY;}
{S}CLUBS?/{END}			{aflag = P_COMPANY;}
{S}CO/{END}			{aflag = P_COMPANY;}
{S}CODES?/{END}			{aflag = P_COMPANY;}
{S}COLA/{END}			{aflag = P_COMPANY;}
{S}COMERCIAL/{END}		{aflag = P_COMPANY;}
{S}COMMITTEE/{END}		{aflag = P_COMPANY;}
{S}COMMUNICATIONS?/{END}	{aflag = P_COMPANY;}
{S}COMMUNITY/{END}		{aflag = P_COMPANY;}
{S}COMPANIA/{END}		{aflag = P_COMPANY;}
{S}COMPANY/{END}		{aflag = P_COMPANY;}
{S}COMPAQ/{END}			{aflag = P_COMPANY;}
{S}COMPU			{aflag = P_COMPANY;}
{S}COMPUTERS/{END}		{aflag = P_COMPANY;}
{S}COMPUTING/{END}		{aflag = P_COMPANY;}
{S}CONFERENCE			{aflag = P_COMPANY;}
{S}CONNECTION/{END}		{aflag = P_COMPANY;}
{S}CONSCIOUS/{END}		{aflag = P_COMPANY;}
{S}CONSULTANTS/{END}		{aflag = P_COMPANY;}
{S}CONSULTING/{END}		{aflag = P_COMPANY;}
{S}CONTROL/{END}		{aflag = P_COMPANY;}
{S}Removal/{END}		{aflag = P_COMPANY;}
{S}Lead/{END}			{aflag = P_COMPANY;}
{S}CORP/{END}			{aflag = P_COMPANY;}
{S}CORPORATE/{END}		{aflag = P_COMPANY;}
{S}CORPORATION/{END}		{aflag = P_COMPANY;}
{S}CORRECTION			{aflag = P_COMPANY;}
{S}COSTUME/{END}		{aflag = P_COMPANY;}
{S}KRISPY/{END}			{aflag = P_COMPANY;}
{S}KREME/{END}			{aflag = P_COMPANY;}
{S}DOUGHNUTS/{END}		{aflag = P_COMPANY;}
{S}CSPAN			{aflag = P_COMPANY;}
{S}CYCLERY/{END}		{aflag = P_COMPANY;}
{S}DELI/{END}			{aflag = P_COMPANY;}
{S}DELL/{END}			{aflag = P_COMPANY;}
{S}DEPARTMENT/{END}		{aflag = P_COMPANY;}
{S}DEPENDABLE/{END}		{aflag = P_COMPANY;}
{S}DESIGN/{END}			{aflag = P_COMPANY;}
{S}DETAILS?/{END}		{aflag = P_COMPANY;}
{S}DEVELOPERS?/{END}		{aflag = P_COMPANY;}
{S}DEVELOPMENT/{END}		{aflag = P_COMPANY;}
{S}DIAL.?(IN|UP)/{END}		{aflag = P_COMPANY;}
{S}DIGITAL/{END}		{aflag = P_COMPANY;}
{S}DINER/{END}			{aflag = P_COMPANY;}
{S}DIR(ECTIONS?)?/{END}		{aflag = P_COMPANY;}
{S}DISEASE/{END}		{aflag = P_COMPANY;}
{S}DREYFUS/{END}		{aflag = P_COMPANY;}
{S}DRUG(STORE)?/{END}		{aflag = P_COMPANY;}
{S}EARTH			{aflag = P_COMPANY;}
{S}ECSTACY/{END}		{aflag = P_COMPANY;}
{S}EDUCATION/{END}		{aflag = P_COMPANY;}
{S}EFF/{END}			{aflag = P_COMPANY;}
{S}OpenTable/{END}		{aflag = P_COMPANY;}
{S}TEA/{END}			{aflag = P_COMPANY;}
{S}ELECTR			{aflag = P_COMPANY;}
{S}ELEVATOR			{aflag = P_COMPANY;}
{S}EMERGENCY			{aflag = P_COMPANY;}
{S}ENCHANCEMENTS?/{END}		{aflag = P_COMPANY;}
{S}SELECT/{END}			{aflag = P_COMPANY;}
{S}COMFORT/{END}		{aflag = P_COMPANY;}
{S}ENERGY/{END}			{aflag = P_COMPANY;}
{S}ENGINEER			{aflag = P_COMPANY;}
{S}ENTERPRISES/{END}		{aflag = P_COMPANY;}
{S}EPA/{END}			{aflag = P_COMPANY;}
{S}EQUIPMENT/{END}		{aflag = P_COMPANY;}
{S}ESSENTIAL/{END}		{aflag = P_COMPANY;}
{S}ETHIC(S|AL)/{END}		{aflag = P_COMPANY;}
{S}EVALUATION/{END}		{aflag = P_COMPANY;}
{S}EXCHANGE/{END}		{aflag = P_COMPANY;}
{S}EXECUTIVE/{END}		{aflag = P_COMPANY;}
{S}EXERCISE/{END}		{aflag = P_COMPANY;}
{S}EXPLOR			{aflag = P_COMPANY;}
{S}EXPRESS/{END}		{aflag = P_COMPANY;}
{S}EYRE/{END}			{aflag = P_COMPANY;}
{S}FAR/{END}			{aflag = P_COMPANY;}
{S}FAMILY" "+[A-Z]/{END}	{aflag = P_COMPANY;}
{S}FAMILY" "+\032/{END}		{aflag = P_NOT_COMPANY;}
{S}FARM/{END}			{aflag = P_COMPANY;}
{S}FEED(BACK)?/{END}		{aflag = P_COMPANY;}
{S}FIDELITY/{END}		{aflag = P_COMPANY;}
{S}FILM/{END}			{aflag = P_COMPANY;}
{S}FIRE/{END}			{aflag = P_COMPANY;}
{S}FLORIST/{END}		{aflag = P_COMPANY;}
{S}FLIGHT?/{END}		{aflag = P_COMPANY;}
{S}FLY(ING)?/{END}		{aflag = P_COMPANY;}
{S}FUNERAL/{END}		{aflag = P_COMPANY;}
{S}FUTURA			{aflag = P_COMPANY;}
{S}FUTURE			{aflag = P_COMPANY;}
{S}GAS/{END}			{aflag = P_COMPANY;}
{S}GENERAL/{END}		{aflag = P_COMPANY;}
{S}GRAPHICS?/{END}		{aflag = P_COMPANY;}
{S}GREAT/{END}			{aflag = P_COMPANY;}
{S}GRILLE?/{END}		{aflag = P_COMPANY;}
{S}GROUP/{END}			{aflag = P_COMPANY;}
{S}GRUPO/{END}			{aflag = P_COMPANY;}
{S}GUARD/{END}			{aflag = P_COMPANY;}
{S}HEADLIGHTS?/{END}		{aflag = P_COMPANY;}
{S}HEADQUARTERS?/{END}		{aflag = P_COMPANY;}
{S}HEALTH			{aflag = P_COMPANY;}
{S}HEATING/{END}		{aflag = P_COMPANY;}
{S}HELICOPTER/{END}		{aflag = P_COMPANY;}
{S}HELP/{END}			{aflag = P_COMPANY;}
{S}HERBAL/{END}			{aflag = P_COMPANY;}
{S}HIGHWAY/{END}		{aflag = P_COMPANY;}
{S}HILTON/{END}			{aflag = P_COMPANY;}
{S}HITCHING/{END}		{aflag = P_COMPANY;}
{S}HOLDINGS?/{END}		{aflag = P_COMPANY;}
{S}HOME/{END}			{aflag = P_COMPANY;}
{S}HONDA/{END}			{aflag = P_COMPANY;}
{S}Managed/{END}		{aflag = P_COMPANY;}
{S}bakery/{END}			{aflag = P_COMPANY;}
{S}firewall/{END}		{aflag = P_COMPANY;}
{S}firewood/{END}		{aflag = P_COMPANY;}
{S}pottery/{END}		{aflag = P_COMPANY;}
{S}barn/{END}			{aflag = P_COMPANY;}
{S}HOSPITAL/{END}		{aflag = P_COMPANY;}
{S}HOTELS?/{END}		{aflag = P_COMPANY;}
{S}HOTLINE/{END}		{aflag = P_COMPANY;}
{S}HOUSE/{END}			{aflag = P_COMPANY;}
{S}HURRICANE/{END}		{aflag = P_COMPANY;}
{S}HYATT/{END}			{aflag = P_COMPANY;}
{S}IBM/{END}			{aflag = P_COMPANY;}
{S}COLD/{END}			{aflag = P_COMPANY;}
{S}LOGIC/{END}			{aflag = P_COMPANY;}
{S}HP/{END}			{aflag = P_COMPANY;}
{S}IMAGE/{END}			{aflag = P_COMPANY;}
{S}IN" "AND" "OUT/{END}		{aflag = P_COMPANY;}
{S}INCORPORATED/{END}		{aflag = P_COMPANY;}
{S}INFO/{END}			{aflag = P_COMPANY;}
{S}INFOR			{aflag = P_COMPANY;}
{S}INFORMATION/{END}		{aflag = P_COMPANY;}
{S}INNS?/{END}			{aflag = P_COMPANY;}
{S}INSURANCE/{END}		{aflag = P_COMPANY;}
{S}INVESTMENTS?/{END}		{aflag = P_COMPANY;}
{S}INVESTORS?/{END}		{aflag = P_COMPANY;}
{S}IP/{END}			{aflag = P_COMPANY;}
{S}work(ing)?/{END}		{aflag = P_COMPANY;}
{S}INTERNET/{END}		{aflag = P_COMPANY;}
{S}ROUTER/{END}		{aflag = P_COMPANY;}
{S}ROUTING/{END}		{aflag = P_COMPANY;}
{S}ISLAMIC/{END}		{aflag = P_COMPANY;}
{S}LEVEL/{END}		{aflag = P_COMPANY;}
{S}STUDY/{END}		{aflag = P_COMPANY;}
{S}CRITICAL/{END}		{aflag = P_COMPANY;}
{S}BUYS/{END}		{aflag = P_COMPANY;}
{S}SWISSCOM/{END}		{aflag = P_COMPANY;}
{S}ISLAND/{END}			{aflag = P_COMPANY;}
{S}ISP/{END}			{aflag = P_COMPANY;}
{S}JEWELERS?/{END}		{aflag = P_COMPANY;}
{S}JEWISH/{END}			{aflag = P_COMPANY;}
{S}LAB(ORATORIE)?S?/{END}	{aflag = P_COMPANY;}
{S}LANDSCAP(E|ING)/{END}	{aflag = P_COMPANY;}
{S}LASER/{END}			{aflag = P_COMPANY;}
{S}PASSWORDS?/{END}		{aflag = P_COMPANY;}
{S}PHONES?/{END}		{aflag = P_COMPANY;}
{S}DOMAIN/{END}			{aflag = P_COMPANY;}
[A-Z]"-"MED/{END}		{aflag = P_COMPANY;}
{S}MASSPIRG/{END}		{aflag = P_COMPANY;}
[A-Z]" "LAWS/{END}		{aflag = P_NOT_COMPANY;}  /* Jane Laws */
{S}LAWS/{END}			{aflag = P_COMPANY;}
{S}OPT"-"(IN|OUT)/{END}		{aflag = P_COMPANY;}
{S}LAW[ ]OFFICES?/{END}		{aflag = P_COMPANY;}
{S}LEATHER/{END}		{aflag = P_COMPANY;}
{S}LIBRARY/{END}		{aflag = P_COMPANY;}
{S}LIBRTY/{END}			{aflag = P_COMPANY;}
{S}LIFE/{END}			{aflag = P_COMPANY;}
{S}LIMITED/{END}		{aflag = P_COMPANY;}
{S}LINE/{END}			{aflag = P_COMPANY;}
{S}LIVESTOCK/{END}		{aflag = P_COMPANY;}
{S}LOAN/{END}			{aflag = P_COMPANY;}
{S}NEED/{END}			{aflag = P_COMPANY;}
{S}KNOW/{END}			{aflag = P_COMPANY;}
{S}LOBBY/{END}			{aflag = P_COMPANY;}
{S}LOCKSMITHS?/{END}		{aflag = P_COMPANY;}
{S}LODGE/{END}			{aflag = P_COMPANY;}
{S}LOG(I|O)N/{END}		{aflag = P_COMPANY;}
{S}LONE" STAR"?/{END}		{aflag = P_COMPANY;}
{S}LUGGAGE/{END}		{aflag = P_COMPANY;}
{S}LUMBER/{END}			{aflag = P_COMPANY;}
{S}MACHINES?/{END}		{aflag = P_COMPANY;}
{S}MAGNETICS?/{END}		{aflag = P_COMPANY;}
{S}MARKETS?/{END}		{aflag = P_COMPANY;}
{S}MARRIOTT/{END}		{aflag = P_COMPANY;}
{S}MATERIALS?/{END}		{aflag = P_COMPANY;}
{S}MEETING/{END}		{aflag = P_COMPANY;}
{S}MERCURY/{END}		{aflag = P_COMPANY;}
{S}STARWOOD/{END}		{aflag = P_COMPANY;}
{S}WESTIN/{END}			{aflag = P_COMPANY;}
{S}METRO			{aflag = P_COMPANY;}
{S}MICRO			{aflag = P_COMPANY;}
{S}MILEAGE/{END}		{aflag = P_COMPANY;}
{S}MINERAL/{END}		{aflag = P_COMPANY;}
{S}MISC/{END}			{aflag = P_COMPANY;}
{S}MORTGAGE/{END}		{aflag = P_COMPANY;}
{S}MOTELS?/{END}		{aflag = P_COMPANY;}
{S}MOTORS?			{aflag = P_COMPANY;}
{S}MOUNTAIN/{END}		{aflag = P_COMPANY;}
{S}WIRELESS/{END}		{aflag = P_COMPANY;}
{S}MOVERS/{END}			{aflag = P_COMPANY;}
{S}MOVING/{END}			{aflag = P_COMPANY;}
{S}MUSIC(AL)?/{END}		{aflag = P_COMPANY;}
{S}MUSLIM/{END}			{aflag = P_COMPANY;}
{S}MUTUAL/{END}			{aflag = P_COMPANY;}
{S}NAVY/{END}			{aflag = P_COMPANY;}
{S}NET(WORK)?S?/{END}		{aflag = P_COMPANY;}
{S}NEW/{END}			{aflag = P_COMPANY;}
{S}NYU/{END}			{aflag = P_COMPANY;}
{S}OF/{END}			{aflag = P_COMPANY;}
{S}OFF/{END}			{aflag = P_COMPANY;}
{S}OFFICE/{END}			{aflag = P_COMPANY;}
{S}OFFSHORE/{END}		{aflag = P_COMPANY;}
{S}OIL/{END}			{aflag = P_COMPANY;}
{S}OLD/{END}			{aflag = P_COMPANY;}
{S}ONLINE/{END}			{aflag = P_COMPANY;}
{S}OPEN/{END}			{aflag = P_COMPANY;}
{S}OPERATION(S)?/{END}		{aflag = P_COMPANY;}
{S}OPTICS?/{END}		{aflag = P_COMPANY;}
{S}Carmel.*hazard/{END}		{aflag = P_NOT_COMPANY;}
{S}ORCHARDS?/{END}		{aflag = P_COMPANY;}
{S}OUTDOOR/{END}		{aflag = P_COMPANY;}
{S}OUTFITTERS?/{END}		{aflag = P_COMPANY;}
{S}PARTNERS?			{aflag = P_COMPANY;}
{S}PATHOLOGY/{END}		{aflag = P_COMPANY;}
{S}PATROL/{END}			{aflag = P_COMPANY;}
{S}PC/{END}			{aflag = P_COMPANY;}
{S}PEOPLE/{END}			{aflag = P_COMPANY;}
{S}PERCISION/{END}		{aflag = P_COMPANY;}
{S}PERFORMANCE/{END}		{aflag = P_COMPANY;}
{S}PERSONAL/{END}		{aflag = P_COMPANY;}
{S}PHARMACY/{END}		{aflag = P_COMPANY;}
{S}SALES/{END}			{aflag = P_COMPANY;}
{S}SALON/{END}			{aflag = P_COMPANY;}
{S}PHOTO(GRAPHY?)?/{END}	{aflag = P_COMPANY;}
{S}PIPELINES?			{aflag = P_COMPANY;}
{S}PIZZA/{END}			{aflag = P_COMPANY;}
{S}PLUMBING/{END}		{aflag = P_COMPANY;}
{S}PLUS				{aflag = P_COMPANY;}
{S}POLICE/{END}			{aflag = P_COMPANY;}
{S}PORTFOLIO/{END}		{aflag = P_COMPANY;}
{S}POWER			{aflag = P_COMPANY;}
{S}PRACTICE/{END}		{aflag = P_COMPANY;}
{S}PRESS/{END}			{aflag = P_COMPANY;}
{S}PRINT(ING)?/{END}		{aflag = P_COMPANY;}
{S}PRODUCT(ION)?S?/{END}	{aflag = P_COMPANY;}
{S}PROGRAM/{END}		{aflag = P_COMPANY;}
{S}PUBLIC/{END}			{aflag = P_COMPANY;}
{S}PUBLISHING/{END}		{aflag = P_COMPANY;}
{S}Pheromones?/{END}		{aflag = P_COMPANY;}
{S}SBOOK/{END}			{aflag = P_COMPANY;}
{S}QUALITY/{END}		{aflag = P_COMPANY;}
{S}QUICK(EN)?/{END}		{aflag = P_COMPANY;}
{S}RADIO/{END}			{aflag = P_COMPANY;}
{S}RADISSON/{END}		{aflag = P_COMPANY;}
{S}RANCH/{END}			{aflag = P_COMPANY;}
{S}REACH/{END}			{aflag = P_COMPANY;}
{S}REALT(Y|(ORS?))/{END}	{aflag = P_COMPANY;}
{S}REPAIR/{END}			{aflag = P_COMPANY;}
{S}Paint/{END}			{aflag = P_COMPANY;}
{S}ARCHITECTS?/{END}		{aflag = P_COMPANY;}
{S}ARCHITECTURE/{END}		{aflag = P_COMPANY;}
{S}Industries/{END}		{aflag = P_COMPANY;}
{S}council/{END}		{aflag = P_COMPANY;}
{S}arts/{END}			{aflag = P_COMPANY;}
{S}gallery/{END}		{aflag = P_COMPANY;}
{S}Kayaks?/{END}		{aflag = P_COMPANY;}
{S}crafts/{END}			{aflag = P_COMPANY;}
{S}pictures/{END}		{aflag = P_COMPANY;}
{S}pirate/{END}			{aflag = P_COMPANY;}
{S}interactive/{END}		{aflag = P_COMPANY;}
{S}Living/{END}			{aflag = P_COMPANY;}
{S}Prairie/{END}		{aflag = P_COMPANY;}
{S}Museum/{END}			{aflag = P_COMPANY;}
{S}Commerciales/{END}		{aflag = P_COMPANY;}
{S}Arthur{S}Andersen/{END}	{aflag = P_COMPANY;}
{S}Aunt{S}Jemima/{END}	{aflag = P_COMPANY;}
[A-Z]{S}SEARS/{END}		{aflag = P_NOT_COMPANY;}
{S}RESEARCH/{END}		{aflag = P_COMPANY;}
{S}RESERVATIONS/{END}		{aflag = P_COMPANY;}
{S}RESTORATION/{END}		{aflag = P_COMPANY;}
{S}RESTAURANT/{END}		{aflag = P_COMPANY;}
{S}ROCKET/{END}			{aflag = P_COMPANY;}
{S}ROOM/{END}			{aflag = P_COMPANY;}
{S}ROUND(UP)?/{END}		{aflag = P_COMPANY;}
{S}Ritz.?Carlton/{END}		{aflag = P_COMPANY;}
{S}SATELLITE/{END}		{aflag = P_COMPANY;}
{S}SAVINGS/{END}		{aflag = P_COMPANY;}
{S}SAVERS/{END}			{aflag = P_COMPANY;}
{S}SCIENTISTS?/{END}		{aflag = P_COMPANY;}
{S}SCIENTIFIC/{END}		{aflag = P_COMPANY;}
{S}SCHEDULE(D)?/{END}		{aflag = P_COMPANY;}
{S}SCIENCES?/{END}		{aflag = P_COMPANY;}
{S}SEAFOOD/{END}		{aflag = P_COMPANY;}
{S}SEARCH/{END}			{aflag = P_COMPANY;}
{S}FOOD/{END}			{aflag = P_COMPANY;}
{S}SECRETS?/{END}		{aflag = P_COMPANY;}
{S}SENATE/{END}			{aflag = P_COMPANY;}
{S}SERVER/{END}			{aflag = P_COMPANY;}
{S}SERVICE(S)?/{END}		{aflag = P_COMPANY;}
{S}TIAA/{END}			{aflag = P_COMPANY;}
{S}CREF/{END}			{aflag = P_COMPANY;}
{S}SEX/{END}			{aflag = P_COMPANY;}
{S}SF				{aflag = P_COMPANY;}
{S}SHACK/{END}			{aflag = P_COMPANY;}
{S}SHARPER/{END}		{aflag = P_COMPANY;}
{S}SHOP/{END}			{aflag = P_COMPANY;}
{S}DOG/{END}			{aflag = P_COMPANY;}
{S}SOCIETY/{END}		{aflag = P_COMPANY;}
{S}SOFTWARE/{END}		{aflag = P_COMPANY;}
{S}SOLUTIONS/{END}		{aflag = P_COMPANY;}
{S}SOPHISTICATED/{END}		{aflag = P_COMPANY;}
{S}SPEED/{END}			{aflag = P_COMPANY;}
{S}SPORTS?/{END}		{aflag = P_COMPANY;}
{S}SQUARE/{END}			{aflag = P_COMPANY;}
{S}STAKE(HOUSE)?/{END}		{aflag = P_COMPANY;}
{S}STATIONERS?/{END}		{aflag = P_COMPANY;}
{S}STOCK/{END}			{aflag = P_COMPANY;}
{S}STORAGE/{END}		{aflag = P_COMPANY;}
{S}STORE/{END}			{aflag = P_COMPANY;}
{S}STORM/{END}			{aflag = P_COMPANY;}
{S}STRATEG(Y|IC)		{aflag = P_COMPANY;}
{S}STUDIOS/{END}		{aflag = P_COMPANY;}
{S}SUBSCRIBE/{END}		{aflag = P_COMPANY;}
{S}SUPER			{aflag = P_COMPANY;}
{S}SYMBOLS?/{END}		{aflag = P_COMPANY;}
{S}SYSTEMS?/{END}		{aflag = P_COMPANY;}
{S}Security/{END}		{aflag = P_COMPANY;}
{S}Social/{END}			{aflag = P_COMPANY;}
{S}TAXI/{END}			{aflag = P_COMPANY;}
{S}TAXIDERMY/{END}		{aflag = P_COMPANY;}
{S}TEAM/{END}			{aflag = P_COMPANY;}
{S}TECHNICAL/{END}		{aflag = P_COMPANY;}
{S}TECHNO			{aflag = P_COMPANY;}
{S}TECHNOLOG			{aflag = P_COMPANY;}
{S}TELE[A-Z]+/{END}		{aflag = P_COMPANY;}
{S}TEMPLE/{END}			{aflag = P_COMPANY;}
{S}TERRA			{aflag = P_COMPANY;}
{S}TERRORIST/{END}		{aflag = P_COMPANY;}
{S}TREASURY/{END}		{aflag = P_COMPANY;}
{S}DIRECT/{END}			{aflag = P_COMPANY;}
{S}802[.]11			{aflag = P_COMPANY;}
{S}TEST(S)?(ING)?/{END}			{aflag = P_COMPANY;}
{S}THEATER/{END}		{aflag = P_COMPANY;}
{S}THEATRE/{END}		{aflag = P_COMPANY;}
{S}THERAPEUTICS?		{aflag = P_COMPANY;}
{S}Kitchens?/{END}		{aflag = P_COMPANY;}
{S}THINKING/{END}		{aflag = P_COMPANY;}
{S}TICKET			{aflag = P_COMPANY;}
{S}YOUTH/{END}			{aflag = P_COMPANY;}
{S}TIRES?/{END}			{aflag = P_COMPANY;}
{S}TOURS?/{END}			{aflag = P_COMPANY;}
{S}TOYS?/{END}			{aflag = P_COMPANY;}
{S}TRAIL/{END}			{aflag = P_COMPANY;}
{S}TRANSFERS?/{END}		{aflag = P_COMPANY;}
{S}TRANSIT/{END}		{aflag = P_COMPANY;}
{S}TRAVEL/{END}			{aflag = P_COMPANY;}
{S}TREATMENT/{END}		{aflag = P_COMPANY;}
{S}RUBBER/{END}		{aflag = P_COMPANY;}
{S}OUTSOURC((ES?)|ING)/{END}		{aflag = P_COMPANY;}
{S}STAMP/{END}		{aflag = P_COMPANY;}
WEAPON			{aflag = P_COMPANY;}
{S}TRUCKING/{END}		{aflag = P_COMPANY;}
{S}TRUST/{END}			{aflag = P_COMPANY;}
{S}TV/{END}			{aflag = P_COMPANY;}
{S}TYPO				{aflag = P_COMPANY;}
{S}unique/{END}			{aflag = P_COMPANY;}
{S}UNION/{END}			{aflag = P_COMPANY;}
{S}UNITED/{END}			{aflag = P_COMPANY;}
{S}UPGRADE/{END}		{aflag = P_COMPANY;}
{S}USA/{END}			{aflag = P_COMPANY;}
{S}USAID/{END}			{aflag = P_COMPANY;}
{S}UTILIT(Y|IES)/{END}		{aflag = P_COMPANY;}
{S}VANTAGE/{END}		{aflag = P_COMPANY;}
{S}VENTURE			{aflag = P_COMPANY;}
{S}VICTORIAN/{END}		{aflag = P_COMPANY;}
{S}VIDO/{END}			{aflag = P_COMPANY;}
{S}VINEYARDS?/{END}		{aflag = P_COMPANY;}
{S}VISA/{END}			{aflag = P_COMPANY;}
{S}VISION/{END}			{aflag = P_COMPANY;}
{S}VOLKSWAGEN/{END}		{aflag = P_COMPANY;}
{S}VOODOO/{END}			{aflag = P_COMPANY;}
{S}VOTER'?S?/{END}		{aflag = P_COMPANY;}
{S}VW/{END}			{aflag = P_COMPANY;}
{S}WARNER" "+BRO(THER)?S/{END}  {aflag = P_COMPANY;}
{S}WAREHOUSE/{END}		{aflag = P_COMPANY;}
{S}WATCH/{END}			{aflag = P_COMPANY;}
{S}WELCOME/{END}		{aflag = P_COMPANY;}
{S}WHEELS?/{END}		{aflag = P_COMPANY;}
{S}WOMEN('S)?/{END}		{aflag = P_COMPANY;}
{S}WORKS?/{END}			{aflag = P_COMPANY;}
{S}WORLD(WIDE)?/{END}		{aflag = P_COMPANY;}
{S}WRITERS/{END}		{aflag = P_COMPANY;}
{S}XMAS				{aflag = P_COMPANY;}
{S}LABORATORY/{END}		{aflag = P_COMPANY;}

[- ]SONIC(S)/{END}		{aflag = P_COMPANY;}


{S}CAB/{END}			{aflag = P_COMPANY;}
{S}AMC/{END}			{aflag = P_COMPANY;}
{S}JEEP/{END}			{aflag = P_COMPANY;}

{S}ETC/{END}			{aflag = P_COMPANY;}
{S}CYMK/{END}			{aflag = P_COMPANY;}

{S}alpha/{END}			{aflag = P_COMPANY;}
{S}beta/{END}			{aflag = P_COMPANY;}
{S}gamma/{END}			{aflag = P_COMPANY;}
{S}delta/{END}			{aflag = P_COMPANY;}
{S}epsilon/{END}		{aflag = P_COMPANY;}
{S}theta/{END}			{aflag = P_COMPANY;}
{S}omega/{END}			{aflag = P_COMPANY;}

{S}first/{END}			{aflag = P_COMPANY;}
{S}second/{END}			{aflag = P_COMPANY;}
{S}third/{END}			{aflag = P_COMPANY;}
{S}fourth/{END}			{aflag = P_COMPANY;}
{S}fifth/{END}			{aflag = P_COMPANY;}
{S}sixth/{END}			{aflag = P_COMPANY;}
{S}seventh/{END}		{aflag = P_COMPANY;}
{S}eighth/{END}			{aflag = P_COMPANY;}
{S}ninth/{END}			{aflag = P_COMPANY;}
{S}tenth/{END}			{aflag = P_COMPANY;}


{S}western/{END}		{aflag = P_COMPANY;}
{S}eastern/{END}		{aflag = P_COMPANY;}
{S}southern/{END}		{aflag = P_COMPANY;}
{S}northern/{END}		{aflag = P_COMPANY;}

{S}one/{END}			{aflag = P_COMPANY;}
{S}two/{END}			{aflag = P_COMPANY;}
{S}three/{END}			{aflag = P_COMPANY;}
{S}four/{END}			{aflag = P_COMPANY;}
{S}five/{END}			{aflag = P_COMPANY;}
{S}six/{END}			{aflag = P_COMPANY;}
{S}seven/{END}			{aflag = P_COMPANY;}
{S}eight/{END}			{aflag = P_COMPANY;}

{S}nine/{END}			{aflag = P_COMPANY;}
{S}ten/{END}			{aflag = P_COMPANY;}
{S}hundred/{END}		{aflag = P_COMPANY;}
{S}thousand/{END}		{aflag = P_COMPANY;}

\001[ ]+The/{END}		{aflag = P_COMPANY;}

.flagfile(company_names.txt,{S},/{END}	{aflag = P_COMPANY;})



{S}ENTWICKLUNGS/{END}		{aflag = P_COMPANY;}
{S}AG/{END}			{aflag = P_COMPANY;}
{S}INC/{END}			{aflag = P_COMPANY;}
{S}LDA/{END}			{aflag = P_COMPANY;}
{S}S\.?A\.?/{END}		{aflag = P_COMPANY;}
{S}S\.?P\.?A\.?/{END}		{aflag = P_COMPANY;}
{S}L\.?T\.?D\.?/{END}		{aflag = P_COMPANY;}
{S}S\.?K\.?F\.?/{END}		{aflag = P_COMPANY;}
{S}SOFCWARE/{END}		{aflag = P_COMPANY;}
{S}SYSTEMES/{END}		{aflag = P_COMPANY;}



%{
// Publically traded companies
%}




%%
unsigned int	parse_company0(const char *buf)
{
	char	*mbuf	= (char*)alloca(strlen(buf)+16);
	char	*cc;
	const	char *dd;

	cc	= mbuf;
	*cc++	= 1;			/* begin with control-a */
	*cc++	= ' ';
	for(dd=buf;*dd;dd++,cc++){
		*cc = *dd;
		if(*cc == '\t') *cc = ' ';
	}
	*cc++	= ' ';
	*cc++	= ' ';
	*cc++	= ' ';
	*cc++	= 26;			/* end with a control-z */
	*cc++	= EOF;
	*cc++	= '\000';
	
	aflag	= 0;

	PSETUP(mbuf,strlen(mbuf));
	yylex();
	PSHUTDOWN;
	return aflag;
}

unsigned int	parse_company(const char *buf)
{
	int pa = parse_address(buf);
	int pc = parse_company0(buf);

	if((pa|pc) & P_NOT_COMPANY) return 0;       /* not a company */

	if(pa & P_EMAIL) return 0;       /* by definition, a person */
	
	if( (pa & P_ADDRESS) && !(pa & P_WEAK) ){
	    return P_COMPANY;     /* addresses are companies unless they are weak */
        }

	if( (pa|pc) & P_COMPANY) return P_COMPANY; /* companies are companies */

	int stock = parse_stocks(buf);

	if(stock>0) return P_COMPANY;             /* stocks are companies */
	
	return 0;
}
