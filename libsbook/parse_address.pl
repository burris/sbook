#!/usr/bin/perl

#
#
# Copyright (C) 1991, 1992, 2000,2001,2002 Simson L. Garfinkel
# All rights reserved.
# parse_address.pl:
# Generates parse_address.flex from parse_address.txt
#

use strict;

my @includes = qw(libsbook.h flexhdr.h);
my @options  = qw(noyywrap 8bit batch case-insensitive pointer);
my $prefix   = 'yyaddress';
my $function = 'parse_address';

sub header {
    print "%{\n";
    foreach $_ (@includes){
	print "#include \"$_\"\n";
    }
    print "\n";
    
    print "static	unsigned int	aflag=0;\n";
    print "unsigned int pa_debug=0;\n";
    print "%}\n";

    foreach $_ (@includes){
	print "%option $_\n";
    }
    print "%option prefix=\"$prefix\"\n";

}

sub macros {
    print <<XX;
N	[0-9]
S	[ \-\001]
H	[a-zA-Z0-9\.\-_=+]
W	[ ][A-Z]+[ ]+
END	[^a-zA-Z]
P	[., ]
USZIP	[0-9]{5}(-[0-9]{4})?
CANADAZIP	([a-z][0-9][a-z]" "[0-9][a-z][0-9])
CZECHZIP	([0-9]{3}[ ]?[0-9]{2})
GENERICZIP	({USZIP}|{CANADAZIP}|{CZECHZIP})

STATE	((alabama)|(alaska)|(arizona)|(arkansas)|(california)|(canal[ ]zone)|(colorado)|(connecticut)|(delaware)|(florida)|(georgia)|(guam)|(hawaii)|(idaho)|(illinois)|(indiana)|(iowa)|(kansas)|(kentucky)|(louisiana)|(maine)|(maryland)|(massachusetts)|(michigan)|(minnesota)|(minn)|(mississippi)|(missouri)|(montana)|(nebraska)|(nevada)|(new[ ]hampshire)|(new[ ]jersey)|(new[ ]mexico)|(new[ ]york)|(north[ ]carolina)|(north[ ]dakota)|(ohio)|(oklahoma)|(oregon)|(pennsylvania)|(penn)|(puerto[ ]rico)|(rhode[ ]island)|(south[ ]carolina)|(south[ ]dakota)|(tennessee)|(texas)|(utah)|(vermont)|(virginia)|(virgin[ ]islands)|(washington)|(west[ ]virginia)|(wisconsin)|(wyoming))

EMAIL	([a-z0-9]([_+a-z0-9\-])*)
EMAILWITHDOT	({EMAIL}([.]{EMAIL})*)
DOMAIN	(com|edu|net|org|mil|biz|uk|de|fr|jp|biz|cz)
%%
}
XX

sub parse_function {
    print <<XX;
unsigned int	${function}(const char *buf)
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
	PSHUTDOWN;
	return aflag;
}
XX


sub main{
    &header();
    &macros();
    &parse_function();
}


