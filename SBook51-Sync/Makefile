BUNDLE=SyncBundle.bundle


all:
	xcodebuild -configuration Development
	ditto build/Development/$(BUNDLE) ../SBook51/build/Development/SBook5.app/Contents/PlugIns/$(BUNDLE)

CFLAGS = -g -I../SBook51 -I../libsbook
LIBSBOOK=../libsbook/libsbook.a

clean:
	/bin/rm -f *~
	xcodebuild clean

ABTESTOBJS=AddressBookSyncer.o ABPersonAdditions.o abtest.o Syncher.o
abtest: $(ABTESTOBJS)
	c++ -g -o abtest $^ -framework AddressBook -framework AppKit -framework Foundation ../libsbook/libsbook.a -lz

.SUFFIXES: .mm .m
.mm.o:
	c++ -c $^  $(CFLAGS)

.m.o:
	c++ -c $^  $(CFLAGS)



