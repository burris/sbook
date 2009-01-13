%{
//
// Copyright (C) 1991, 1992, 2000,2001,2002 Simson L. Garfinkel
// All rights reserved.
// Address  parser
//
#include "libsbook.h"
#include "flexhdr.h"

static	unsigned int	aflag=0;
unsigned int pa_debug=0;
%}

%option noyywrap
%option 8bit
%option batch
%option case-insensitive
%option pointer
%option prefix="yyaddress"

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

ISO	(ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cf|cd|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|fi|fj|fk|fm|fo|fr|fx|ga|gb|gd|ge|gf|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|in|io|iq|ir|is|it|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nt|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|pt|pw|py|qa|re|ro|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zr|zw)

GTLD	(com|edu|net|org|mil|biz|info|int|gov)
DOMAIN	({GTLD}|{ISO})

%%




{S}sn" "[0-9]{3}			{aflag |= P_NOT_ADDRESS; /* serial numbers are not addresses */}


https?:"//"{H}+"/"?		{aflag |= P_URL;}
"www"[.]{H}+[.]{DOMAIN}		{aflag |= P_URL;}


{S}turn/{END}			{aflag |= P_DIRECTIONS;}
{S}left/{END}			{aflag |= P_DIRECTIONS;}
{S}right/{END}			{aflag |= P_DIRECTIONS;}
{S}at[ ]the[ ]light/{END}	{aflag |= P_DIRECTIONS;}

   /* Czech variants which I've been able to think of. The flexion is a real bitch!: */
{S}odbo\u010d(it|\355m|\355?te|ka)?/{END}			{aflag |= P_DIRECTIONS;}
{S}zah(ni|nout|nu|n\u011bte)/{END}			{aflag |= P_DIRECTIONS;}
{S}(v|na)levo/{END}			{aflag |= P_DIRECTIONS;}
{S}doleva/{END}			{aflag |= P_DIRECTIONS;}
{S}(v|na)pravo/{END}			{aflag |= P_DIRECTIONS;}
{S}doprava/{END}			{aflag |= P_DIRECTIONS;}
{S}(na|u)[ ]semaforu/{END}	{aflag |= P_DIRECTIONS;}
{S}p\u0159ed[ ]semaforem/{END}	{aflag |= P_DIRECTIONS;}
  /* these are used pretty often too, mean "beside the pub", more or less: */
{S}(vedle|u)[ ]restaurace/{END}	{aflag |= P_DIRECTIONS;}
{S}p\u0159ed[ ]restaurac\355/{END}	{aflag |= P_DIRECTIONS;}
{S}(vedle|u)[ ]hospody/{END}	{aflag |= P_DIRECTIONS;}
{S}p\u0159ed[ ]hospodou/{END}	{aflag |= P_DIRECTIONS;}
  /* these mean actually something like "highway" and "circle", but so far as I can say, they are almost exclusively used inside directions. Never I've seen them inside address/street: */
{S}(po|na)[ ]okruh(u)?/{END}	{aflag |= P_DIRECTIONS;}
{S}(po|na)[ ]d\341lnici/{END}	{aflag |= P_DIRECTIONS;}
{S}(po|na)[ ]magistr\341l(u|e)/{END}	{aflag |= P_DIRECTIONS;}
{S}sjezd(u)?/{END}	{aflag |= P_DIRECTIONS;}



[, ]{STATE}/{END}		{aflag |= P_ADDRESS | P_STATE;}
[, ]{WEAK_STATE}/{END}		{aflag |= P_ADDRESS | P_STATE | P_WEAK;}

{S}{PROVENCE}/{END}		{aflag |= P_ADDRESS;}

{P}p[. ]*o[. ]*b(ox)?		{aflag |= P_ADDRESS | P_NOT_COMPANY;}
{P}box[ 0-9]			{aflag |= P_ADDRESS;}
{P}RR[ 0-9]			{aflag |= P_ADDRESS;}
{P}RFD[ 0-9]			{aflag |= P_ADDRESS;}

{P}Postfach[ 0-9]	{aflag |= P_ADDRESS;}  /* germany */
{S}Platz/{END}			{aflag |= P_ADDRESS;}

{S}north/{END}			{aflag |= P_ADDRESS | P_NEWS | P_WEAK;}
{S}northern/{END}		{aflag |= P_ADDRESS | P_NEWS;}
{S}south(ern)?/{END}		{aflag |= P_ADDRESS | P_NEWS;}
{S}east(ern)?/{END}		{aflag |= P_ADDRESS | P_NEWS;}
{S}west/{END}			{aflag |= P_ADDRESS | P_NEWS | P_WEAK;}
{S}western/{END}		{aflag |= P_ADDRESS | P_NEWS;}
{S}central/{END}		{aflag |= P_ADDRESS | P_NEWS;}
{S}midtown/{END}		{aflag |= P_ADDRESS | P_NEWS;}


{S}alley/{END}			{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
{S}ally{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}arcade/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}arc{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}avenue/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}ave{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}apartment/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}apt{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}boulevard/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}blvd{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}branch/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}broadway/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}br{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}bypass/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}byp{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}causeway/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}cswy{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}center/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}ctr{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}circle/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}canyon/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}cir{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}court/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}ct{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}courts/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}cts{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}crescent/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}cres{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}drive/{END}			{aflag |= P_ADDRESS | P_STREET;}
{W}dr{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}expressway/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}expy{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}extended/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}extension/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}freeway/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}fwy{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}gardens/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}gdns{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}grove/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}grv{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}heights/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}hts{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}highway/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}hwy{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}lane/{END}			{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
{S}ln{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}manner/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}mnr{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}place/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}pl{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}plaza/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}plz{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}point/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}pt{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}road/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}room/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}rd{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}rural/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}square/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}sq{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}street/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}st{P}/{S}*{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}terrace/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}terr?{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}trail/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}trl{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}turnpike/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}tpke?{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}viaduct/{END}		{aflag |= P_ADDRESS | P_STREET;}
{S}via{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}vista/{END}			{aflag |= P_ADDRESS | P_STREET;}
{S}vis{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}zone/{END}			{aflag |= P_ADDRESS | P_STREET;}

  /* French */
{S}rue/{END}			  {aflag |= P_ADDRESS | P_STREET;}

  /* Dutch/Flemish */
[A-Z]{3,}KADE/{END}		{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
[A-Z]{3,}STEEG/{END}		{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
[A-Z]{3,}STRAAT/{END}		{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
[A-Z]{3,}STRAATWEG/{END}	{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
[A-Z]{3,}WEG/{END}		{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
[A-Z]{3,}LAAN/{END}		{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
[A-Z]{3,}PLEIN/{END}		{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
[A-Z]{3,}BOULEVARD/{END}	{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
[A-Z]{3,}DREEF/{END}		{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
[A-Z]{6,}HOF/{END}		{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
[A-Z]{6,}DIJK/{END}		{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
[A-Z]{6,}WAL/{END}		{aflag |= P_ADDRESS | P_STREET | P_WEAK;}

  /* German */
[A-Z]{4,}strase/{END}		{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
[A-Z]{4,}" "strase" "[0-9]	{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
{S}zimmer/{END}			{aflag |= P_ADDRESS | P_STREET | P_WEAK;} /* chamber */

{S}suurheid/{END}		{aflag |= P_ADDRESS | P_STREET | P_WEAK;} 


  /* Czech */
{S}n\341m{P}			{aflag |= P_ADDRESS | P_STREET;}
{S}n\341m\u011bst\355/{END}	{aflag |= P_ADDRESS | P_STREET;}
{S}ul{P}			{aflag |= P_ADDRESS | P_STREET | P_WEAK;}
{S}ulice/{END}			{aflag |= P_ADDRESS | P_STREET;}



{S}administration/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}admin{P}			{aflag |= P_ADDRESS | P_ORG;}
{S}beach/{END}			{aflag |= P_ADDRESS | P_ORG;}
{S}bldg/{END}			{aflag |= P_ADDRESS | P_ORG;}
{S}building/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}bureau/{END}			{aflag |= P_ADDRESS | P_ORG;}
{S}college/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}council/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}corporation/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}commission/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}conference/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}corp{P}			{aflag |= P_ADDRESS | P_ORG;}
{S}dorm{P}			{aflag |= P_ADDRESS | P_ORG;}
{S}federal/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}gallery/{END}		{aflag |= P_ADDRESS ;}
{S}foundation/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}department/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}project/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}institute/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}office/{END}			{aflag |= P_ADDRESS | P_ORG | P_OFFICE;}
{S}school/{END}			{aflag |= P_ADDRESS | P_ORG | P_OFFICE;}
{S}laboratory/{END}		{aflag |= P_ADDRESS | P_ORG | P_OFFICE;}
{S}preschool/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}society/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}museum/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}suite/{END}			{aflag |= P_ADDRESS | P_ORG;}
{S}univ/{END}			{aflag |= P_ADDRESS | P_ORG;}
{S}Montessori/{END}	{aflag |= P_ADDRESS | P_ORG;}
{S}university/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}alliance/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}coalition/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}house/{END}			{aflag |= P_ADDRESS | P_ORG;}
{S}consulate/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}embassy/{END}		{aflag |= P_ADDRESS | P_ORG;}


  /* Czech: */
  /* Hmmmmm. This will be difficult, since quite often companies use just name again (like "OCSoftware, address, phones"). Well _some_ strings there are. Also I am not sure of the exact meaning of P_OFFICE, so I don't use it (an exact translation of "office" is "kancel\341\u0159", but the most common usage of the word in company names here is in "cestovn\355 kancel\341\u0159", which means "travel agency"... (well don't you love those live languages ;): */
{S}kancel\341\u0159/{END}	{aflag |= P_ADDRESS | P_ORG;}
{S}a\\.s\\./{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}s\\.r\\.o\\./{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}sro/{END}			{aflag |= P_ADDRESS | P_ORG | P_WEAK;}
{S}spol(\\.|e\u010dnost)?/{END}		{aflag |= P_ADDRESS | P_ORG | P_WEAK;}
{S}bank(a|ovn\355)?/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}servis(n\355)?/{END}			{aflag |= P_ADDRESS | P_ORG;}
{S}v\375rob(a|n\355|ce)/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}fakult(a|n\355)/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}\u0161kol(a|n\355)/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}univer[sz]it(a|n\355)/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}\372stav(n\355)?/{END}		{aflag |= P_ADDRESS | P_ORG | P_WEAK;}
{S}studio/{END}			{aflag |= P_ADDRESS | P_ORG;}
{S}laborato\u0159/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}agentura/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}poradna/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}restaura(ce|nt)/{END}		{aflag |= P_ADDRESS | P_ORG;}
{S}klub/{END}		        {aflag |= P_ADDRESS | P_ORG;}
{S}tisk(\341rna|ov\351)?/{END}	{aflag |= P_ADDRESS | P_ORG | P_WEAK;}
{S}slu\u017e(by|ba|eb(n\355)?)?/{END}		{aflag |= P_ADDRESS | P_ORG;}


{S}AMERICANA?/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}CANADIAN/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}GERMAN/{END}			{aflag |= P_ADDRESS | P_ORG; }
{S}DUTCH/{END}			{aflag |= P_ADDRESS | P_ORG; }
{S}SPANISH/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}FRENCH/{END}			{aflag |= P_ADDRESS | P_ORG; }
{S}CHINESE/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}JAPANESE/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}ISRAELI/{END}		{aflag |= P_ADDRESS | P_ORG; }


 /* Check */
 /* what is the point of uppercases here? Why should eg. "Dutch flowers, inc." not do for DUTCH? */
{S}americk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}kanadsk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}n\u011bmeck(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}holandsk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}nizozemsk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}\u0161pan\u011blsk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}francouzsk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}\u010d\355nsk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}japonsk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}i[sz]raelsk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }

  /* Czech, Slovak, Polish, Hungarian... just neighbours. I don't think it is worth to add English ones for them: */
{S}\u010desk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}slovensk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}polsk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}ma\u010farsk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }
{S}rakousk(\375|\341|\351)/{END}		{aflag |= P_ADDRESS | P_ORG; }




{S}City/{END}			{aflag |= P_ADDRESS | P_CITY;}
{S}harvard/{END}		{aflag |= P_ADDRESS | P_CITY;}
{S}MIT/{END}			{aflag |= P_ADDRESS | P_CITY;}

  /* Chec */
{S}MFF/{END}			{aflag |= P_ADDRESS | P_CITY;}

{S}america/{END}		{aflag |= P_ADDRESS;}
{S}pacific/{END}		{aflag |= P_ADDRESS;}
{S}atlantic/{END}		{aflag |= P_ADDRESS;}

{S}afghanistan/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}africa/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}albania/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}algeria/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}andorra/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}angola/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}argentina/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}ascension/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}australia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}austria/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}azores/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}bahamas/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}bahrain/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}bangladesh/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}barbados/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}belfast/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}belgium/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}belize/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}benin/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}bermuda/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}bhutan/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}bolivia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}botswana/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}brazil/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}brunei/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}bulgaria/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}burma/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}burundi/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}cambodia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}cameroon/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}canada/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}cape[ ]verde/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}cayman[ ]islands/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}centeral[ ]african[ ]republic/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}chad/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}chile/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}china/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}columbia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}colombia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}comoros/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}congo/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}corsica/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}costa[ ]rica/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}cuba/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}cyprus/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}czechoslovakia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}czech" "republic/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}denmark/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}derbys/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}djibouti/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}dominica/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}dominican[ ]republic/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}east[ ]timor/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}ecuador/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}egypt/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}el[ ]salvador/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}equatorial[ ]guinea/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}estonia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}england/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}ethiopia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}faeroe[ ]islands/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}falkland[ ]islands/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}faso/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}fiji/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}finland/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}formosa/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}france/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}french[ ]guiana/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}french[ ]polynesia/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}gabon/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}gambia/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}germany/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}ghana/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}gibraltar/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}great[ ]britain/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}greece/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}greeland/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}grenada/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}guadeloupe/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}guatemala/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}guine/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}guine-bissau/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}guyana/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}gujarat/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}haiti/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}holland/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}honduras/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}hong[ ]kong/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}hungary/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}iceland/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}india/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}indonesia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}iran/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}iraq/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}ireland/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}israel/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}italy/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}ivory[ ]coast/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}jamaica/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}japan/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}jordan/{END}			{aflag |= P_ADDRESS | P_COUNTRY | P_WEAK;}
{S}kampuchea/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}kenya/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}kiribati/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}korea/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}south[ ]korea/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}north[ ]korea/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}kuwait/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}laos?/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}latvia/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}lebanon/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}leeward[ ]islands/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}lesotho/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}liberia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}libya/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}lithuania/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}luxenborg/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}macao/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}maadagascar/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}madeira[ ]islands/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}malawi/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}malaysia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}maldives/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}mali/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}malta/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}matinique/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}mauritania/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}mauritius/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}mexico/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}mongolia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}mor?rocco/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}mozambique/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}nauru/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}namibia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}nepal/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}netherlands/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}netherlands[ ]antiloes/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}new[ ]caledonia/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}new[ ]guinea/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}new[ ]zealand/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}nicaragua/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}niger/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}nigeria/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}norway/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}oman/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}pakistan/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}panama/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}papua[ ]new[ ]guinea/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}paraguay/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}peru/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}philippines/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}pitcairm[ ]islands/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}poland/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}portugal/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}Palestinian" "(National)?" "Authority/{END} {aflag |= P_ADDRESS | P_COUNTRY;}
{S}qatar/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}reunion/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}republic/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}republika/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}romania/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}rwanda/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}russia/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}samoa/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}s(ain)?t[. ]+helena/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}s(ain)?t[. ]+lucia/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}s(an)?ta[. ]+lucia/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}s(ain)?t[. ]+pierre/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}s(ain)?t[. ]+thomas/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}s(ain)?t[. ]+vincent/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}santa[ ]cruz[ ]islands/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}saudi[ ]arabia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}scotland/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}senegal/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}seychelles/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}sierre[ ]leone/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}singapore/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}solomon[ ]islands/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}somalia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}south[ ]africa/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}spain/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}sri[ ]lanka/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}sudan/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}suriname/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}swaziland/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}sweden/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}switzerland/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}syria/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}taiwan/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}tanzania/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}tasmania/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}thailand/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}the[ ]+netherlands/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}togo/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}tonga/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}trinidad/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}tristan[ ]da[ ]cunha/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}tunisia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}turkey/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}turks[ ]and[ ]caicos[ ]islands/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}tuvalu/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}ellice[ ]islands/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}uganda/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}u[. ]*s[. ]*s[. ]*r[. ]*/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}united[ ]arab[ ]emirates/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}upper[ ]volta/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}uruguay/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}united[ ]kingdom/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}union/{END}			{aflag |= P_ADDRESS | P_COUNTRY | P_WEAK;}
{S}vanuatu/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}vatican/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}venezuela/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}vietnam/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}western[ ]samoa/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}western[ ]sahara/{END}	{aflag |= P_ADDRESS | P_COUNTRY;}
{S}yemen/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}yugoslavia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}
{S}zaire/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}zambia/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}zimbabwe/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}

{S}Armenia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1000;}
{S}Azerbaijan/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1001;}
{S}Belarus/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1002;}
{S}Georgia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1003;}
{S}Kazakhstan/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1004;}
{S}Kyrgyzstan/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1005;}
{S}Moldovia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1006;}
{S}Tajikistan/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1007;}
{S}Turkmenistan/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1008;}
{S}Ukraine/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1009;}
{S}Uzbekistan/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1010;}
{S}Bosnia/{END}			{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1011;}
{S}Herzegovina/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1012;}
{S}Croatia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1013;}
{S}Macedonia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1014;}
{S}Serbia/{END}			{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1015;}
{S}Montenegro/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1016;}
{S}Slovenia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1017;}
{S}Slovakia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1018;}
{S}Eritrea/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1019;}
{S}Marshall" "Islands/{END}	{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1020;}
{S}Palau/{END}			{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1021;}
{S}Micronesia/{END}		{aflag |= P_ADDRESS | P_COUNTRY;pa_debug=1022;}



{S}paris/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}london/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}madrid/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}genova/{END}			{aflag |= P_ADDRESS | P_COUNTRY;}
{S}brondby/{END}		{aflag |= P_ADDRESS | P_COUNTRY;}

  /* These are all german; should probably have a P_GERMANY... */


{S}(Niedersachsen|Lower)" "Saxony" "/{END}			{aflag |= P_ADDRESS;}
{S}Aachen/{END}			{aflag |= P_ADDRESS;}
{S}Aalen/{END}			{aflag |= P_ADDRESS;}
{S}Achim/{END}			{aflag |= P_ADDRESS;} 
{S}Ahaus/{END}			{aflag |= P_ADDRESS;}
{S}Alsfeld/{END}		{aflag |= P_ADDRESS;}
{S}Alstaette/{END}		{aflag |= P_ADDRESS;}
{S}Altenburg/{END}		{aflag |= P_ADDRESS;}
{S}Alzey/{END}			{aflag |= P_ADDRESS;}
{S}Ankuem/{END}			{aflag |= P_ADDRESS;}
{S}Annaberg/{END}		{aflag |= P_ADDRESS;}
{S}Ansbach/{END}		{aflag |= P_ADDRESS;}
{S}Arnsberg/{END}		{aflag |= P_ADDRESS;}
{S}Arolsen/{END}		{aflag |= P_ADDRESS;}
{S}Aschaffenburg/{END}		{aflag |= P_ADDRESS;}
{S}Aschau/{END}			{aflag |= P_ADDRESS;}
{S}Aufkirchen/{END}		{aflag |= P_ADDRESS;}
{S}Augsburg/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Camberg/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Duerkheim/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Ems/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Herrenalb/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Hersfeld/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Homburg/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Kreuznach/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Laasphe/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Liebenzell/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Lippspringe/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Malente/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Mergentheim/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Nauheim/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Nenndorf/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Pyrmont/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Rothenfelde/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Salzuflen/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Sassendorf/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Segeberg/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Soden" "Salmuenster/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Urach/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Weilbach/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Weissee/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Wildungen/{END}			{aflag |= P_ADDRESS;}
{S}Bad" "Zwischenahn/{END}			{aflag |= P_ADDRESS;}
{S}Baden" "Baden/{END}			{aflag |= P_ADDRESS;}
{S}Baden/{END}			{aflag |= P_ADDRESS;}
{S}Bamberg/{END}			{aflag |= P_ADDRESS;}
{S}Baunatal/{END}		{aflag |= P_ADDRESS;}
{S}Bavaria/{END}		{aflag |= P_ADDRESS;}
{S}Bayern/{END}			{aflag |= P_ADDRESS;}
{S}Bayreuth/{END}		{aflag |= P_ADDRESS;}
{S}Bensheim/{END}			{aflag |= P_ADDRESS;}
{S}Berg" "Leoni/{END}			{aflag |= P_ADDRESS;}
{S}Bergen/{END}			{aflag |= P_ADDRESS;}
{S}Berlin/{END}			{aflag |= P_ADDRESS;}
{S}Bernkastel" "Cues" "Rheinland" "pfalz/{END}			{aflag |= P_ADDRESS;}
{S}Biberach/{END}			{aflag |= P_ADDRESS;}
{S}Bielefeld/{END}			{aflag |= P_ADDRESS;}
{S}Bingen/{END}			{aflag |= P_ADDRESS;}
{S}Bissendorf/{END}			{aflag |= P_ADDRESS;}
{S}Bochum/{END}			{aflag |= P_ADDRESS;}
{S}Boeblingen/{END}			{aflag |= P_ADDRESS;}
{S}Bonn/{END}		{aflag |= P_ADDRESS;}
{S}Boppard.rhein/{END}			{aflag |= P_ADDRESS;}
{S}Brandenburg/{END}			{aflag |= P_ADDRESS;}
{S}Brandis/{END}			{aflag |= P_ADDRESS;}
{S}Braunlage/{END}			{aflag |= P_ADDRESS;}
{S}Braunschweig/{END}			{aflag |= P_ADDRESS;}
{S}Brehna/{END}			{aflag |= P_ADDRESS;}
{S}Bremen/{END}			{aflag |= P_ADDRESS;}
{S}Bremerhaven/{END}			{aflag |= P_ADDRESS;}
{S}Bruehl/{END}			{aflag |= P_ADDRESS;}
{S}Castrop/{END}		{aflag |= P_ADDRESS;}
{S}Celle/{END}			{aflag |= P_ADDRESS;}
{S}Coburg/{END}			{aflag |= P_ADDRESS;}
{S}Cologne/{END}			{aflag |= P_ADDRESS;}
{S}Cottbus/{END}			{aflag |= P_ADDRESS;}
{S}Cuxhaven/{END}			{aflag |= P_ADDRESS;}
{S}Darmstadt/{END}			{aflag |= P_ADDRESS;}
{S}Dasing/{END}			{aflag |= P_ADDRESS;}
{S}Detmold/{END}			{aflag |= P_ADDRESS;}
{S}Ditzingen/{END}			{aflag |= P_ADDRESS;}
{S}Doelbau/{END}			{aflag |= P_ADDRESS;}
{S}Donauries/{END}			{aflag |= P_ADDRESS;}
{S}Donauworth/{END}			{aflag |= P_ADDRESS;}
{S}Dormagen/{END}			{aflag |= P_ADDRESS;}
{S}Dortmund/{END}			{aflag |= P_ADDRESS;}
{S}Dreieich/{END}		{aflag |= P_ADDRESS;}
{S}Dresden/{END}			{aflag |= P_ADDRESS;}
{S}Duesseldorf/{END}			{aflag |= P_ADDRESS;}
{S}Duisberg/{END}			{aflag |= P_ADDRESS;}
{S}Dusseldorf/{END}			{aflag |= P_ADDRESS;}
{S}Eisenach/{END}		{aflag |= P_ADDRESS;}
{S}Eltville/{END}			{aflag |= P_ADDRESS;}
{S}Erding/{END}		{aflag |= P_ADDRESS;}
{S}Erfkstadt/{END}			{aflag |= P_ADDRESS;}
{S}Erlangen/{END}			{aflag |= P_ADDRESS;}
{S}Eschborn/{END}		{aflag |= P_ADDRESS;}
{S}Essen/{END}			{aflag |= P_ADDRESS;}
{S}Ettlingen/{END}			{aflag |= P_ADDRESS;}
{S}Europa/{END}			{aflag |= P_ADDRESS;}
{S}Falkenstein/{END}		{aflag |= P_ADDRESS;}
{S}Feldkirchen/{END}			{aflag |= P_ADDRESS;}
{S}Filderstadt/{END}			{aflag |= P_ADDRESS;}
{S}Flensburg/{END}			{aflag |= P_ADDRESS;}
{S}Floersheim/{END}		{aflag |= P_ADDRESS;}
{S}Frankenthal/{END}			{aflag |= P_ADDRESS;}
{S}Frankfurt/{END}			{aflag |= P_ADDRESS;}
{S}Frasdorf/{END}			{aflag |= P_ADDRESS;}
{S}Freiburg/{END}			{aflag |= P_ADDRESS;}
{S}Freidrichshafen/{END}			{aflag |= P_ADDRESS;}
{S}Freising/{END}			{aflag |= P_ADDRESS;}
{S}Friedrichroda/{END}		{aflag |= P_ADDRESS;}
{S}Friedrichshafen/{END}			{aflag |= P_ADDRESS;}
{S}Fuerth/{END}			{aflag |= P_ADDRESS;}
{S}Fuessen/{END}			{aflag |= P_ADDRESS;}
{S}Fulda/{END}			{aflag |= P_ADDRESS;}
{S}Gaertringen/{END}			{aflag |= P_ADDRESS;}
{S}Garbsen/{END}			{aflag |= P_ADDRESS;}
{S}Garmisch-partenkirchen/{END}			{aflag |= P_ADDRESS;}
{S}Garmisch/{END}			{aflag |= P_ADDRESS;}
{S}Gelsenkirchen/{END}			{aflag |= P_ADDRESS;}
{S}Gera/{END}			{aflag |= P_ADDRESS;}
{S}Gerlingen/{END}			{aflag |= P_ADDRESS;}
{S}Gersthofen/{END}			{aflag |= P_ADDRESS;}
{S}Giessen/{END}			{aflag |= P_ADDRESS;}
{S}Glienicke/{END}			{aflag |= P_ADDRESS;}
{S}Goerlitz/{END}		{aflag |= P_ADDRESS;}
{S}Goettingen/{END}			{aflag |= P_ADDRESS;}
{S}Goslar/{END}		{aflag |= P_ADDRESS;}
{S}Gotha/{END}			{aflag |= P_ADDRESS;}
{S}Greifswald/{END}			{aflag |= P_ADDRESS;}
{S}Grossbeeren/{END}			{aflag |= P_ADDRESS;}
{S}Guestrow/{END}			{aflag |= P_ADDRESS;}
{S}Guetersloh/{END}		{aflag |= P_ADDRESS;}
{S}Guglingen/{END}		{aflag |= P_ADDRESS;}
{S}Gunzburg/{END}			{aflag |= P_ADDRESS;}
{S}Haan" "Mengerskirchen/{END}			{aflag |= P_ADDRESS;}
{S}Hagen/{END}			{aflag |= P_ADDRESS;}
{S}Hahnenklee" "Michendorf" "Thuringia/{END}			{aflag |= P_ADDRESS;}
{S}Halle" "Minden/{END}			{aflag |= P_ADDRESS;}
{S}Halle" "Peisen/{END}			{aflag |= P_ADDRESS;}
{S}Halle" "Saale/{END}			{aflag |= P_ADDRESS;}
{S}Halle" "Westfalen/{END}			{aflag |= P_ADDRESS;}
{S}Hamburg/{END}			{aflag |= P_ADDRESS;}
{S}Hameln/{END}			{aflag |= P_ADDRESS;}
{S}Hamm/{END}			{aflag |= P_ADDRESS;}
{S}Hanau/{END}		{aflag |= P_ADDRESS;}
{S}Hannover/{END}			{aflag |= P_ADDRESS;}
{S}Hanover/{END}			{aflag |= P_ADDRESS;}
{S}Hartenstein/{END}			{aflag |= P_ADDRESS;}
{S}Heide[ ]Neubrandenburg/{END}			{aflag |= P_ADDRESS;}
{S}Heidelberg/{END}			{aflag |= P_ADDRESS;}
{S}Heidenheim/{END}			{aflag |= P_ADDRESS;}
{S}Heilbronn/{END}			{aflag |= P_ADDRESS;}
{S}Helgoland/{END}			{aflag |= P_ADDRESS;}
{S}Helmstedt/{END}			{aflag |= P_ADDRESS;}
{S}Hennigsdorf/{END}			{aflag |= P_ADDRESS;}
{S}Henstedt/{END}			{aflag |= P_ADDRESS;}
{S}Hepenheim/{END}			{aflag |= P_ADDRESS;}
{S}Heringsdorf/{END}			{aflag |= P_ADDRESS;}
{S}Herten/{END}			{aflag |= P_ADDRESS;}
{S}Hockenheim/{END}			{aflag |= P_ADDRESS;}
{S}Hof/{END}			{aflag |= P_ADDRESS;}
{S}Hoppegarten/{END}			{aflag |= P_ADDRESS;}
{S}Hoyerswerda/{END}			{aflag |= P_ADDRESS;}
{S}Huerth/{END}			{aflag |= P_ADDRESS;}
{S}Ilsenburg/{END}			{aflag |= P_ADDRESS;}
{S}Ingolstadt/{END}			{aflag |= P_ADDRESS;}
{S}Isernhagen/{END}			{aflag |= P_ADDRESS;}
{S}Jena/{END}			{aflag |= P_ADDRESS;}
{S}Jueterbog/{END}			{aflag |= P_ADDRESS;}
{S}Juist/{END}			{aflag |= P_ADDRESS;}
{S}Kaarst/{END}			{aflag |= P_ADDRESS;}
{S}Kaiserslautern/{END}		{aflag |= P_ADDRESS;}
{S}Karben/{END}			{aflag |= P_ADDRESS;}
{S}Karlsruhe/{END}			{aflag |= P_ADDRESS;}
{S}Kassel/{END}			{aflag |= P_ADDRESS;}
{S}Kelsterbach/{END}			{aflag |= P_ADDRESS;}
{S}Kiel/{END}			{aflag |= P_ADDRESS;}
{S}Kirchheim[ ]Teck/{END}			{aflag |= P_ADDRESS;}
{S}Koblenz/{END}			{aflag |= P_ADDRESS;}
{S}Koeln/{END}			{aflag |= P_ADDRESS;}
{S}Koetschlitz/{END}			{aflag |= P_ADDRESS;}
{S}Koln/{END}			{aflag |= P_ADDRESS;}
{S}Konigswinter/{END}		{aflag |= P_ADDRESS;}
{S}Konstanz/{END}			{aflag |= P_ADDRESS;}
{S}Krefeld/{END}			{aflag |= P_ADDRESS;}
{S}Kronberg/{END}			{aflag |= P_ADDRESS;}
{S}Kuopio/{END}			{aflag |= P_ADDRESS;}
{S}Laatzen/{END}			{aflag |= P_ADDRESS;}
{S}Lahnstein/{END}			{aflag |= P_ADDRESS;}
{S}Lampertheim/{END}		{aflag |= P_ADDRESS;}
{S}Langenhagen/{END}		{aflag |= P_ADDRESS;}
{S}Langenselbold/{END}			{aflag |= P_ADDRESS;}
{S}Leer/{END}			{aflag |= P_ADDRESS | P_WEAK;}
{S}Leinfelden/{END}			{aflag |= P_ADDRESS;}
{S}Leipzig/{END}			{aflag |= P_ADDRESS;}
{S}Leonberg[ ]Sauerlach/{END}			{aflag |= P_ADDRESS;}
{S}Leverkusen/{END}			{aflag |= P_ADDRESS;}
{S}Lippstadt/{END}			{aflag |= P_ADDRESS;}
{S}Lohne/{END}		{aflag |= P_ADDRESS;}
{S}Lubeck/{END}			{aflag |= P_ADDRESS;}  /* u should have umlot over it */
{S}Ludwig/{END}			{aflag |= P_ADDRESS;}
{S}Ludwigsburg/{END}			{aflag |= P_ADDRESS;}
{S}Ludwigslust/{END}			{aflag |= P_ADDRESS;}
{S}Luebeck/{END}			{aflag |= P_ADDRESS;}
{S}Luedenscheid/{END}			{aflag |= P_ADDRESS;}
{S}Lueneburg/{END}			{aflag |= P_ADDRESS;}
{S}Luneburg/{END}			{aflag |= P_ADDRESS;}
{S}Magdeburg/{END}			{aflag |= P_ADDRESS;}
{S}Mainz/{END}			{aflag |= P_ADDRESS;}
{S}Mann/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Mannheim/{END}			{aflag |= P_ADDRESS;}
{S}Marburg/{END}			{aflag |= P_ADDRESS;}
{S}Marienhagen/{END}			{aflag |= P_ADDRESS;}
{S}Marl/{END}			{aflag |= P_ADDRESS;}
{S}Meerane/{END}			{aflag |= P_ADDRESS;}
{S}Meerbusch/{END}			{aflag |= P_ADDRESS;}
{S}Meiningen/{END}			{aflag |= P_ADDRESS;}
{S}Melsungen/{END}		{aflag |= P_ADDRESS;}
{S}Merseberg/{END}			{aflag |= P_ADDRESS;}
{S}Morfelden(" "waldorf)?/{END}			{aflag |= P_ADDRESS;}
{S}Muenchen/{END}			{aflag |= P_ADDRESS;}
{S}Muenster/{END}			{aflag |= P_ADDRESS;}
{S}Troestau/{END}			{aflag |= P_ADDRESS;}
{S}Munchen/{END}			{aflag |= P_ADDRESS;}
{S}Troisdorf/{END}			{aflag |= P_ADDRESS;}
{S}Munich/{END}		{aflag |= P_ADDRESS;}
{S}Munster/{END}			{aflag |= P_ADDRESS;}
{S}Necharsulm/{END}		{aflag |= P_ADDRESS;}
{S}Neu.Isenburg/{END}			{aflag |= P_ADDRESS;}
{S}Neu.Ulm/{END}			{aflag |= P_ADDRESS;}
{S}Neumuenster/{END}			{aflag |= P_ADDRESS;}
{S}Neustadt/{END}			{aflag |= P_ADDRESS;}
{S}New.Isenburg/{END}			{aflag |= P_ADDRESS;}
{S}Niederhausen(" "wiesbaden)/{END}			{aflag |= P_ADDRESS;}
{S}Nordenstadt/{END}			{aflag |= P_ADDRESS;}
{S}Norderstedt/{END}			{aflag |= P_ADDRESS;}
{S}Nuernberg/{END}			{aflag |= P_ADDRESS;}
{S}Numbrecht/{END}			{aflag |= P_ADDRESS;}
{S}Nuremberg/{END}			{aflag |= P_ADDRESS;}
{S}Nurenburg/{END}			{aflag |= P_ADDRESS;}
{S}Nurnberg/{END}			{aflag |= P_ADDRESS;}
{S}Nurtingen/{END}			{aflag |= P_ADDRESS;}
{S}Oberhausen/{END}			{aflag |= P_ADDRESS;}
{S}Oberhof/{END}			{aflag |= P_ADDRESS;}
{S}Oberlahr/{END}			{aflag |= P_ADDRESS;}
{S}Offenbach/{END}			{aflag |= P_ADDRESS;}
{S}Offenburg/{END}			{aflag |= P_ADDRESS;}
{S}Olsberg/{END}			{aflag |= P_ADDRESS;}
{S}Osnabruck/{END}			{aflag |= P_ADDRESS;}
{S}Osnabrueck/{END}			{aflag |= P_ADDRESS;}
{S}Ostseebad/{END}		{aflag |= P_ADDRESS;}
{S}Paderborn/{END}			{aflag |= P_ADDRESS;}
{S}Palma[ ]De[ ]Mallorca/{END}			{aflag |= P_ADDRESS;} /*spain, favorite holiday resort of germans*/
{S}Parsberg/{END}			{aflag |= P_ADDRESS;}
{S}Passau/{END}			{aflag |= P_ADDRESS;}
{S}Peine/{END}			{aflag |= P_ADDRESS;}
{S}Pinzgau/{END}			{aflag |= P_ADDRESS;}
{S}Potsdam/{END}			{aflag |= P_ADDRESS;}
{S}Rastatt/{END}			{aflag |= P_ADDRESS;}
{S}Ratingen/{END}			{aflag |= P_ADDRESS;}
{S}Raunheim/{END}			{aflag |= P_ADDRESS;}
{S}Rauxel/{END}			{aflag |= P_ADDRESS;}
{S}Recklinghausen/{END}			{aflag |= P_ADDRESS;}
{S}Regensburg/{END}			{aflag |= P_ADDRESS;}
{S}Remagen/{END}			{aflag |= P_ADDRESS;}
{S}Remscheid/{END}			{aflag |= P_ADDRESS;}
{S}Reutlingen/{END}			{aflag |= P_ADDRESS;}
{S}Rissen/{END}			{aflag |= P_ADDRESS;}
{S}Rodgau/{END}			{aflag |= P_ADDRESS;}
{S}Roedermark/{END}			{aflag |= P_ADDRESS;}
{S}Rostock/{END}			{aflag |= P_ADDRESS;}
{S}Rothenburg/{END}			{aflag |= P_ADDRESS;}
{S}Rothenburg[ ]Ob[ ]Der[ ]Tauber/{END}			{aflag |= P_ADDRESS;}
{S}Rotz/{END}			{aflag |= P_ADDRESS;}
{S}Ruesselsheim/{END}			{aflag |= P_ADDRESS;}
{S}Rugen/{END}				{aflag |= P_ADDRESS;}
{S}Saarbruecken/{END}			{aflag |= P_ADDRESS;}
{S}Saarlouis/{END}			{aflag |= P_ADDRESS;}
{S}Sachsen[ ]Anhalt/{END}		{aflag |= P_ADDRESS;}
{S}Sarreguemines/{END}			{aflag |= P_ADDRESS;}
{S}Saulgau/{END}			{aflag |= P_ADDRESS;}
{S}Schackendorf/{END}			{aflag |= P_ADDRESS;}
{S}Schangenbad/{END}			{aflag |= P_ADDRESS;}
{S}Schleswig[ ]holstein/{END}			{aflag |= P_ADDRESS;}
{S}Schliersee/{END}			{aflag |= P_ADDRESS;}
{S}Schmallenberg/{END}			{aflag |= P_ADDRESS;}
{S}Schmallenberg[ ]westfeld/{END}			{aflag |= P_ADDRESS;}
{S}Schneverdingen/{END}			{aflag |= P_ADDRESS;}
{S}Schoenheide/{END}			{aflag |= P_ADDRESS;}
{S}Schwerin/{END}			{aflag |= P_ADDRESS;}
{S}Sehnde/{END}			{aflag |= P_ADDRESS;}
{S}Seiffen/{END}			{aflag |= P_ADDRESS;}
{S}Sellin/{END}			{aflag |= P_ADDRESS;}
{S}Siegburg/{END}			{aflag |= P_ADDRESS;}
{S}Siegen/{END}			{aflag |= P_ADDRESS;}
{S}Sindelfingen/{END}			{aflag |= P_ADDRESS;}
{S}Solingen/{END}			{aflag |= P_ADDRESS;}
{S}Solingen[ ]Ohligs/{END}			{aflag |= P_ADDRESS;}
{S}Speyer/{END}			{aflag |= P_ADDRESS;}
{S}Spitzingsee/{END}			{aflag |= P_ADDRESS;}
{S}St.[ ]Peter-ording/{END}			{aflag |= P_ADDRESS;}
{S}Stralsund/{END}			{aflag |= P_ADDRESS;}
{S}Stromberg/{END}			{aflag |= P_ADDRESS;}
{S}Stuttgart/{END}			{aflag |= P_ADDRESS;}
{S}Taucha/{END}				{aflag |= P_ADDRESS;}
{S}Tecklenburg[ ]westfalen/{END}	{aflag |= P_ADDRESS;}
{S}Timmendorfer[ ]Strand/{END}		{aflag |= P_ADDRESS;}
{S}Tossens/{END}			{aflag |= P_ADDRESS;}
{S}Trent/{END}				{aflag |= P_ADDRESS | P_WEAK;}
{S}Triberg/{END}			{aflag |= P_ADDRESS;}
{S}Ulm" "Seligweiler/{END}			{aflag |= P_ADDRESS;}
{S}Ulm/{END}				{aflag |= P_ADDRESS;}
{S}Ulzburg/{END}			{aflag |= P_ADDRESS;}
{S}Unterfoehring/{END}			{aflag |= P_ADDRESS;}
{S}Unterhaching/{END}			{aflag |= P_ADDRESS;}
{S}Uphusen/{END}		{aflag |= P_ADDRESS;}
{S}Viernheim/{END}			{aflag |= P_ADDRESS;}
{S}Vlotho/{END}				{aflag |= P_ADDRESS;}
{S}Walldorf/{END}			{aflag |= P_ADDRESS;}
{S}Walsrode/{END}			{aflag |= P_ADDRESS;}
{S}Weimar/{END}			{aflag |= P_ADDRESS;}
{S}Weimar[ ]Mellingen/{END}		{aflag |= P_ADDRESS;}
{S}Weingarten/{END}			{aflag |= P_ADDRESS;}
{S}Weissenburg/{END}			{aflag |= P_ADDRESS;}
{S}Wenden/{END}			{aflag |= P_ADDRESS;}
{S}Westerland/{END}			{aflag |= P_ADDRESS;}
{S}Westfalen/{END}			{aflag |= P_ADDRESS;}
{S}Wiesbaden/{END}			{aflag |= P_ADDRESS;}
{S}Wiesbaden[ ]hessen/{END}			{aflag |= P_ADDRESS;}
{S}Wilsdruff/{END}			{aflag |= P_ADDRESS;}
{S}Windhagen/{END}			{aflag |= P_ADDRESS;}
{S}Winnenden/{END}			{aflag |= P_ADDRESS;}
{S}Winterbach/{END}			{aflag |= P_ADDRESS;}
{S}Wismar/{END}			{aflag |= P_ADDRESS;}
{S}Wolfenbuettel/{END}			{aflag |= P_ADDRESS;}
{S}Wolfsburg/{END}			{aflag |= P_ADDRESS;}
{S}Worms/{END}			{aflag |= P_ADDRESS;}
{S}Wuerzburg/{END}			{aflag |= P_ADDRESS;}
{S}Wuppertal/{END}			{aflag |= P_ADDRESS;}
{S}Wurzburg/{END}			{aflag |= P_ADDRESS;}
{S}Xanten/{END}			{aflag |= P_ADDRESS;}
{S}Zossen/{END}			{aflag |= P_ADDRESS;}
{S}Zwickau/{END}			{aflag |= P_ADDRESS;}
{S}ausburger/{END}			{aflag |= P_ADDRESS;}
{S}chemnitz/{END}			{aflag |= P_ADDRESS;}
{S}thuringen/{END}			{aflag |= P_ADDRESS;}


  /* Czech cities */
{S}Decin/{END}			{aflag |= P_ADDRESS;}
{S}Usti" "nad" "Labem/{END}			{aflag |= P_ADDRESS;}
{S}Ceska" "Lipa/{END}			{aflag |= P_ADDRESS;}
{S}Litomerice/{END}			{aflag |= P_ADDRESS;}
{S}Most/{END}			{aflag |= P_ADDRESS | P_WEAK;}
{S}Chomutov/{END}			{aflag |= P_ADDRESS;}
{S}Louny/{END}			{aflag |= P_ADDRESS;}
{S}Melnik/{END}			{aflag |= P_ADDRESS;}
{S}Kladno/{END}			{aflag |= P_ADDRESS;}
{S}Praha/{END}			{aflag |= P_ADDRESS;}
{S}Rakovnik/{END}			{aflag |= P_ADDRESS;}
{S}Beroun/{END}			{aflag |= P_ADDRESS;}
{S}Karlovy" "Vary/{END}			{aflag |= P_ADDRESS;}
{S}Sokolov/{END}			{aflag |= P_ADDRESS;}
{S}Cheb/{END}			{aflag |= P_ADDRESS;}
{S}Tachov/{END}			{aflag |= P_ADDRESS;}
{S}Plzen/{END}			{aflag |= P_ADDRESS;}
{S}Rokycany/{END}			{aflag |= P_ADDRESS;}
{S}Pribram/{END}			{aflag |= P_ADDRESS;}
{S}Domazlice/{END}			{aflag |= P_ADDRESS;}
{S}Klatovy/{END}			{aflag |= P_ADDRESS;}
{S}Strakonice/{END}			{aflag |= P_ADDRESS;}
{S}Pisek/{END}			{aflag |= P_ADDRESS;}
{S}Prachatice/{END}			{aflag |= P_ADDRESS;}
{S}Ceske" "Budejovice/{END}			{aflag |= P_ADDRESS;}
{S}Cesky" "Krumlov/{END}			{aflag |= P_ADDRESS;}
{S}Jindrichuv" "Hradec/{END}			{aflag |= P_ADDRESS;}
{S}Tabor/{END}			{aflag |= P_ADDRESS;}
{S}Pelhrimov/{END}			{aflag |= P_ADDRESS;}
{S}Jihlava/{END}			{aflag |= P_ADDRESS;}
{S}Trebic/{END}			{aflag |= P_ADDRESS;}
{S}Znojmo/{END}			{aflag |= P_ADDRESS;}
{S}Havlickuv" "Brod/{END}			{aflag |= P_ADDRESS;}
{S}Zdar" "nad" "Sazavou/{END}			{aflag |= P_ADDRESS;}
{S}Benesov/{END}			{aflag |= P_ADDRESS;}
{S}Kutna" "Hora/{END}			{aflag |= P_ADDRESS;}
{S}Chrudim/{END}			{aflag |= P_ADDRESS;}
{S}Kolin/{END}			{aflag |= P_ADDRESS;}
{S}Pardubice/{END}			{aflag |= P_ADDRESS;}
{S}Hradec" "Kralove/{END}			{aflag |= P_ADDRESS;}
{S}Nymburk/{END}			{aflag |= P_ADDRESS;}
{S}Mlada" "Boleslav/{END}			{aflag |= P_ADDRESS;}
{S}Jicin/{END}			{aflag |= P_ADDRESS;}
{S}Semily/{END}			{aflag |= P_ADDRESS;}
{S}Jablonec" "nad" "Nisou/{END}			{aflag |= P_ADDRESS;}
{S}Liberec/{END}			{aflag |= P_ADDRESS;}
{S}Trutnov/{END}			{aflag |= P_ADDRESS;}
{S}Nachod/{END}			{aflag |= P_ADDRESS;}
{S}Rychnov" "nad" "Kneznou/{END}			{aflag |= P_ADDRESS;}
{S}Usti" "nad" "Orlici/{END}			{aflag |= P_ADDRESS;}
{S}Svitavy/{END}			{aflag |= P_ADDRESS;}
{S}Blansko/{END}			{aflag |= P_ADDRESS;}
{S}Brno/{END}			{aflag |= P_ADDRESS;}
{S}Breclav/{END}			{aflag |= P_ADDRESS;}
{S}Hodonin/{END}			{aflag |= P_ADDRESS;}
{S}Uherske" "Hradiste/{END}			{aflag |= P_ADDRESS;}
{S}Zlin/{END}			{aflag |= P_ADDRESS;}
{S}Vsetin/{END}			{aflag |= P_ADDRESS;}
{S}Kromeriz/{END}			{aflag |= P_ADDRESS;}
{S}Vyskov/{END}			{aflag |= P_ADDRESS;}
{S}Prostejov/{END}			{aflag |= P_ADDRESS;}
{S}Prerov/{END}			{aflag |= P_ADDRESS;}
{S}Olomouc/{END}			{aflag |= P_ADDRESS;}
{S}Novy" "Jicin/{END}			{aflag |= P_ADDRESS;}
{S}Frydek-Mistek/{END}			{aflag |= P_ADDRESS;}
{S}Ostrava/{END}			{aflag |= P_ADDRESS;}
{S}Karvina/{END}			{aflag |= P_ADDRESS;}
{S}Opava/{END}			{aflag |= P_ADDRESS;}
{S}Bruntal/{END}			{aflag |= P_ADDRESS;}
{S}Sumperk/{END}			{aflag |= P_ADDRESS;}
{S}Vinohrady/{END}		{aflag |= P_ADDRESS;}
{S}Nova" "Ves" "pod" "Plesi/{END}              {aflag |= P_ADDRESS;}
{S}Nova" "Ves/{END}              {aflag |= P_ADDRESS;}
{S}Lhota/{END}			{aflag |= P_ADDRESS;}
{S}Mesto/{END}				{aflag |= P_ADDRESS;}




{S}JEWISH/{END}			{aflag |= P_ADDRESS;}
{S}CATHOLIC/{END}		{aflag |= P_ADDRESS;}
{S}CHRISTIAN/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}ISLAMIC/{END}		{aflag |= P_ADDRESS;}
{S}ISLAM/{END}			{aflag |= P_ADDRESS | P_WEAK;}
{S}SERBIAN/{END}		{aflag |= P_ADDRESS;}
{S}CROTIAN/{END}		{aflag |= P_ADDRESS;}
{S}ITALIAN/{END}		{aflag |= P_ADDRESS;}

{S}Abilene('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Aiken('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Akron('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Albany('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Albuquerque('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Alexandria('S)?/{END}	   {aflag |= P_ADDRESS  | P_WEAK;}
{S}Allentown('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Altoona('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Amarillo('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Anchorage('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Anderson('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Ann" "Arbor('S)?/{END}	{aflag |= P_ADDRESS;}
{S}Anniston('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Appleton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Arlington('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Asheville('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Ashland('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Atascadero('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Athens('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Atlanta('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Atlantic('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Auburn('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Augusta('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Austin('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Bakersfield('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Baltimore('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Bangor('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Barnstable('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Baton" "Rouge('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Battle" "Creek('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Bryan('S)?/{END}	    {aflag |= P_ADDRESS | P_WEAK;}
{S}Bay" "City('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Beaumont('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Bellevue('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Bellingham('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Beloit('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Benton" "Harbor('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Bergen('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Bethlehem('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Billings('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Biloxi('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Binghamton('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Birmingham('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Bismarck('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Bloomington('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Boca" "Raton('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Boise" "City('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Bossier" "City('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Boston('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Boulder('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Bradenton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Brazoria('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Bremerton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Bridgeport('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Bridgeton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Bristol('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Brockton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Brownsville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Buffalo('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Burlington('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Canton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Cape" "Coral('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Cape" "May('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Cape" "Cod('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Cape" "Fear('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Cape" "Horn('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Carlisle('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Casper('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Cedar" "Falls('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Cedar" "Rapids('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Champaign('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Chapel" "Hill('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Charleston('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Charlotte('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Charlottesville('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Chattanooga('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Cheyenne('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Chicago('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Chico('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Cincinnati('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Clarksville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Clearwater('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Cleveland('S)?/{END}		{aflag |= P_ADDRESS;}
{S}College" "Station('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Colorado" "Springs('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Columbia('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Corpus" "Christi('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Cumberland('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Dallas('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Danbury('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Danville('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Dayton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Daytona" "Beach('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Davenport('S)?/{END}		{aflag |= P_ADDRESS|P_WEAK;}
{S}Decatur('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Denver('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Denison('S)?/{END}		{aflag |= P_ADDRESS|P_WEAK;}
{S}Des" "Moines('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Detroit('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Dothan('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Dover('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Dubuque('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Duluth('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Durham('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Dutchess" "County('S)?/{END}		{aflag |= P_ADDRESS;}
{S}East" "Lansing('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Easton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Eau" "Claire('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Edinburg('S)?/{END}		{aflag |= P_ADDRESS;}
{S}El" "Paso('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Elkhart('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Elmira('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Elyria('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Enid('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Erie('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Eugene('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Evansville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Everett('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Fairfield('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Fall" "River('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Fargo('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Fayetteville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Fitchburg('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Flagstaff('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Flint('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Florence('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Fort" "Collins('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Fort" "Lauderdale('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Fort" "Myers('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Fort" "Pierce('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Fort" "Smith('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Fort" "Walton" "Beach('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Fort" "Wayne('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Fort" "Worth('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Fresno('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Gadsden('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Gainesville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Galveston('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Gastonia('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Gary('S)?/{END}	    {aflag |= P_ADDRESS|P_WEAK;}
{S}Glens" "Falls('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Goldsboro('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Goshen('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Grand" "Forks('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Grand" "Junction('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Grand" "Rapids('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Great" "Falls('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Greeley('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Green" "Bay('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Greensboro('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Greenville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Gulfport('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Hagerstown('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Hamilton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Harlingen('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Harrisburg('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Hartford('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Hattiesburg('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Hazleton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Henderson('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Hickory('S)?/{END}		{aflag |= P_ADDRESS;}
{S}High" "Point('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Holland('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Honolulu('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Hopkinsville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Houma('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Houston('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Hunterdon('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Huntington('S)?/{END}	{aflag |= P_ADDRESS;}
{S}Huntsville('S)?/{END}	{aflag |= P_ADDRESS;}
{S}Indianapolis('S)?/{END}	{aflag |= P_ADDRESS;}
{S}Iowa" "City('S)?/{END}	{aflag |= P_ADDRESS;}
{S}Jackson('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Jacksonville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Jamestown('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Janesville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Jersey" "City('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Johnson" "City('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Johnstown('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Jonesboro('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Joplin('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Kalamazoo('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Kankakee('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Kansas" "City('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Kennewick('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Kenosha('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Killeen('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Kingsport('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Knoxville('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Kokomo('S)?/{END}		{aflag |= P_ADDRESS;}
{S}La" "Crosse('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Lafayette('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Lake" "Charles('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Lakeland('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Lancaster('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Lansing('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Laredo('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Las" "Cruces('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Las" "Vegas('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Lawrence('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Lawton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Lebanon('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Lenoir('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Leominster('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Lewiston('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Lexington('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Lima('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Lincoln('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Little" "Rock('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Lodi('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Lompoc('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Long" "Beach('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Longmont('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Longview('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Lorain('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Los" "Angeles('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Louisville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Loveland('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Lowell('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Lubbock('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Lynchburg('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Macon('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Madison('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Manchester('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Mansfield('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Marietta('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Marshall('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Manhattan('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Massillon('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Mcallen('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Medford('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Melbourne('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Memphis('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Merced('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Meriden('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Mesa('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Miami('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Middlesex('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Middletown('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Midland('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Millville('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Milwaukee('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Minneapolis('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Mission('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Missoula('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Mobile('S)?/{END}		{aflag |= P_ADDRESS|P_WEAK;}
{S}Modesto('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Moline('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Monmouth('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Monroe('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Montgomery('S)?/{END}	    {aflag |= P_ADDRESS | P_WEAK;}
{S}Moorhead('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Morganton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Muncie('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Muskegon('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Myrtle" "Beach('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Napa('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Naples('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Nashua('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Nashville('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Nassau('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Neenah('S)?/{END}		{aflag |= P_ADDRESS;}
{S}New" "Bedford('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}New" "Haven('S)?/{END}		{aflag |= P_ADDRESS;}
{S}New" "London('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}New" "Orleans('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}New" "York('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Newark('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Newburgh('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Newport" "News('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Niagara" "Falls('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Norfolk('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Normal('S)?/{END}		{aflag |= P_ADDRESS;}
{S}North" "Charleston('S)?/{END}		{aflag |= P_ADDRESS;}
{S}North" "Little" "Rock('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Norwalk('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Norwich('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Oakland('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Ocala('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Ocean('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Odessa('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Ogden('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Oklahoma" "City('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Olympia('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Omaha('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Orange" "County('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Orem('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Orlando('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Oshkosh('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Owensboro('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Palm" "Bay('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Panama" "City('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Paradise('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Parkersburg('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Pascagoula('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Pasco('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Paso" "Robles('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Passaic('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Pekin('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Pensacola('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Peoria('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Petersburg('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Philadelphia('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Phoenix('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Pine" "Bluff('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Pittsburgh('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Pittsfield('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Pocatello('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Port" "Arthur('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Port" "St." "Lucie('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Porterville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Portland('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Portsmouth('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Providence('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Provo('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Pueblo('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Punta" "Gorda('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Racine('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Raleigh('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Rapid" "City('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Reading('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Redding('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Reno('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Richland('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Richmond('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Riverside('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Roanoke('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Rochester('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Rock" "Hill('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Rock" "Island('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Rockford('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Rocky" "Mount('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Rogers('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Rome('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Sacramento('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Saginaw('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Salem('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Salinas('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Salt" "Lake" "City('S)?/{END}		{aflag |= P_ADDRESS;}
{S}San" "Angelo('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}San" "Antonio('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}San" "Benito('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}San" "Bernardino('S)?/{END}		{aflag |= P_ADDRESS;}
{S}San" "Diego('S)?/{END}		{aflag |= P_ADDRESS;}
{S}San" "Francisco('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}San" "Jose('S)?/{END}		{aflag |= P_ADDRESS;}
{S}San" "Luis" "Obispo('S)?/{END}		{aflag |= P_ADDRESS;}
{S}San" "Marcos('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Santa" "Barbara('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Santa" "Cruz('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Santa" "Fe('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Santa" "Maria('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Santa" "Rosa('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Sarasota('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Savannah('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Schenectady('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Scranton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Seattle('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Sheboygan('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Sherman('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Sharon('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Shreveport('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Sioux" "City('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Sioux" "Falls('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Somerset('S)?/{END}		{aflag |= P_ADDRESS;}
{S}South" "Bend('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Spartanburg('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Spokane('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Springdale('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Springfield('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}St." "Cloud('S)?/{END}		{aflag |= P_ADDRESS;}
{S}St." "Joseph('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}St." "Louis('S)?/{END}		{aflag |= P_ADDRESS;}
{S}St." "Paul('S)?/{END}		{aflag |= P_ADDRESS;}
{S}St." "Petersburg('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Stamford('S)?/{END}		{aflag |= P_ADDRESS;}
{S}State" "College('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Steubenville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Stockton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Suffolk('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Sumter('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Superior('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Syracuse('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Tacoma('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Tallahassee('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Tampa('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Temple('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Terre" "Haute('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Texarkana('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Texas" "City('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Titusville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Toledo('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Topeka('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Trenton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Troy('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Tucson('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Tulare('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Tulsa('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Tuscaloosa('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Tyler('S)?/{END}	    {aflag |= P_ADDRESS | P_WEAK;}
{S}Urbana('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Utica('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Vallejo('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Vancouver('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Ventura('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Victoria('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Vineland('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Virginia" "Beach('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Visalia('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Waco('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Warwick('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Washington('S)?/{END}	    {aflag |= P_ADDRESS | P_WEAK;}
{S}Warren('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Waterbury('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Waterloo('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Watsonville('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Waukesha('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Wausau('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Weirton('S)?/{END}		{aflag |= P_ADDRESS;}
{S}West" "Palm" "Beach('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Wheeling('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Wichita('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Wichita" "Falls('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Wilkes-Barre('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Williamsport('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Wilmington('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Winston('S)?/{END}		{aflag |= P_ADDRESS | P_WEAK;}
{S}Winter" "Haven('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Worcester('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Yakima('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Yarmouth('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Yolo('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}York('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Youngstown('S)?/{END}	    {aflag |= P_ADDRESS;}
{S}Yuba" "City('S)?/{END}		{aflag |= P_ADDRESS;}
{S}Yuma('S)?/{END}	    {aflag |= P_ADDRESS;}


{S}ATLANTIC" "CITY/{END}		{aflag |= P_ADDRESS;} 
{S}MIAMI" "BEACH/{END}		{aflag |= P_ADDRESS;} 
{S}ACAPULCO/{END}		{aflag |= P_ADDRESS;} 
{S}BEIJING/{END}		{aflag |= P_ADDRESS;} 
{S}CANCUN/{END}		{aflag |= P_ADDRESS;} 
{S}COPENHAGEN/{END}		{aflag |= P_ADDRESS;} 
{S}HELSINKI/{END}		{aflag |= P_ADDRESS;} 
{S}MONTREAL/{END}		{aflag |= P_ADDRESS;} 
{S}NICE/{END}		{aflag |= P_ADDRESS;} 
{S}VENICE/{END}		{aflag |= P_ADDRESS;}
{S}AMSTERDAM/{END}		{aflag |= P_ADDRESS;} 
{S}BRUSSELS/{END}		{aflag |= P_ADDRESS;} 
{S}CANNES/{END}		{aflag |= P_ADDRESS;} 
{S}DUBLIN/{END}		{aflag |= P_ADDRESS;} 
{S}GENEVA/{END}		{aflag |= P_ADDRESS;} 
{S}LISBON/{END}		{aflag |= P_ADDRESS;} 
{S}MEXICO" "CITY/{END}		{aflag |= P_ADDRESS;} 
{S}MOSCOW/{END}		{aflag |= P_ADDRESS;} 
{S}SALZBURG/{END}		{aflag |= P_ADDRESS;} 
{S}VIENNA/{END}		{aflag |= P_ADDRESS;}
{S}BARCELONA/{END}		{aflag |= P_ADDRESS;} 
{S}BUDAPEST/{END}		{aflag |= P_ADDRESS;} 
#{S}COLOGNE/{END}		{aflag |= P_ADDRESS;} 
{S}EDINBURGH/{END}		{aflag |= P_ADDRESS;} 
{S}SARAJEVO/{END}		{aflag |= P_ADDRESS;} 
{S}MILAN/{END}		{aflag |= P_ADDRESS;}
#{S}MUNICH/{END}	{aflag |= P_ADDRESS;} 
{S}PRAGUE/{END}		{aflag |= P_ADDRESS;} 
{S}STOCKHOLM/{END}		{aflag |= P_ADDRESS;} 
{S}ZURICH/{END}		{aflag |= P_ADDRESS;} 
{S}PICCADILLY		{aflag |= P_ADDRESS;} 

{S}TOKYO/{END}		{aflag |= P_ADDRESS;}
{S}SIAGON/{END}		{aflag |= P_ADDRESS;}

{S}Sydney/{END}		{aflag |= P_ADDRESS;}
{S}Brisbane/{END}	{aflag |= P_ADDRESS;}
{S}Adelaide/{END}	{aflag |= P_ADDRESS;}
#{S}Melbourne/{END}	{aflag |= P_ADDRESS;} /* appears above */
{S}Hobart/{END}		{aflag |= P_ADDRESS;}
{S}Canberra/{END}	{aflag |= P_ADDRESS;}
{S}Darwin/{END}		{aflag |= P_ADDRESS| P_WEAK;}
{S}Perth/{END}		{aflag |= P_ADDRESS;}
{S}Windsor/{END}	{aflag |= P_ADDRESS;}
#{S}Richmond/{END}	{aflag |= P_ADDRESS;} /* appears above */
{S}Colo/{END}		{aflag |= P_ADDRESS;}
{S}Lower" "Colo/{END}	{aflag |= P_ADDRESS;}
{S}Upper" "Colo/{END}	{aflag |= P_ADDRESS;}
{S}Lower" "Portland/{END}	{aflag |= P_ADDRESS;}

 /* Canada, from http://www.demographia.com/db-cancma.htm */

{S}Toronto/{END}		{aflag |= P_ADDRESS;}
 /* {S}Montreal/{END}		{aflag |= P_ADDRESS;}*/
 /* {S}Vancouver/{END}		{aflag |= P_ADDRESS;}*/
{S}Ottawa-Hull/{END}		{aflag |= P_ADDRESS;}
{S}Edmonton/{END}		{aflag |= P_ADDRESS;}
{S}Calgary/{END}		{aflag |= P_ADDRESS;}
{S}Quebec/{END}			{aflag |= P_ADDRESS;}
{S}Winnipeg/{END}		{aflag |= P_ADDRESS;}
 /*{S}Hamilton/{END}		{aflag |= P_ADDRESS;} */
 /*{S}London/{END}			{aflag |= P_ADDRESS;} */
{S}Kichener/{END}		{aflag |= P_ADDRESS;}
{S}St". "Catherines/{END}	{aflag |= P_ADDRESS;}
{S}Niagara(" "Falls)?/{END}	{aflag |= P_ADDRESS;}
{S}Falls/{END}			{aflag |= P_ADDRESS;}
{S}Halifax/{END}		{aflag |= P_ADDRESS;}
 /*{S}Victoria/{END}		{aflag |= P_ADDRESS;} */
 /*{S}Windsor/{END}		{aflag |= P_ADDRESS;}*/
{S}Oshawa/{END}			{aflag |= P_ADDRESS;}
{S}Saskatoon/{END}		{aflag |= P_ADDRESS;}
{S}Regina/{END}			{aflag |= P_ADDRESS | P_WEAK;}
{S}St". "John\'s/{END}		{aflag |= P_ADDRESS;}
{S}Chicoutimi-Jonque/{END}	{aflag |= P_ADDRESS;}
{S}Sudbury/{END}		{aflag |= P_ADDRESS;}
{S}Sherbrooke/{END}		{aflag |= P_ADDRESS;}
{S}Trois-Rivere/{END}		{aflag |= P_ADDRESS;}
{S}Thunder" "Bay/{END}		{aflag |= P_ADDRESS;}
{S}Saint" "John/{END}		{aflag |= P_ADDRESS;}



{S}att(entio)?n[.]?[:][ ]	{aflag |= P_ADDRESS;}		/* 3-29-94 */

\001[ ]*{USZIP}[ ]*\032			{aflag |= P_ADDRESS | P_ZIP; /* zip on a line by itself */}
\001[ ]*{CANADAZIP}[ ]*\032		{aflag |= P_ADDRESS | P_ZIP; /* zip on a line by itself */}
\001[ ]*{UKZIP}[ ]*\032		{aflag |= P_ADDRESS | P_ZIP; /* zip on a line by itself */}
\001[ ]*[0-9]{5}" "[A-Z]{3,}[ ]*\032	{aflag |= P_ADDRESS; /* looks like germany */}

\001[ ]*[0-9]{4}" "?[A-Z][A-Z]" "	{aflag |= P_ADDRESS | P_ZIP; /* Amsterdam */}

[A-Z]{4,}[ ]+{N}{2,}[/]{N}{2,}		{aflag |= P_ADDRESS;} /* Those wacky Czech addresses */


.					{} /* by default, ignore, but look for more stuff */

%%

unsigned int	parse_address(const char *buf)
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
	PSHUTDOWN();
	return aflag;
}
