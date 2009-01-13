/*
 * main.cpp
 *
 */

#include <qprinter.h>
#include <qapplication.h>
#include <qcolor.h>
#include <qpushbutton.h>
#include <qlayout.h>
#include <qlineedit.h>
#include <qmenubar.h>
#include <qpopupmenu.h>
#include <qtimer.h>
#include <qregexp.h>

#include "myqsplitter.h"
#include <qlistbox.h>
#include <stdio.h>
#include <qcombobox.h>
#include <qmessagebox.h>
#include <qfiledialog.h>
#include <qwidgetstack.h>

#include "libsbook/libsbook.h"
#include "entry.h"
#include "arrowlineedit.h"
#include "sbook.h"
#include "xml.h"
#include "myqfiledialog.h"
#include "inspector.h"
#include "sbookedit.h"
#include "defaults.h"
#include "parser.h"


SBookWidget::SBookWidget( QWidget *parent, const char *name )
    : QWidget( parent, name )
{
    /* Initialize state variables */
    editable=false;
    dirty=false;
    displayedEntry=0;
    selectedTLB = 0;
    changingEditBox = false;
    inspector=0;
    labelPrinter = new QPrinter;

    // Set the default size
    this->setGeometry(QRect(DEFAULT_X,DEFAULT_Y,DEFAULT_W,DEFAULT_H));

    // Make the top-level layout; a vertical box to contain all widgets
    // and sub-layouts.
    QBoxLayout *topLayout = new QVBoxLayout( this, 5 );

    // Create the menubar...
    CreateMenuBar(topLayout);
    // Make an hbox that will hold the search field and pull-down
    QBoxLayout *r1 = new QHBoxLayout( topLayout);
    searchField    = new ArrowLineEdit( this );
    connect(searchField,SIGNAL(textChanged(const QString &)),
	    this,SLOT(doSearch(const QString &)));
    
    searchMode = new QComboBox( this );
    searchMode->insertItem( SEARCH_AUTO );
    searchMode->insertItem( SEARCH_NAME );
    //    searchMode->insertItem( "Soundex" );
    searchMode->insertItem( SEARCH_FULLTEXT );
    connect(searchMode,SIGNAL(activated(int)),SLOT(doSearch(int)));

    r1->addWidget(searchField,10);
    r1->addWidget(searchMode,0);

    // Make the splitview
    MyQSplitter *s1 = new MyQSplitter( QSplitter::Vertical, this);
    s1->setOpaqueResize( TRUE );
    //s1->setFrameShape(QFrame::Box);
    //s1->setFrameStyle(QFrame::Plain);
    //s1->setLineWidth(0);
    s1->setFrameShadow(QFrame::Plain);

    /* Make the list box */
    listbox       = new QListBox( s1 );		  // was this
    listbox->setHScrollBarMode(QListBox::AlwaysOff);
    listbox->setVScrollBarMode(QListBox::AlwaysOn);
    searchField->listBox = listbox;	// get a pointer to it
    listbox->setFocusProxy(0);			  // do not set a focus proxy for listBox. 
    connect(listbox,SIGNAL(highlighted(int)),
	    this,SLOT(displaySelectedEntry(void)));

    /* Make the text edit field */
    //QScrollView *qsv = new QScrollView(s1);
    editbox = new SBookEdit( s1 );
    editbox->setWordWrap(QMultiLineEdit::WidgetWidth);
    editbox->setReadOnly(TRUE);			  // until you can type there.
    editbox->searchField = searchField;		  // make a copy 

    connect(editbox,SIGNAL(textChanged()), this,SLOT(editboxChanged()));

    topLayout->addWidget(s1);			  // put splitter in

    // Add the progress bar & status bar at the bottom.
    statusStack = new QWidgetStack(this);

    const int height=22;

    progressBar = new QProgressBar( statusStack );
    progressBar->setFixedHeight(height);

    statusBar = new QLabel( statusStack );
    statusBar->setText("Welcome to " APP_NAME);
    statusBar->setFrameStyle( QFrame::Panel | QFrame::Sunken );
    statusBar->setFixedHeight( height );
    statusBar->setAlignment( AlignVCenter | AlignLeft );

    //        statusStack->raiseWidget(statusBar);
        statusStack->raiseWidget(progressBar);

    connect( this,  SIGNAL(alert(const QString& )), this,SLOT(showStatus(const QString&)) );

    topLayout->addWidget( statusStack );
    topLayout->activate();

    redisplay();				  // set title, fonts, etc.
}

bool SBookWidget::event ( QEvent * e )
{
    if(e->type()==QEvent::WindowActivate){
	/* When the window is activated, simulate a ^f search after the next event is processed*/
	QTimer::singleShot(0,this,SLOT(menuFind()));
    }
    return QWidget::event(e);			  // pass it up
}

/* for closeEvent of the SBookWidget, pretend it was a fileExit */
void SBookWidget::closeEvent(QCloseEvent *e)
{
    menuFileExit();
}

/* clearAllSelections
 * Clear the selections, displayed text, and put cursor in search field
 */

void SBookWidget::clearAllSelections(void)
{
    setTitle();					  // set the title
    searchField->setText("");			  // search for nothing
    doSearch("");				  // do the search
    displaySelectedEntry();
    searchField->setFocus();			  // set focus to the search field
}

/* dirtyCheck():
 * Any operation that would change the file currently being edited
 * should call dirtyCheck() first. Returns TRUE if the operation
 * should be canceled, FALSE if the operation can proceed.
 */
 
bool SBookWidget::dirtyCheck(void)
{
    if(dirty){
	char buf[2048];

	sprintf(buf,"The file %s has been modified since it was last saved.\n"
		"Do you wish to save it now? ",data.filename);

	switch(QMessageBox::warning(this,
				    APP_NAME ": File not saved",
				    buf,
				    "&Yes","&No","&Cancel",0,2)){
	case 0:
	    menuSave();
	    return false;
	case 1:
	    return false;
	case 2:
	    return true;
	}
    }
    return false;
}

void SBookWidget::saveFrame()
{
    data.frame = this->geometry();
}

void SBookWidget::setGeometry(QRect frame)
{
    const int margin=40;

    int dw = qApp->desktop()->width();
    int dh = qApp->desktop()->height();

    /* See if we can fit the object on screen by moving it,
     * then shrinking it. Set a minimum size
     * Then put ourselves in this place on the screen
     */

    if(frame.width()>dw-margin) frame.setWidth(dw-margin);
    if(frame.width()<100) frame.setWidth(100);
    if(frame.x() + frame.width() > dw-margin){
	frame.moveTopLeft(QPoint(dw - frame.width()-margin,
				 frame.y()));
    }
    
    if(frame.height()>dh-margin*2) frame.setHeight(dh-margin*2);
    if(frame.height()<100) frame.setHeight(100);
    if(frame.y() + frame.height() > dh-margin){
	frame.moveTopLeft(QPoint(frame.x(),
				 margin));
    }
    QWidget::setGeometry(frame);
}

void SBookWidget::setDirty(bool val)
{
    dirty = val;
    setTitle();	
}

void SBookWidget::setTitle(void)
{
    QString caption;

    caption += APP_NAME;
    caption += ": ";

    if(strlen(data.filename)>0){
	caption.append(data.filename);
	caption.truncate(caption.length()-strlen(DOC_TYPE)); // remove ext
    }
    else{
	caption.append("Untitled");
    }

    if(dirty){
	caption.append(" *");
    }
    this->setCaption(caption);
}

/* 
 * loadFile:
 * Load the named file. If file end with DOC_TYPE, assume it is SBook XML
 * Otherwise, try to open it as sbook ascii.
 */
void SBookWidget::loadFile(const QString &fn)
{
    data.Empty();				  // Empty the list

    if(fn.right(strlen(DOC_TYPE)).lower().compare(DOC_TYPE)==0){
	showProgress();
	if(data.loadFile(fn.latin1(),this,progressBar)){
	    emit alert("could not read SBook XML file " + fn);
	    return;
	}
	emit alert("Loaded SBook XML file "+fn);
	goto done;
    }
	
    if(data.ImportSBookASCII(fn)==false){
	return;
    }

 done:;

    /* We arrived here if load is successful */
    redisplay();
}

void SBookWidget::redisplay()
{
#ifdef DEBUG_SEARCH
    puts("redisplay");
#endif    
    //setEntryFont(data.entryFont);
    //setListFont(data.listFont);
    clearAllSelections();
}

void SBookWidget::doSearch(void)
{
    doSearch(searchField->text());
}

void SBookWidget::doSearch(int i)		  // ignores i
{
    doSearch(searchField->text());
}

void SBookWidget::addEntryToListbox(Entry *entry,bool displayEntry)
{
    TaggedListBoxText *item = new TaggedListBoxText(entry->line1Display());
    item->entry = entry;
    listbox->insertItem(item);
    if(displayEntry){
	listbox->setCurrentItem(item);
	displayedEntry = entry;
    }
}

/* doSearch:
 * Update the listbox with the search. If str=="", display all.
 * If an Entry is provided, the Entry is automatically included in the 
 * search results and selected when it is found. (This is used to handle ^n New Entry.)
 * If search results in a single entry being displayed, automatically select it.
 */
void SBookWidget::doSearch(const QString &str)
{
    int count=0;

    /* Reload file if necessary */
    data.checkForReload();

    Entry   *lastSelectedEntry = selectedEntry();

    /* First clear the current selection */
    listbox->clear();
    selectedTLB=0;
    bool fulltext = (searchMode->currentText() == SEARCH_FULLTEXT);

    /* Now go through each of the entries in the data list to see if they match */
 again:;
    for(Entry *ent = data.list.first();
	ent != 0;
	ent = data.list.next()){
	    
#ifdef DEBUG_SEARCH
	printf("checking %d: %s...",count++,ent->line1()->latin1());
#endif	
	if(   (str.length()==0)
	      || ent->match(str,fulltext)){

	    /* We have a match. Create a new TaggedListBoxText and populate it */
	    addEntryToListbox(ent,0);
	}
#ifdef DEBUG_SEARCH
	printf("done\n");
#endif
    }
    /* If we found nothing and we are in auto mode, and this wasn't the fulltext
     * search, go back and do a full-text search.
     */
    if(listbox->count()==0 &&
       searchMode->currentText() == SEARCH_AUTO &&
       fulltext==false){
	fulltext=true;
	goto again;
    }

    /* If we only found one thing, then select it */
    if(listbox->count()==1){
	listbox->setCurrentItem(0);
    }

    /* If the selected entry has changed, issue the signal */
    if(selectedEntry() != lastSelectedEntry){
	emit selectedEntryChanged();
    }

    QString info;
    info.sprintf("%d of %d entries displayed",listbox->count(),data.list.count());
    emit alert(info);
}

/*
 * displaySelectedEntry:
 * called when a new entry in the list is clicked on or otherwise selected.
 */

void SBookWidget::displaySelectedEntry(void)
{
    int  numSelected=0;				  // number selected
    int  count = listbox->count();		  // number of items
    int  i;
    QString str;

    selectedTLB = 0;				  // clear selection
    for(i=0;i<count;i++){
	if(listbox->isSelected(i)){
	    numSelected++;

	    TaggedListBoxText *t = (TaggedListBoxText *)listbox->item(i);
	    displayedEntry = t->entry;

	    if(numSelected==1){
		selectedTLB = t;
	    }
	    else{
		selectedTLB = 0;			  // clear selection
		str+= "================================\n";
	    }
	    str += displayedEntry->text();
	}
    }
    initialEditText = str;		// remember initial text

    changingEditBox = true;
    editbox->setText(str);
    changingEditBox = false;

    editbox->setCursorPosition(0,0);	// move to the stop
    if(numSelected==1){
	emit alert("");
	editbox->setReadOnly(FALSE);
    }
    else{
	displayedEntry = 0;			  // I can't keep track of what is displayed
	QString buf;
	editbox->setReadOnly(TRUE);
	selectedTLB=0;
	buf.sprintf("%d entries selected",numSelected);
	emit alert(buf);
    }

    searchField->setFocus();		// return focus to the search field
    emit selectedEntryChanged();
}

/* editboxChanged:
 * This is called whenever the text is changed.
 *
 * Unfortunately, in Qt, that's whether it is changed by the user or the programmer.
 * So we need to check to see if the text has actually being changed programmatically,
 * which what the "changingEditBox" flag is about.
 */
void SBookWidget::editboxChanged()
{
    /* Check to see if this was called becuase of Qt */
    if(changingEditBox){
	return;
    }
    QString		newText = editbox->text(); // get the text
    if(newText.ascii()==0){
	/* Turns out that we didn't need to be called - Qt bug */
	return;
    }

    /* Update the entry itself*/
    if(displayedEntry){
	if(dirty==FALSE){
	    if(initialEditText.compare(newText)==0){
		return;			// no change was made
	    }
	    setDirty(TRUE);
	}
	displayedEntry->setText(newText);
    }

    /* If an entry in the List is selected, then modify the selection */
    if(selectedTLB){
	Entry *ent = selectedTLB->entry;

	if(selectedTLB->text().compare(*ent->line1())!=0){	// change made to first line?
	    selectedTLB->setText(ent->line1Display()); // update label in entry scroller
	    listbox->triggerUpdate(FALSE);	  // redraw the scroller
	}
    }

}

/*
 * saveTo:
 * Saves the data file to a particular file.
 */

int SBookWidget::saveTo(const QString &fn)	  
{
    XML xml;

    saveFrame();				  // record frame
    showProgress();
    if(!xml.writeFile(fn.latin1(),&data,progressBar)){
	emit alert("Error writing " + fn + ": " + strerror(errno));
	return -1;
    }
    emit alert("Wrote " + fn);
    Defaults::globalDefaultObject()->set(DEFAULT_LAST_SAVED_FILE,fn);
    setTitle();				  // show new title
    return 0;
}

Entry *SBookWidget::selectedEntry()
{
    return selectedTLB ? selectedTLB->entry : 0;
}

void SBookWidget::setEntryFont(QFont &font)
{
    return;
	const char *family = font.family().latin1();
	const char *key    = font.key().latin1();

	if(family && key){
		printf("setEntryFont %s %s\n",family,key);
	    data.entryFont = font;
	}
	else{
		printf("family & key are invalid");
	}
    //editbox->setFont( font );
}

void SBookWidget::setListFont(QFont &font)
{
    // data.listFont  = font;
    //listbox->setFont( font );
}

void SBookWidget::showProgress()
{
    statusStack->raiseWidget(progressBar);
}

void SBookWidget::showStatus(const QString &str)
{
    statusStack->raiseWidget(statusBar);
    statusBar->setText(str);
}

void SBookWidget::setSelectionMode(QListBox::SelectionMode mode)
{
    listbox->setSelectionMode(mode);
    if(mode==QListBox::Single){
	listbox->setCurrentItem(listbox->currentItem());
    }
}
	
int SBookWidget::editBoxLines()
{
    QString theText = editbox->text();
    int i;
    int len = theText.length();
    int l=1;

    for(i=0;i<len;i++){
	if(theText.at(i)=='\n'){
	    l++;
	}
    }
    return l;
}



QString SBookWidget::editBoxLine(int line)
{
    QString theText = editbox->text();
    int len = theText.length();
    int p1=0;

    while(line>0 && p1<len){
	if(theText.at(p1)=='\n'){
	    line--;
	}
	p1++;
    }
    if(p1>=len) return "";

    int p2;

    for(p2=p1+1;p2<len;p2++){
	if(theText.at(p2)=='\n'){
	    break;
	}
    }

    QString ret = theText.mid(p1,p2-p1);

    QRegExp r("[\r\n]");

    ret.replace(r,"");		  // change \r or \n to ""
    return ret;
}

int main( int argc, char **argv )
{
    //    freopen("sbook.log","w",stdout);
    //freopen("sbook.err","w",stderr);

    theParser = new Parser();
    setGlobalDefaults("Simson","SBook"); // establish app vendor & name

    QApplication a( argc, argv );

    SBookWidget *f = new SBookWidget;
    a.setMainWidget(f);
    f->show();

    if(argc>1 && argv[1]){
	f->loadFile(argv[1]);
    }
    else{
	if(Defaults::globalDefaultObject()->getBool(DEFAULT_AUTOLOAD_LAST_SAVED_FILE)){
	    QString file = Defaults::globalDefaultObject()->get(DEFAULT_LAST_SAVED_FILE);

	    if(file.length()){
		f->loadFile(file);
	    }
	}
    }
    return a.exec();
}


