TEMPLATE	= app
CONFIG          += qt warn_on debug
CONFIG         += thread

HEADERS		= arrowlineedit.h fontbutton.h buffer.h inspector.h sbook.h defaults.h metaphone.h myqfiledialog.h sbookedit.h sbookwidget.h taggedlistboxitem.h xml.h myqsplitter.h dcheckbox.h datastorageobject.h Identifier.h IdentifierList.h Parser.h

SOURCES		= entries.cpp entry.cpp myqsplitter.cpp inspector.cpp arrowlineedit.cpp myqfiledialog.cpp sbookedit.cpp taggedlistboxitem.cpp fontbutton.cpp sbookwidget.cpp defaults.cpp main_menu.cpp dcheckbox.cpp xml.cpp Identifier.cpp IdentifierList.cpp Parser.cpp

RC_FILE		= sbook.rc

win32:CFLAGS	+= /Yd /Gm /GX /Zi /ZI /GF /GZ /Ge /YX /MTd /DDEBUG
win32:DEFINES	  = WIN32
win32:LIBS	+= ../libsbook/libsbook.lib

INCLUDEPATH	= libsbook
TARGET		= sbook

