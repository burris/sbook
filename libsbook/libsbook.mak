OBJS=parse_address.obj parse_company.obj parse_case.obj match.obj nxatom.obj hashtable.obj parse_stocks.obj getopt.obj smartsort.obj

FLEX=c:\cygwin\bin\flex
SED=c:\cygwin\bin\sed
FLEXOPTS=-tL8B 
FLEXCASE=-i
MAKEFILE=libsbook.mak
#QLIB=$(QTDIR)\lib\qt-mt.lib
#
# Options:
# -f = large, fast scanner
# -i = case insensitive scanner
# -t = sent to stdout
# -+ = generate a C++ class
# -L = suppress line directives in scnner
# -B = generate batch scanner
# -7 = generate 7-bit scanner
# -s = suppress default rule to echo unmatched text


CXXFLAGS=	-nologo -W3 -DDEBUG /Yd /Gm /GX /Zi /ZI /GF /GZ /Ge /YX /MTd /DWIN32 \
		/I. /I$(QTDIR)/include

all: libsbook.lib tester.exe

tester.exe: tester.obj libsbook.lib $(QLIB)
	    link /out:tester.exe tester.obj libsbook.lib $(QLIB) /debug
#tester.exe: tester.obj parse_case.obj parse_address.obj 
#	    link /out:tester.exe tester.obj  parse_case.obj parse_address.obj /debug

libsbook.lib: $(OBJS)
    lib /out:libsbook.lib $(OBJS)

getopt.obj: getopt.c

clean:
    del parse_address.cpp
    del parse_company.cpp
    del parse_case.cpp
    del *.obj
    del *.lib

#
# These parsers are case-insensetive
#
parse_address.obj: parse_address.cpp
parse_company.obj: parse_company.cpp
parse_stocks.obj: parse_stocks.cpp

parse_address.cpp: parse_address.flex $(MAKEFILE) flexhdr.h
	$(FLEX) -Pyyaddress $(FLEXOPTS) $(FLEXCASE) parse_address.flex  | grep -v unistd.h > parse_address.cpp

parse_company.cpp: parse_company.flex $(MAKEFILE) flexhdr.h
	$(FLEX) -Pyycompany $(FLEXOPTS) $(FLEXCASE) parse_company.flex  | grep -v unistd.h  >  parse_company.cpp

parse_stocks.cpp: parse_stocks.flex $(MAKEFILE) flexhdr.h
	$(FLEX) -Pyystocks $(FLEXOPTS) $(FLEXCASE) parse_stocks.flex  | grep -v unistd.h  >   parse_stocks.cpp

#
# Case is the case-sensetive parser
#
parse_case.cpp: parse_case.flex $(MAKEFILE) flexhdr.h
	$(FLEX) $(FLEXOPTS) parse_case.flex  | $(SED) s/yy/yycase/g | grep -v unistd.h >  parse_case.cpp


.SUFFIXES: .cpp
.cpp.obj:
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -Fo$@ $<

