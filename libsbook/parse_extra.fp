%{
//
//	Copyright (C) 2002 Simson L. Garfinkel
//	All rights reserved.
//
//	parse_extra: extra parsers

#include "libsbook.h"
#include "flexhdr.h"

static	unsigned int	aflag=0;
			
%}

%option noyywrap
%option 8bit
%option batch
%option case-insensitive
%option pointer
%option prefix="yyextra"

S	[ \001]
END	[^a-zA-Z]
P	[., ]

%%

[^:][:][ ]*\032			{aflag |=P_LABEL;}
[\001 ]*[a-z0-9#]+":"[^/]	{aflag |=P_LABEL;}
[\001 ]*[a-z0-9# ]{1,10}":"[^/]	{aflag |=P_LABEL;}

[\001 ]*~[a-zA-Z/0-9\_\-]{6}	{aflag |= P_FILE;}

{S}general/{END}		{aflag |= P_TITLE;}
{S}major/{END}			{aflag |= P_TITLE;}
{S}director/{END}		{aflag |= P_TITLE;}
{S}CIO/{END}			{aflag |= P_TITLE;}
{S}Chief/{END}			{aflag |= P_TITLE;}
{S}Columnist/{END}		{aflag |= P_TITLE;}
{S}professor/{END}		{aflag |= P_TITLE;}
{S}editor/{END}			{aflag |= P_TITLE;}
{S}senior/{END}			{aflag |= P_TITLE;}
{S}junior/{END}			{aflag |= P_TITLE;}
{S}engineer/{END}		{aflag |= P_TITLE;}
{S}customer/{END}		{aflag |= P_TITLE;}
{S}representative/{END}		{aflag |= P_TITLE;}
{S}Hypnotherapist/{END}		{aflag |= P_TITLE;}
{S}planner/{END}		{aflag |= P_TITLE;}
{S}president/{END}		{aflag |= P_TITLE;}
{S}consultant/{END}		{aflag |= P_TITLE;}
{S}writer/{END}			{aflag |= P_TITLE;}
{S}assistant/{END}		{aflag |= P_TITLE;}
{S}manager/{END}		{aflag |= P_TITLE;}
{S}student/{END}		{aflag |= P_TITLE;}
{S}VP/{END}			{aflag |= P_TITLE;}
{S}officer/{END}		{aflag |= P_TITLE;}
{S}chairman/{END}		{aflag |= P_TITLE;}
{S}managing/{END}		{aflag |= P_TITLE;}
{S}founder/{END}		{aflag |= P_TITLE;}
{S}ceo/{END}			{aflag |= P_TITLE;}
{S}cfo/{END}			{aflag |= P_TITLE;}
{S}cpo/{END}			{aflag |= P_TITLE;}
{S}analyist/{END}		{aflag |= P_TITLE;}
{S}programmer/{END}		{aflag |= P_TITLE;}
{S}executive/{END}		{aflag |= P_TITLE;}


.						{}

%%



unsigned int	parse_extra(const char *buf)
{
	char	*mbuf	= (char*)alloca(strlen(buf)+16);
	char	*cc;
	const	char *dd;

	cc	= mbuf;
	*cc++	= 1;                    /* beginning of line */
	*cc++	= ' ';			/* Put in a space */
	for(dd=buf;*dd;dd++,cc++){
		*cc = *dd;
		if(*cc == '\t') *cc = ' ';
	}
	*cc++	= ' ';
	*cc++	= 26;                 /* end with a control-z */
	*cc++	= EOF;
	*cc++	= '\000';
	
	aflag	= 0;

	PSETUP(mbuf,strlen(mbuf));
	yylex();		/* DO IT! */
	PSHUTDOWN;

	return aflag;
}
