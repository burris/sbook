BUNDLE=USDialRulesBundle.bundle

all:
	xcodebuild -buildstyle Development
	ditto build/Development/$(BUNDLE) ../SBook51/build/Development/SBook5.app/Contents/PlugIns/$(BUNDLE)

clean:
	xcodebuild clean -buildstyle Development

