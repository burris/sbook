#ifndef PARSER_H
#define PARSER_H

#include <qstring.h>
#include <qstringlist.h>
#include <qvaluelist.h>

class Parser
{
private:
    class IdentifierList *zip;
    class IdentifierList *notphone;
    class Identifier	*label;
    class Identifier	*blankLine;
    class IdentifierList *address;
    class IdentifierList *telephones;

    class Entry		*entry;

public:
    Parser();

    int		*lineFlags;	// a flag for each line
    int		numLines;

    class	SButtonList *addresses;
    class	SButtonList *emails;
    class	SButtonList *e_telephones;

    int		identifyLine(const char *aLine);
    void	setEntryAndParse(class Entry *);
    void	parseEntry();
    QString	addressN(unsigned n);
    QString	emailN(unsigned n);
    QString	telephoneN(unsigned n);
};

extern Parser *theParser;			  // the global parser

class SButtonList : public QValueList<int>
{
};    


#endif
