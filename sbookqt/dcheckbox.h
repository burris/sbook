/*
 * DCheckBox:
 * Like a DCheckBox, but stores defaults.
 */

#ifndef DCHECKBOX_H
#define DCHECKBOX_H
#include "defaults.h"
#include <qcheckbox.h>
class DCheckBox: public QCheckBox {
    Q_OBJECT;
public:
    DCheckBox( QWidget *parent, const char *name=0 );
    DCheckBox( const QString &text, QWidget *parent, const char* name=0 );
private slots:
    void doStateChanged(int state);
};

#endif
