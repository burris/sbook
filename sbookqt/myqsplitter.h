#include "sbook.h"

#ifndef MYQSPLITTER_H
#define MYQSPLITTER_H
#include <qsplitter.h>
#include <qpainter.h>

class MyQSplitter : public QSplitter
{
    Q_OBJECT

public:
    MyQSplitter( QWidget *parent=0, const char *name=0 );
    MyQSplitter( Orientation o, QWidget *parent=0, const char *name=0 );
protected:
    virtual void drawSplitter( QPainter*, QCOORD x, QCOORD y,
			       QCOORD w, QCOORD h );

};

#endif
