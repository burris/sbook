/* 
 * ArrowLineEdit:
 * Line edit that can control a matrix with the arrows.
 */
 
#include "arrowlineedit.h"
#include <stdio.h>

ArrowLineEdit::ArrowLineEdit(QWidget *parent,const char *name)
    : QLineEdit(parent,name)
{
    setKeyCompression(false);			  // bad for arrow handling
}

void ArrowLineEdit::keyUp(QKeyEvent * e)
{
    listBox->setCurrentItem(listBox->currentItem()-1);
}

/* keyDown:
 * Select the next selected entry. If no entry is selected, select first.
 */
void ArrowLineEdit::keyDown(QKeyEvent * e)
{
    int nextRow = listBox->currentItem()+1;

    if(nextRow < listBox->numRows()){
	listBox->setCurrentItem(nextRow);
    }
}

void ArrowLineEdit::keyEnter(QKeyEvent * e)
{
    keyDown(e);
}



void ArrowLineEdit::keyPressEvent( QKeyEvent * e )
{
    switch(e->key()){
    case Key_Up:
	keyUp(e);
	return;
    case Key_Down:
	keyDown(e);
	return;
    case Key_Enter:
    case Key_Return:
	keyEnter(e);
	return;
    default:
	QLineEdit::keyPressEvent(e);
    }
}
