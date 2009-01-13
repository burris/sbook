#include "sbook.h"

/* SBookWidget is the SBook main user interface
 */

#ifndef SBOOK_WIDGET_H
#define SBOOK_WIDGET_H

#include <qwidget.h>
#include <qmenubar.h>
#include <qlabel.h>
#include <qsplitter.h>
#include <qlabel.h>
#include <qlistbox.h>
#include <qlineedit.h>
#include <qcombobox.h>
#include <qprogressbar.h>
#include <qwidgetstack.h>

#include "entry.h"
#include "entries.h"
#include "taggedlistboxitem.h"
#include "arrowlineedit.h"
#include "inspector.h"
#include "smenucell.h"
#include "sbookedit.h"


class SBookWidget : public QWidget
{
    Q_OBJECT
public:
    SBookWidget( QWidget *parent = 0, const char *name = 0 );

private:
    /* Here are the components of the main window */
    ArrowLineEdit   *searchField;		  // what we are searching for
    QListBox	    *listbox;			  // entry list box
    SBookEdit	    *editbox;			  // where we edit
    QComboBox	    *searchMode;
    QWidgetStack    *statusStack;
    QLabel	    *statusBar;
    QProgressBar    *progressBar;
    QPrinter	    *labelPrinter;

    /* Here are the state variables for selection */
    TaggedListBoxText *selectedTLB;		  // selected item in the listBox
    Entry	    *displayedEntry;		  // set when we display an entry.
    QString	    initialEditText;		  // first data that shows up



    /* The Inspector Inspector */
    class Inspector *inspector;		  
    
signals:
    void alert( const QString& );		  // puts message in status window
    void selectedEntryChanged();		  // entry has changed

    /* These slots are mostly for the menus */
public slots:
    void menuFileOpen();
    int  menuSave();			  // returns 0 if successful, -1 if fail
    int  menuSaveAs();			  // returns 0 if successful, -1 if fail
    void menuFileNew();
    void menuFileExit();
    void menuFilePrint();
    void menuFilePrintLabel();
    void menuFilePrintLabel2();
    void menuFileSetupLabelPrinter();

    void menuExport();
    void menuImport();

    void menuEntryNew();
    void menuEntryDelete();
    void menuFind();

    void menuAbout();
    void menuAboutQt();
    void menuShowInspector();


    void redisplay();			  // display the current search
    void setDirty(bool);
    void setTitle();
    void loadFile(const QString &);		  
    void doSearch();
    void doSearch(const QString &str);// typed in search field
    void doSearch(int);				  // for combo box
    void addEntryToListbox(Entry *entry,bool andDisplayEntry);	// adds to the list
    void displaySelectedEntry();		  // clicked in listbox
    void editboxChanged();			  // typed in edit field
    void showProgress();
    void showStatus(const QString &);
    int  editBoxLines();
    QString editBoxLine(int n);
    void printLabel(const QString &str);

public:
    Entries	data;
    Entry	*selectedEntry();		  // selected entry, NULL if selection
						  // is none or more than one
    void setEntryFont(QFont &font);
    void setListFont(QFont &font);
    virtual void	setGeometry(QRect frame);	  // set the frame
    void    setSelectionMode(QListBox::SelectionMode mode);

private:
    bool 	editable;		// can we edit what is in the box?
    bool	dirty;			// has this buffer been edited?
    bool	filereadOnly;		// was file opened read-only
    bool	changingEditBox;		  // true if we are changing it
    bool	event ( QEvent * e );
    void	closeEvent(QCloseEvent *e);
    void	clearAllSelections();
    bool	dirtyCheck();			  // can we blow it away?
    void	saveFrame();
    int		saveWithChoices(const char *title,QString &fn);
    int		saveTo(const QString &fn);	  // 0 if success, -1 if failure
    void	CreateMenuBar(QLayout *topLayout);
};

#endif
