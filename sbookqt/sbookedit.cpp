#include "sbookedit.h"
#include "arrowlineedit.h"
#include <stdio.h>
#include <qclipboard.h>
#include <qapplication.h>

SBookEdit::SBookEdit ( QWidget * parent, const char * name )
    :QMultiLineEdit(parent,name)
{
    setUndoDepth(10);
}

void SBookEdit::selectFirstLine()
{
    setSelection(0,0,0,65535);
}

void SBookEdit::selectSecondLine()
{
    setSelection(1,0,1,65535);
}

void SBookEdit::mouseMoveEvent(QMouseEvent *event)
{
    if(searchField->hasFocus()){
	searchField->clearFocus();
	setFocus();
    }

    QMultiLineEdit::mouseMoveEvent(event);
}

void SBookEdit::mouseDoubleClickEvent(QMouseEvent *event)
{
    if(searchField->hasFocus()){
	searchField->clearFocus();
	setFocus();
    }
    QMultiLineEdit::mouseDoubleClickEvent(event);
}

/* special handling of keystorkes within the sbook editor.
 * If we hit return on the first line, just selected the second
 * line.
 */
void SBookEdit::keyPressEvent(QKeyEvent *event)
{
    int line,col;

    /* Special key processing */
    switch(event->key()){
	/* Pressing return on the first line takes you to the second line
	 * unless the Alt  key is down.
	 */
    case Key_Return:
	getCursorPosition(&line,&col);
	if(line==0 && numLines()>1 && ((event->state()&AltButton)==0)){
	    selectSecondLine();
	    return;
	}
	break;					  // no second row; just handle normally
    case Key_V:					  
	if(event->state() & ControlButton){	  // ^v does our special paste
	    paste();
	    return;
	}
	break;
    case Key_A:					  // ^a does a select all
	if(event->state() & ControlButton){
	    selectAll();
	    return;
	}
    }
    /* Default - just handle the event */
    QTextEdit::keyPressEvent(event);
    edited = true;				  // we have done something here
}

void SBookEdit::setText(const QString &text)
{
    edited = false;
    QMultiLineEdit::setText(text);
}

/* 
 * Special paste logic.
 * If we are on the first line, and if we have a multi-line paste,
 * then replace the paste with the first line of the paste,
 * do the paste onto the first line, replace the clipboard with the rest,
 * select the entire second line, and paste the rest.
 */
void SBookEdit::paste()
{
    int line,col;
    getCursorPosition(&line,&col);
    if(line!=0 || numLines()<2 ){			  // not on first line or 1 row; 
	QTextEdit::paste();		  // handle normally
	return;
    }
    QClipboard *cb = QApplication::clipboard();
    
    int nl = cb->text().find('\n');
    if(nl==-1 || (int)cb->text().length() == nl+1){
	QTextEdit::paste();
	return;
    }
    QString allText= cb->text();		  // make a copy
    QString line1  = cb->text().mid(0,nl-1);
    QString theRest= cb->text().mid(nl+1);

    /* Paste in the first line */
    cb->setText(line1);
    QTextEdit::paste();			  // paste in the first line

    /* If we haven't edited, select the entire second line.
     * Otherwise, just move to the beginning of the second line
     */
    if(edited==false){
	selectSecondLine();
    }
    else{
	setCursorPosition(1,0);			  // move to the next row
    }

    /* Now paste in the second line */
    cb->setText(theRest);
    QTextEdit::paste();
    cb->setText(allText);			  // restore the clipboard
}
