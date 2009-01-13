#!/usr/bin/perl
# http://www.ssa.gov/OACT/babynames/1999/top1000of90s.html
# Babynames come from:

use strict;
my %name;

my @files = qw(top1000of50s.html
	       top1000of60s.html);

foreach $_ (@files){
    open(F,$_) || die "Cannot open $_";
    while(<F>){
	if(m:<td>([a-z]+)</td>.*<td>([a-z]+)</td>:i){
	    $name{$1}=1;
	    $name{$2}=1;
	}
    }
}

print <<XX;
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
%option case-insensitive
%option pointer
%option prefix="firstname"

S	[ ]
END	[^a-zA-Z]

%%
XX


foreach $_ (sort keys %name){
    print "{S}",$_,"/{END}\t\t{aflag=P_FIRST_NAME;}\n";
}

print <<XX;

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
XX
