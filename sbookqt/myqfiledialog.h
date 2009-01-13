#include "sbook.h"

#ifndef MYQFD_H
#define MYQFD_H
#include <qfiledialog.h>
#include <qstring.h>

class Q_EXPORT MyQFileDialog : public QFileDialog
{
    Q_OBJECT

public:
    MyQFileDialog( const QString& dirName,
		   const QString& filter = QString::null,
		   QWidget *parent=0, const char *name=0, bool modal=FALSE );
public slots:
    void setFilter( const QString& );
};
#endif
