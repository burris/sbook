#ifndef SMENUCELL_H
#define SMENUCELL_H
#include <qpopupmenu.h>

class SMenuCell 
{
    QPopupMenu *menu;
    int		item;
public:
    SMenuCell(QPopupMenu *menu,int item);
    void setItemEnabled(bool enabled);
    
};


inline SMenuCell::SMenuCell(QPopupMenu *menu_,int item_)
{
    menu = menu_;
    item = item_;
}


inline void SMenuCell::setItemEnabled(bool enabled)
{
    menu->setItemEnabled(item,enabled);
}


#endif
