all:
	(cd expat;make)
	(cd libsbook;make)
	(cd SBook51;make)
	(cd SBook51-Dialer;make)
	(cd SBook51-USDialRules;make)
	(cd SBook51-Reports;make)
	(cd SBook51-Sync;make)	
	(cd SBook51;make)

cleanall:
	(cd SBook51-Dialer;make clean)
	(cd SBook51-USDialRules;make clean)
	(cd SBook51-Reports;make clean)
	(cd SBook51-Sync;make clean) 	
	(cd SBook51;make clean)
