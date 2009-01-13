/*
 * defaults.h:
 * Manage the defaults system.
 */

#ifndef DEFAULTS_H
#define DEFAULTS_H

#include <qstring.h>
void setGlobalDefaults(const QString &vendor, const QString &program);
class Defaults {
private:
    void	*hkMain;
public:
    static Defaults *globalDefaultObject();
    Defaults(const QString &vendor,
	     const QString &program);
    ~Defaults();

    void    set(const QString &name,const QString &value);
    void    set(const QString &name,bool value);

    QString get(const QString &name);
    bool    getBool(const QString &name);
};

#endif
