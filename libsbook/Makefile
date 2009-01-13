#
# $Id: Makefile,v 1.18 2004/07/21 03:18:14 simsong Exp $
#


LIBOBJS=sbook_parser.o parse_address.o parse_company.o parse_case.o parse_extra.o parse_stocks.o \
	parse_time.o parse_month.o parse_email.o \
	match.o smartsort.o nxatom.o hashtable.o metaphone.o blowfish.o md5.o \
	find_zip.o parse_telephone.o entrylist.o entry.o misc.o base64.o vcard.o \
	parse_firstname.o \
	encrypted_object.o

PARSERS = parse_case.cpp parse_case.cpp parse_stocks.cpp parse_time.cpp parse_month.cpp \
	parse_email.cpp parse_telephone.cpp parse_firstname.cpp

LIB=libsbook.a
FLEXPP=./flexpp
FLEX=flex
SED=sed
EXPAT=../expat/xmlparse/libexpat.a

INCDIRS=-I../../sand/slib -I../expat/xmlparse \
	-I/usr/include/g++ -I/usr/local/include/w3c-libwww

FLEXOPTS=-tL8B -f -p -Ce -Cf
CFLAGS   = -g -I. -Wall -DUNIX $(INCDIRS)
CPPFLAGS = -g -I. -Wall -DUNIX $(INCDIRS)

ifeq ($(OSTYPE),darwin)
CC	:= gcc
CXX	:= g++
CFLAGS   += -D__APPLE__ -DCFLAGS
CPPFLAGS += -ObjC++ -D__APPLE__ -DCPPFLAGS
endif


# had -pthread


all: $(LIB) query sbookreader

parsers: $(PARSERS)

t: query 
	./query -V < tests/slg.txt
#	./query -c tests/test.people
#	./query -p tests/test.corps

web: query 
	cp query   /usr/home/www/sbook5.com/

query: query.o $(LIB)
	    $(CXX) -o query query.o $(LIB) 

sbook_parser.o: libsbook.h

TAGS: 
	etags *.cpp *.c

$(LIB): $(LIBOBJS) 
	/bin/rm -rf $(LIB)
	ar -r $(LIB) $(LIBOBJS)
	ranlib $(LIB)

clean:
	rm -f parse_*.cpp
	rm -f *.o
	rm -f *.lib
	rm -f query
	rm -f *.a
	rm -f query web lex.vcard.c
	rm -f parse_firstname.cpp

#
# vCard stuff is still under development
#
vcard.o:	vcard.cpp 
vcard.tab.o:	vcard.tab.c 
lex.vcard.o:	lex.vcard.c

vcard.tab.c:	vcard.y
	bison -b vcard -d -p vcard vcard.y

lex.vcard.c:	vcard.lex
	$(FLEX) -Pvcard vcard.lex


parse_company.cpp: company_names.txt

parse_firstname.fp: parse_firstname.pl
	perl parse_firstname.pl > parse_firstname.fp

# .fp is the flex pre-processor

.SUFFIXES: .fp
.fp.cpp: 
	$(FLEXPP) $< > $<.flex
	$(FLEX)  $(FLEXOPTS) $<.flex  > `basename $< .fp`.cpp
	/bin/rm $<.flex



#
# sbookreader - read and write SBook XML file
#
sbookreader: $(LIB) sbookreader.o 
	$(CXX) -o sbookreader sbookreader.o $(LIB) $(EXPAT) 


searcher: searcher.o
	$(CXX) -o searcher searcher.o 

#.SUFFIXES: .cpp
#.cpp.o:
#	$(CXX) -c $(CPPFLAGS) $(INCPATH) $<

