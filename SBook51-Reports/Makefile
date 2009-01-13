BUNDLE=ReportsBundle.bundle

all:
	xcodebuild -configuration Development
	ditto build/Development/$(BUNDLE) ../SBook51/build/Development/SBook5.app/Contents/PlugIns/$(BUNDLE)

pt:
	xcodebuild -target PageTester -buildstyle Development

clean:
	xcodebuild clean
	/bin/rm *~


