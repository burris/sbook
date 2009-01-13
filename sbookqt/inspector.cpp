#include <qlabel.h>
#include <qpushbutton.h>
#include <qtabwidget.h>
#include <qlayout.h>
#include <qvbox.h>
#include <qgrid.h>
#include <stdio.h>
#include <qfontdialog.h>
#include <qgroupbox.h>
#include <time.h>
#include "dcheckbox.h"

#include "inspector.h"

struct {
    char *label;
    int	sortType;
} SortKeyArray[] = {
    {"Smart Sort",SORTKEY_SMART},
    {"First word", 0},
    {"Second word", 1},
    {"Third word", 2},
    {"2nd Last", -2},
    {"Last", -1},
    {0,0}
};
    
    

QWidget *Inspector::StartInspectorTab(const QString &label)
{
    QWidget *tab;

    row = 0;
    tabView->insertTab(tab=new QWidget(this,0),label);
    currentParentWidget = tab;
    currentGridLayout = new QGridLayout(tab,4,1,10,10);
    currentGridLayout->setColStretch(3,1);
    currentGridLayout->setRowStretch(row,0);
    row++;
    return tab;
}


QWidget *Inspector::addLabeledWidget(const QString &label,
			  QWidget *widget)
{
    currentGridLayout->addWidget(new QLabel(label,currentParentWidget), row, 1);
    currentGridLayout->addWidget(widget,row,2);
    row++;
    return widget;
}

QLabel *Inspector::addLabeledLabel(const QString &label)
{
    return (QLabel *)addLabeledWidget(label,new QLabel("",currentParentWidget));
}

QWidget *Inspector::addWideWidget(QWidget *widget)
{
    currentGridLayout->addMultiCellWidget(widget,row,row,1,2,AlignLeft);
    row++;
    return widget;
}

void Inspector::EndInspectorTab()
{
    currentGridLayout->setRowStretch(row++,10);
    currentGridLayout->activate();
}

Inspector::Inspector(QWidget *parent,const char *name,
		     bool modal, WFlags f )
{
    int i;
    QGridLayout *g;

    main = 0;
    this->setCaption("SBook Inspector");
    this->setGeometry(100,100,200,300);

    QBoxLayout *topLayout = new QVBoxLayout( this,5);

    // Create the tab view
    tabView = new QTabWidget(this,0);
    topLayout->addWidget(tabView);

    /* Program Tab */
    programTab = StartInspectorTab("&Program");
    addWideWidget(multipleSelectionBox = new DCheckBox("Allow &Multiple Selections",
						       programTab,
						       DEFAULT_ALLOW_MULTIPLE_SELECTIONS));
    addWideWidget(multipleSelectionBox = new DCheckBox("Auto&save",programTab,
						       DEFAULT_AUTOSAVE));
    addWideWidget(multipleSelectionBox = new DCheckBox("Auto&load last saved file",
						       programTab,
						       DEFAULT_AUTOLOAD_LAST_SAVED_FILE));

    connect(multipleSelectionBox,SIGNAL(stateChanged(int)),
	    this,SLOT(setAllowMultipleSelections(int)));


    EndInspectorTab();

    /* File Tab */

    fileTab = StartInspectorTab("&File");
    filenameLabel = addLabeledLabel("File:");
    entryCountLabel  = addLabeledLabel("Entries:");
    fileCreationDateLabel = addLabeledLabel("Created:");
    addLabeledWidget("Default Sort Key:",defaultSortKeyBox=new QComboBox(fileTab));
    for(i=0;SortKeyArray[i].label;i++){
	defaultSortKeyBox->insertItem(SortKeyArray[i].label);
    }
    connect(defaultSortKeyBox,SIGNAL(activated(int)),
	    this,SLOT(setDefaultSortKey(int)));

    addWideWidget(sortBox = new QCheckBox("&Sort Entries",fileTab));
    connect(sortBox,SIGNAL(stateChanged(int)), this,SLOT(setSortEntries(int)));

    addLabeledWidget("List Font:",listFontButton = new FontButton(fileTab));
    addLabeledWidget("Entry Font", entryFontButton = new FontButton(fileTab));
    EndInspectorTab();
	

    /* Entry Tab */
    entryTab = StartInspectorTab("&Entry");
    entryName = addLabeledLabel("Name:");
    entryCtime = addLabeledLabel("Created:");
    entryMtime = addLabeledLabel("Last Modified:");
    entryAtime = addLabeledLabel("Last Accessed:");
    addLabeledWidget("Entry Sort Key:",entrySortKeyBox=new QComboBox(entryTab));
    for(i=0;SortKeyArray[i].label;i++){
	entrySortKeyBox->insertItem(SortKeyArray[i].label);
    }
    connect(entrySortKeyBox,SIGNAL(activated(int)),
	    this,SLOT(setEntrySortKey(int)));
    entrySortName = addLabeledLabel("");

    EndInspectorTab();
    
    /* Template Tab */
    QWidget *w;
    tabView->insertTab(w=new QWidget(this,0),"&Template");
    g = new QGridLayout(w,1,1,10,3);
    g->addWidget(new QLabel("Template for new entries:",w), 0,0);
    g->addWidget(templateText = new QMultiLineEdit(w),1,0);
    g->activate();

    // Create the buttons
    QHBoxLayout *h1	= new QHBoxLayout(topLayout);

    h1->addStretch(5);

    /* Do the apply button; this needs to go away */
    QPushButton *apply	= new QPushButton(this,0);
    apply->setText("&Apply");
    h1->addWidget(apply);
    connect(apply,SIGNAL(clicked()), this,SLOT(apply()));

    /* Do the Revert Button */
    QPushButton *revert	= new QPushButton(this,0);
    revert->setText("&Revert");
    h1->addWidget(revert);
    connect(revert,SIGNAL(clicked()), this,SLOT(revert()));

    /* Do the Close Button */
    QPushButton *close	= new QPushButton(this,0);
    close->setText("&Close");
    h1->addWidget(close);
    connect(close,SIGNAL(clicked()), this,SLOT(close()));

    h1->addStretch(5);


    topLayout->activate();
}

QString ascDate(time_t t)
{
    char *cc;

    cc = asctime(localtime(&t));
    cc[24] = '\000';
    return cc;
}

/****************************************************************
 *** Buttons that we would push ***
 ****************************************************************/

/* apply: save the data;
 * This needs to go away with the new property value system.
 */
void Inspector::apply(void)
{
    main->setEntryFont(entryFontButton->getTheFont());
    main->setListFont(listFontButton->getTheFont());
    main->data.template_ = templateText->text();
}

/* Revert: reshow what we were asked to show.
 * This needs to be rethought.
 */
void Inspector::revert(void)
{
    this->show();
}

/* Show: show all of the current contents */
void Inspector::show(void)
{
    /* Set the current values */
    showFile();
    showEntry();				  // sets the entry
    showTemplate();

    QDialog::show();				  // show super
}

void Inspector::showFile()
{
    entryFontButton->setTheFont(main->data.entryFont);
    listFontButton->setTheFont(main->data.listFont);
    filenameLabel->setText(main->data.filename);
    fileCreationDateLabel->setText(ascDate(main->data.fileCreationDate));
    entryCountLabel->setNum((int)main->data.list.count());
    sortBox->setChecked(main->data.sortFlag);
}

void Inspector::showEntry()
{
    /* Set entry values if there is a selected entry */
    if(main->selectedEntry()){
	Entry *ent = main->selectedEntry();

	tabView->setTabEnabled(entryTab,TRUE);
	tabView->showPage(entryTab);
	entryName->setText(*ent->line1());
	entryCtime->setText(ascDate(ent->ctime));
	entryMtime->setText(ascDate(ent->mtime));
	entryAtime->setText(ascDate(ent->atime));
	entrySortName->setText(ent->sortName());
    }
    else{
	tabView->setTabEnabled(entryTab,FALSE);
	tabView->showPage(fileTab);
	entryName->setText("--");
	entryCtime->setText("--");
	entryMtime->setText("--");
	entryAtime->setText("--");
	entrySortName->setText("--");
    }
}

void Inspector::showTemplate()
{
    /* set the template */
    templateText->setText(main->data.template_);
}



void Inspector::setDefaultSortKey(int key)
{
    main->data.setDefaultSortKey(SortKeyArray[key].sortType);
}

void Inspector::setEntrySortKey(int key)
{
    if(main->selectedEntry()){
	main->selectedEntry()->setSortKey(SortKeyArray[key].sortType);
	showEntry();
    }
}

void Inspector::setSortEntries(int flag)
{
    main->data.setSortFlag(flag);
}


void Inspector::setSBookWidget(SBookWidget *widget)
{
    main=widget;
    connect(main,SIGNAL(selectedEntryChanged()), this,SLOT(showEntry()));
}

void Inspector::setAllowMultipleSelections(int flag)
{
    if(flag){
	main->setSelectionMode(QListBox::Extended);
    }
    else{
	main->setSelectionMode(QListBox::Single);
    }
}
