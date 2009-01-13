/*
 * ArrowLineEdit:
 * Implements the Search Field in sbook.
 */

#ifndef ARROWLINEEDIT_H
#define ARROWLINEEDIT_H

#include <qlineedit.h>
#include <qlistbox.h>


class Q_EXPORT ArrowLineEdit : public QLineEdit
{
public:
    ArrowLineEdit(QWidget *parent, const char * name=0); 
    QListBox	*listBox;
    virtual void keyUp(QKeyEvent *e);
    virtual void keyDown(QKeyEvent *e);
    virtual void keyEnter(QKeyEvent *e);
protected:
    virtual void keyPressEvent ( QKeyEvent * e );
};

#endif
