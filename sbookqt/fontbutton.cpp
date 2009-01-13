#include "fontbutton.h"
#include <qfontdialog.h>
#include <stdio.h>

FontButton::FontButton( QWidget *parent, const char *name)
    : QPushButton(parent,name)
{
    setTheFont(QFont("Arial",12));		  // default font
    connect(this,SIGNAL(clicked()),this,SLOT(doClick()));
}

void FontButton::setTheFont(const QFont &font)
{
    QString name;

#if 0
    theFont = font;
    name.sprintf("%s %d",
		 theFont.family().latin1(),
		 theFont.pointSize());
	printf("setting font to name %s\n",name.latin1());
    setText(name);
    setMinimumSize(sizeHint());			  // resize the button
#endif
}

void FontButton::doClick()
{
    bool ok;

    printf("FontButton::doCLick %s\n",theFont.family().latin1());
    QFont f = QFontDialog::getFont( &ok, theFont,this );
    if ( ok ) {
        // the user selected a valid font
	setTheFont(f);
    }
}
