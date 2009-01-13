#include "myqfiledialog.h"

MyQFileDialog::MyQFileDialog( const QString& dirName,
			      const QString& filter,
			      QWidget *parent,
			      const char *name,
			      bool modal)
{
    QFileDialog(dirName,filter,parent,name,true);
}


void MyQFileDialog::setFilter(const QString &filter)
{
    QFileDialog::setFilter(filter);
}
