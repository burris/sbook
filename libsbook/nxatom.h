/*
 * nxatom.h:
 *
 * A tribute to NeXTSTEP, implements NXUniqueString() and NXAtom
 */

#ifndef NXATOM_H
#define NXATOM_H

#include <memory.h>
#include <stdlib.h>
#include <stdio.h>

typedef const char *NXAtom;
NXAtom NXUniqueString(const char *string);

#ifdef __cplusplus
class NXAtomList
{
private:;
    NXAtom *data;
    unsigned int numAtoms;

public:
    NXAtomList();
    ~NXAtomList();
    NXAtomList *copy() const;
    unsigned int count() const;
    NXAtom  &operator[](unsigned int i) const;
    void    append(NXAtom);
    NXAtom  &last() const;
    void    print(FILE *f);
};
#else
typedef void NXAtomList;
#endif


extern NXAtom atom_blank;
extern NXAtom atom_dashes;
extern NXAtom atom_THE;
extern NXAtom atom_U;
extern NXAtom atom_S;
extern NXAtom atom_US;
extern NXAtom atom_AND;


#endif
