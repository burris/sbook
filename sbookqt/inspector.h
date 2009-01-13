#include "sbook.h"

#ifndef PROPERTYMANAGER_H
#define PROPERTYMANAGER_H

#include <qsemimodal.h>
#include <qdialog.h>
#include <qlabel.h>
#include <qmultilineedit.h>
#include <qpushbutton.h>
#include <qtabwidget.h>
#include <qgrid.h>
#include <qlayout.h>
#include <qcheckbox.h>
#include <qdict.h>

#include "sbookwidget.h"
#include "fontbutton.h"

class Inspector: public QDialog
{
    Q_OBJECT
public:
    void    setSBookWidget(class SBookWidget *widget);

private:
    class SBookWidget *main;
    QTabWidget *tabView;

    /* For building the window */
    int	row;					  // current row in GridLayout
    QGridLayout *currentGridLayout;
    QWidget	*currentParentWidget;
    QWidget	*addLabeledWidget(const QString &label, QWidget *widget);
    QWidget	*addWideWidget(QWidget *widget);
    QLabel	*addLabeledLabel(const QString &label);
    QWidget	*StartInspectorTab(const QString &label);
    void	EndInspectorTab();

    /* Program properties */
    QWidget	*programTab;
    QCheckBox	*multipleSelectionBox;

    /* File properties */
    QWidget	*fileTab;
    QLabel	*filenameLabel;
    QLabel	*fileCreationDateLabel;
    QLabel	*entryCountLabel;
    QCheckBox	*sortBox;
    QComboBox	*defaultSortKeyBox;
    FontButton	*listFontButton;
    FontButton	*entryFontButton;

    /* Entry properties */
    QWidget	*entryTab;
    QLabel	*entryName;
    QComboBox	*entrySortKeyBox;
    QLabel	*entrySortName;
    QLabel	*entryCtime;
    QLabel	*entryMtime;
    QLabel	*entryAtime;
    QLabel	*entryCusername;
    QLabel	*entryMusername;

    /* Template */
    QMultiLineEdit *templateText;

    /* Revert Values */
    QDict<QString> revertValue;

public:
    Inspector( QWidget *parent = 0, const char *name = 0,
		     bool modal=TRUE, WFlags f=0);

 public slots:
    void    apply();
    void    revert();				  // restores previous value

    void    show();				  // sets the field, shows object
    void    showFile();				  // called when File property changes
    void    showEntry();			  // called when entry property changes
    void    showTemplate();

    /* These need to go away */

    void    setAllowMultipleSelections(int);
    void    setDefaultSortKey(int);
    void    setEntrySortKey(int);
    void    setSortEntries(int);
};

#endif
