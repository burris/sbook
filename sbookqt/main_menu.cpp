/*
 * main_menu.cpp
 * Functions called by the menu
 * Functions for setting up the menu
 */

#include <qapplication.h>
#include <qcolor.h>
#include <qpushbutton.h>
#include <qlayout.h>
#include <qlineedit.h>
#include <qmenubar.h>
#include <qpopupmenu.h>
#include <qsplitter.h>
#include <qlistbox.h>
#include <stdio.h>
#include <qcombobox.h>
#include <qmessagebox.h>
#include <qfiledialog.h>
#include <qprinter.h>
#include <qpainter.h>

#ifdef WIN32
#include  <io.h>
#endif

#include  <stdio.h>
#include  <stdlib.h>

#ifdef UNIX
#include <unistd.h>
#include <errno.h>
#endif


#include "entry.h"
#include "arrowlineedit.h"
#include "sbook.h"
#include "sbookwidget.h"
#include "xml.h"
#include "myqfiledialog.h"
#include "smenucell.h"

#define SBOOK_XML_FILTER  "SBook XML (*" DOC_TYPE ")"

void SBookWidget::CreateMenuBar(QLayout *topLayout)
{
    QMenuBar *menubar = new QMenuBar( this );
    menubar->setSeparator( QMenuBar::InWindowsStyle );


    QPopupMenu *file = new QPopupMenu;
    file->insertItem( "&New File", this, SLOT(menuFileNew()) );
    file->insertItem( "&Open", this, SLOT(menuFileOpen()),CTRL+Key_O );
    file->insertSeparator();
    file->insertItem( "&Save",    this, SLOT(menuSave()),CTRL+Key_S );
    file->insertItem( "Save &As ...", this, SLOT(menuSaveAs()));
    file->insertItem( "E&xport ...", this, SLOT(menuExport()));
    file->insertItem( "I&mport ...",   this, SLOT(menuImport()));
    file->insertSeparator();
    file->insertItem( "&Print ...",   this, SLOT(menuFilePrint()), CTRL+Key_P);
    file->insertItem( "&Setup Label Printer ...", this, SLOT(menuFileSetupLabelPrinter()));
    file->insertSeparator();
    file->insertItem( "&Inspector", this, SLOT(menuShowInspector()),CTRL+SHIFT+Key_I);
    file->insertItem( "&Exit", this, SLOT(menuFileExit()) );
    menubar->insertItem( "&File", file );

    /*************/
    /*   ENTRY   */
    /*************/
    QPopupMenu *entry = new QPopupMenu;
    entry->insertItem( "&New Entry",	this, SLOT(menuEntryNew()),CTRL+Key_N );
    entry->insertItem( "&Delete Entry", this, SLOT(menuEntryDelete()),CTRL+Key_D );
    entry->insertItem( "&Find Entry",	this, SLOT(menuFind()), CTRL+Key_F );
    entry->insertSeparator();
    entry->insertItem( "&Send Email",	this, SLOT(sendEmail()), CTRL+Key_E );
    entry->insertItem( "Print &Label ...", this, SLOT(menuFilePrintLabel()), CTRL+Key_L);
    entry->insertItem( "Print Label 2 ...", this, SLOT(menuFilePrintLabel2()), CTRL+SHIFT+Key_L);

    menubar->insertItem( "&Entry", entry);
    /****************************************************************/

    QPopupMenu *help = new QPopupMenu;
    help->insertItem( "&About " APP_NAME " " APP_VERSION,
		      this, SLOT(menuAbout()) );
    help->insertSeparator();
    help->insertItem( "About &Qt"       , this, SLOT(menuAboutQt()) );
    menubar->insertItem( "&Help",help);

    // ...and tell the layout about it.
    topLayout->setMenuBar( menubar );
}

void drawFonts( QPainter *p )
{
    static const char *fonts[] = { "Helvetica", "Courier", "Times", 0 };
    static int	 sizes[] = { 10, 12, 18, 24, 36, 0 };
    int f = 0;
    int y = 0;
    while ( fonts[f] ) {
        int s = 0;
        while ( sizes[s] ) {
            QFont font( fonts[f], sizes[s] );
            p->setFont( font );
            QFontMetrics fm = p->fontMetrics();
            y += fm.ascent();
            p->drawText( 10, y, "Quartz Glyph Job Vex'd Cwm Finks" );
            y += fm.descent();
            s++;
        }
        f++;
    }
}
/* Print the current entry */
void SBookWidget::menuFilePrint()
{
    Entry *entry = selectedEntry();

    if(entry){
	QPrinter printer;

	if(printer.setup()){
	    int lines = entry->lines();
	    
	    QPainter p(&printer);
	    
	    QFont font("Helvitica",12);
	    p.setFont(font);
	    
	    QFontMetrics fm = p.fontMetrics();
	    int y = 0;
	    int i = 0;
	    
	    for(i=0;i<lines;i++){
		y += fm.ascent();
		p.drawText(10,y,entry->getLine(i));
		y += fm.descent();
	    }
	}
    }
}

/* Create a new file */
void SBookWidget::menuFileNew(void)
{
    if(dirtyCheck()){
	return;
    }
    data.filename = NXUniqueString("");		  // erase the file
    data.Empty();				  // erase the data
    setDirty(false);				  // no longer dirty
    clearAllSelections();
    emit alert("New File");
}

char *aboutMsg = 
"<html><head></head><body><h1>" APP_NAME " " APP_VERSION "</h1>"
"Simson Garfinkel's <b>new</b> address book.<br>"
"(C) Copyright 2000, Simson L. Garfinkel. All rights reserved.<p>"
"This program is an experimental version of " APP_NAME " for Windows, "
"a program that is similar to the original SBook for NeXTSTEP but which "
"shares no common code with Simson Garfinkel's original SBook program.<p>"
"For more information, check out http://simson.net/sbook/"
"</body></html>";

void SBookWidget::menuAbout(void)
{
    QMessageBox::about( this, APP_NAME,aboutMsg);

}
void SBookWidget::menuAboutQt(void)
{
    QMessageBox::aboutQt( this, APP_NAME " " APP_VERSION ": About Qt");
}

static int newCount=0;
void SBookWidget::menuEntryNew(void)
{
    QString text;
    int	ct = ++newCount;

    text.sprintf(data.template_,ct,ct,ct,ct,ct,ct,ct,ct,ct,ct,ct);

    Entry *ent = new Entry(text);
    ent->SN	= data.getNextSN();
    data.add(ent);
    this->addEntryToListbox(ent,true);	 
    editbox->selectFirstLine();
    editbox->setFocus();
    setDirty(true);
}

/* Delete the entry that is currently selected.
 * This may or may not be an entry that is displayed.
 */

void SBookWidget::menuEntryDelete(void)
{
    if(listbox->currentItem() == -1){
	return;					  // no selected entry
    }

    Entry *entryToDelete = selectedEntry();

    if(entryToDelete==0){	  // something weird happened, not sure what.
	return;
    }

    /* Remove the item that is selected from the listbox.
     */
    listbox->removeItem(listbox->currentItem());
    setDirty(true);

    /* Remove the item from the list */
    data.remove(entryToDelete);

    /* Finally, delete the entry itself */

    //delete entryToDelete;			it autodeletes
    emit alert("Entry Deleted");


    /* Remove the entry to delete from the list.
     */

#if 0
    if(displayedEntry==entryToDelete){
	displayedEntry=0;
    }
#endif
}


/* menuFind():
 * Since SBook does an incremental find, this function merely highlights
 * the characters in the search field.
 */
void SBookWidget::menuFind()
{
    searchField->setFocus();
    searchField->selectAll();
}


void SBookWidget::menuFileOpen(void)
{
    if(dirtyCheck()){
	return;
    }

    QString fn = QFileDialog::getOpenFileName(QString::null,SBOOK_XML_FILTER,NULL);
    if(!fn.isNull()){
	loadFile(fn);
    }
}

int SBookWidget::menuSave(void)
{
    QString fn;

    if(strlen(data.filename)==0){		  // if no filename?
	if(saveWithChoices("Save As",fn)==0){		  // do a saveAs
	    setDirty(false);
	    return 0;
	}
	return -1;
    }
    if(dirty==false){				  // no sense to do the save
	return 0;				  // since we are not dirty
    }
    if(saveTo(data.filename)==0){		  // save to filename
	setDirty(false);			  // no longer dirty
	return 0;
    }
    return -1;
}

int SBookWidget::menuSaveAs(void)
{
    QString fn;

    if(saveWithChoices("Save As",fn)==0){		  // do a saveAs
	data.filename = NXUniqueString(fn.latin1());	// remember new file name
	setDirty(false);
	return 0;
    }
    return -1;
}

const char *ifilters[] = {"SBook XML (*" DOC_TYPE ")",
			  "SBook ASCII (*.txt)",
			  "CSV Optimized for Palm (*.csv)",
			  "Comma Seperated Values (*.csv *.txt)",
			  "Tab Delimited (*.tab *.txt)",
			  "InfoGenie / QuickDex (*.dat *.txt)",
			 0};

const char *ofilters[] = {"SBook XML (*" DOC_TYPE ")",
			  "SBook ASCII (*.txt)",
			  "CSV Optimized for Palm (*.csv)",
			  "Comma Seperated Values (*.csv)",
			  "Tab Delimited (*.txt)",
			  "InfoGenie / QuickDex (*.dat)",
			 0};
#define FILTER_XML 0
#define FILTER_SBOOK_ASCII 1
#define FILTER_PALM_CSV 2
#define FILTER_CSV 3
#define FILTER_TAB 4
#define FILTER_IG 5

/*
 * Save with choices.
 * title = "Save As" or "Export To"
 */

int SBookWidget::saveWithChoices(const char *title,QString &fn)
{
    QFileDialog fd(QString::null,0,this,title,true);

    fd.setMode(QFileDialog::AnyFile);
    fd.setCaption(title);
    fd.setSelection(QDir::currentDirPath());
    fd.setFilters((const char **)ofilters);

    if(fd.exec()==QDialog::Accepted){
	QString filter    = fd.selectedFilter();
	QString extension = filter.right(5);	  // get last 5 characters
	extension.truncate(4);			  // remove last ")"
	fn = fd.selectedFile();

	if(fn.right(4).lower().compare(extension)!=0){
	    fn += extension;			  // add the ending if not ther
	}

	if(access(fn.latin1(),0)==0){
	    if(QMessageBox::warning(0,"File Exists","The file "
				    + fn + " exists. Do you wish to overwrite it?",
				    "OK","Cancel",QString::null,1,1)==1){
		return -1;			  // aborted
	    }
	}

	if(filter.compare(ofilters[FILTER_XML])==0){
	    saveTo(fn);
	}
	if(filter.compare(ofilters[FILTER_SBOOK_ASCII])==0){
	    data.Export(fn.latin1(),FORMAT_SBOOK_ASCII);
	}
	if(filter.compare(ofilters[FILTER_PALM_CSV])==0){
	    data.Export(fn.latin1(),FORMAT_PALM_CSV);
	}
	if(filter.compare(ofilters[FILTER_CSV])==0){
	    data.Export(fn.latin1(),FORMAT_CSV);
	}
	if(filter.compare(ofilters[FILTER_TAB])==0){
	    data.Export(fn.latin1(),FORMAT_TAB);
	}
	if(filter.compare(ofilters[FILTER_IG])==0){
	    data.Export(fn.latin1(),FORMAT_IG);
	}
	return 0;				  // good save
    }
    return -1;					  // didn't save
}
			  

void SBookWidget::menuExport(void)
{
    QString fn;

    saveWithChoices("Export",fn);
}

void SBookWidget::menuImport(void)
{
    QFileDialog fd(QString::null,0,this,"Import",true);

    fd.setMode(QFileDialog::ExistingFile);
    fd.setCaption("Import");
    fd.setSelection(QDir::currentDirPath());
    fd.setFilters((const char **)ifilters);

    if(fd.exec()==QDialog::Accepted){
	QString filter    = fd.selectedFilter();
	QString fn = fd.selectedFile();

	if(access(fn.latin1(),04)){
	    if(QMessageBox::warning(0,"Cannot Read",
				    "The file "
				    + fn
				    + " cannot be opened for reading:"
				    + sys_errlist[errno],
				    "OK",QString::null,QString::null)==1){
	    }
	    return;				  // aborted
	}

	int count=0;

	if(filter.compare(ifilters[FILTER_XML])==0){
	    XML xml;

	    statusStack->raiseWidget(progressBar);
	    count = xml.readFile(fn,&data,0,progressBar);
	    statusStack->raiseWidget(statusBar);
	    if(count == -1){
		QMessageBox::warning(0,"Cannot Read",
				     "The file " + fn + " appears to be corrupt. Sorry!",
				     "OK");
		return;
	    }
	}
	

	if(filter.compare(ifilters[FILTER_SBOOK_ASCII])==0){
	    count = data.ImportSBookASCII(fn);
	}
	if(filter.compare(ifilters[FILTER_TAB])==0){
	    count = data.ImportDelimited(fn,TAB_DELIM);
	}
	if(filter.compare(ifilters[FILTER_CSV])==0){
	    count = data.ImportDelimited(fn,CSV_DELIM);
	}
	if(filter.compare(ifilters[FILTER_IG])==0){
	    count = data.ImportIG(fn);
	}
	redisplay();
	char buf[1024];
	sprintf(buf,"Imported %d %s",count,count==1 ? "entry" : "entries");
	emit alert(buf);
    }
}
			  

void SBookWidget::menuShowInspector()
{
    const int inspectorStyle = WStyle_Customize|WStyle_DialogBorder|WStyle_Title;
    if(!inspector){
	// Create the property manager
	inspector = new Inspector(0,"SBook Inspector",
				  TRUE,
				  inspectorStyle);
	inspector->setSBookWidget(this);
    }
    inspector->show();
    inspector->raise();
}

void SBookWidget::menuFileExit(void)
{
    if(dirtyCheck()){
	return;
    }

    qApp->quit();				  // quit the app
}


void SBookWidget::menuFileSetupLabelPrinter()
{
    labelPrinter->setup();
}

void SBookWidget::printLabel(const QString &str)
{

    labelPrinter->setPrinterName("Dymo LabelWriter Turbo");

    QStringList list = QStringList::split(QChar('\n'), str);

    QPainter p(labelPrinter);
	    
    QFont font("Helvitica",12);
    p.rotate(-90);
    p.setFont(font);
	    
    QFontMetrics fm = p.fontMetrics();

    p.drawText(-330,20,"Simson Garfinkel & Beth Rosenberg");
    p.drawText(-330,40,"305 Walden St., #2");
    p.drawText(-330,60,"Cambridge, MA 02138");


    int x = -250;
    int y = 100;
    unsigned int i = 0;
	    
    for(i=0;i<list.count();i++){
	QString line = (*list.at(i));

	y += fm.ascent();
	p.drawText(x,y,line);
	y += fm.descent();
    }
}

void SBookWidget::menuFilePrintLabel()
{
    Entry *ent = selectedEntry();
    if(ent){
	QString addr = ent->addressN(0);


	if(addr.length()){
	    printLabel(addr);
	}
    }
}


void SBookWidget::menuFilePrintLabel2()
{
    Entry *ent = selectedEntry();

    if(ent){
	QString addr = ent->addressN(1);

	if(addr.length()){
	    printLabel(addr);
	}
    }
}


