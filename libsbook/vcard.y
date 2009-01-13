%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "libsbook.h"
#include "vcard.tab.h"
    extern char *vcardtext;

%}	 

%start document

%token COLON TAG STRING NAME VALUE EQUALS SEMICOLON XTAG

%token BEGIN_VCARD END_VCARD
%token NAME PROFILE SOURCE
%token FN N NICKNAME PHOTO BDAY
%token ADR LABEL
%token TEL EMAIL MAILER
%token TZ GEO
%token TITLE ROLE LOGO AGENT ORG
%token CATEGORIES NOTE PRODID REV SORTSTRING SOUND UID URL VERSION
%token CLASS KEY

%%

document: vcards
;

vcards: vcard vcards
| vcard
;

vcard: BEGIN_VCARD END_VCARD
| BEGIN_VCARD vstatements END_VCARD 
;

vstatements: vstatement
| vstatement vstatements
;

vstatement:
VERSION COLON STRING {printf("got version %s\n",str_num($3));}
| REV tags COLON STRING
| FN COLON STRING
| N COLON STRING
| NICKNAME tags COLON STRING
| PHOTO SEMICOLON namevalues

| UID tags COLON STRING
| ORG tags COLON STRING 
| TEL tags COLON STRING
| EMAIL tags COLON STRING
| FN tags COLON STRING
| ADR tags COLON STRING
| NOTE tags COLON STRING
| URL tags COLON STRING
| TITLE tags COLON STRING
| XTAG tags COLON STRING
;

tags:
| SEMICOLON TAG 
| SEMICOLON TAG tags;

namevalues:
| NAME EQUALS VALUE 
| NAME EQUALS VALUE SEMICOLON namevalues
;
