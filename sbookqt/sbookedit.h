#include "sbook.h"

#ifndef SBOOKEDIT_H
#define SBOOKEDIT_H
#include <qmultilineedit.h>

class SBookEdit:public QMultiLineEdit
{
    Q_OBJECT;
private:
    bool    edited;				  // true if we have been edited since last setText
public:
    SBookEdit ( QWidget * parent=0, const char * name=0 );
    class ArrowLineEdit *searchField;
    void selectFirstLine();
    void selectSecondLine();
public slots:
    void paste();
    virtual void setText(const QString &text);
protected:
    virtual void mouseMoveEvent(QMouseEvent *);
    virtual void mouseDoubleClickEvent ( QMouseEvent * e );
    virtual void keyPressEvent(QKeyEvent *);

};
#endif
