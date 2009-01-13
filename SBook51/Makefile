all:
	xcodebuild -configuration Development
	(cd ../SBook51-Dialer;make)
	(cd ../SBook51-Reports;make)
	(cd ../SBook51-Sync;make)
	(cd ../SBook51-USDialRules;make)


clean:
	xcodebuild clean -buildstyle Development

src:
	(cd ..;/bin/rm -rf */*~ */*/*~.nib)
	(cd ..;gtar -c --exclude \*.svn -z -v -f SBook51/plugin-src.tar.gz SBook51-*/*.{[hmc]*,plist,xcode,txt,lproj} SBook51-*/Makefile)

dist:
	perl make_dist.pl
