%{
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>
#include "libsbook.h"
#include "vcard.tab.h"

    int vcard_lval;

%}


%pointer
%option 8bit
%option caseless
%option fast
%option batch
%option never-interactive
%option noyywrap

%x arg tag name value

NUM	[0-9.]+
ST2	[^\n\r]+
EOL	[\r\n]



%%


<*>":"			BEGIN(arg);return COLON;
<*>";"			return SEMICOLON;



BEGIN:" "*VCARD		return BEGIN_VCARD;
END:" "*VCARD		return END_VCARD;

^FN			BEGIN(tag);return FN;
^N			BEGIN(tag);return N;
^NICKNAME		BEGIN(tag);return NICKNAME;
^PHOTO			BEGIN(name);return PHOTO;

^VERSION		BEGIN(tag);return VERSION;
^REV			BEGIN(tag);return REV;
^UID			BEGIN(tag);return UID;
^ORG			BEGIN(tag);return ORG;
^TEL			BEGIN(tag);return TEL;
^EMAIL			BEGIN(tag);return EMAIL;
^ADR			BEGIN(tag);return ADR;
^NOTE			BEGIN(tag);return NOTE;
^URL			BEGIN(tag);return URL;
^TITLE			BEGIN(tag);return TITLE;
^X-[^;:]+		BEGIN(tag);return XTAG;

<tag>[^;:\n\r]+		{vcard_lval = str_alloc(yytext); printf("tag=>%s<\n",yytext);return TAG; } 
<arg>[^\n\r]+		{vcard_lval = str_alloc(yytext); printf("arg=>%s<\n",yytext);BEGIN(INITIAL); return STRING; } 

<name>[^=]+		{vcard_lval = str_alloc(yytext); printf("name=>%s<\n",yytext);return NAME; } 
<name>"="		BEGIN(value);return EQUALS;
<value>([^;]|("\;"))+	{vcard_lval = str_alloc(yytext); printf("value=>%s<\n",yytext);BEGIN(name); return VALUE; } 

<*>[\r\n]		BEGIN(INITIAL);/* ignore blanklines */;



%%

void  vcarderror(const char *buf)
{
    if(0) yyunput(0,0);
    fprintf(stderr,"\n\nyyerror  yytext='%s' buf='%s'\n\n\n",yytext,buf);
}


int numstrings = 0;
char **strings = 0;
int parsererror(const char *str)
{
    fprintf(stderr,"gvparser error: %s\n",str);
    return 0;
}

void str_init()
{
    strings = (char **)malloc(0);
    numstrings = 0;
}

int str_freeall()
{
    int i;

    for(i=0;i<numstrings;i++){
	free(strings[i]);
    }
    strings = realloc(strings,0);
    return 0;
}

int str_alloc(const char *strbuf)
{
    int i;

    /* See if it is a string we were given */
    for(i=0;i<numstrings;i++){
	if(!strcmp(strings[i],strbuf)) return i;
    }

    /* Allocate a new string */
    strings = (char **)realloc(strings,(numstrings+1) * sizeof(char *));
    strings[numstrings] = strdup(strbuf);
    return numstrings++;
}

int str_allocq(const char *strbuf)
{
    int len = strlen(strbuf);
    char *buf2 = (char *)alloca(len);
    memcpy(buf2,strbuf+1,len-2);
    buf2[len-2] = '\000';
    return str_alloc(buf2);
}

const char *str_num(int i)
{
    assert(i>=0 && i<numstrings);
    return strings[i];
}
