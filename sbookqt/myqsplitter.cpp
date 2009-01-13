#include "myqsplitter.h"
MyQSplitter::MyQSplitter( QWidget *parent, const char *name )
    :QSplitter( parent, name )
{
}

MyQSplitter::MyQSplitter( Orientation o, QWidget *parent, const char *name )
    : QSplitter( o, parent, name )
{
}

void MyQSplitter::drawSplitter( QPainter*p, QCOORD x, QCOORD y, QCOORD w, QCOORD h )
{
    p->fillRect(x,y,w,h,gray);
}
