#include "sbook.h"

/*
 * fontbutton.h:
 *
 * Defines the FontButton object, sort of like a QPushButton
 * except it has an associated QFont and the text is equal to the font,
 * and when you push the butto you can change the font.
 */

#ifndef FONTPUSHBUTTON_H
#define FONTPUSHBUTTON_H

#include <qfont.h>
#include <qpushbutton.h>

class FontButton: public QPushButton
{
    Q_OBJECT

public:
    FontButton( QWidget *parent, const char *name=0 );

    void    setTheFont(const QFont &font);
    QFont   &getTheFont(void) {return theFont;}

public slots:
    void    doClick();
 
private:
    QFont   theFont;
};
#endif

