/* 
 * NXAtom implementation.
 *  
 * NXAtoms are char * strings that are stored in a global hash table.
 * By definition, two strings equivillent strings will hash to the same
 * NXAtom, so you can do comparisons based on == rather than strcmp.
 * NXAtoms cannot be freed.
 */

#include "nxatom.h"
#include "hashtable.h"

static HashTable *ht = 0;

NXAtom atom_blank   = NXUniqueString("");
NXAtom atom_dashes  = NXUniqueString("--------");
NXAtom atom_THE	    = NXUniqueString("THE");
NXAtom atom_U	    = NXUniqueString("U");
NXAtom atom_S	    = NXUniqueString("S");
NXAtom atom_US	    = NXUniqueString("US");
NXAtom atom_AND	    = NXUniqueString("AND");


/*
 * NXUniqueStrng:
 * Return an NXAtom for a buffer.
 * In the NeXTSTEP implementation, this returns a value that cannot be modified
 * becuase it is stored in read-only memory.
 */

long nxatom_from_cache = 0;
long nxatom_alloc = 0;

NXAtom NXUniqueString(const char *key)
{
    const char *value  = 0;

    if(!ht){					  // need to create the hashtable
	ht = hashtable_alloc(1,0);
    }
    /* If it is in the hash table, just return the reference */
    value = hashtable_keyvalue(ht,key);
    if(!value){
	/* It wasn't there; add it */
	value = strdup(key);			  // make a copy, which will be the value
	hashtable_addkeyvalue(ht,key,value);
	nxatom_alloc++;
    }
    else {
	nxatom_from_cache++;
    }
    return value;				  // return the "unique" string
}

NXAtomList::NXAtomList()
{
    data = (NXAtom *)malloc(0);
    numAtoms = 0;
}

NXAtomList::~NXAtomList()
{
    if(data){
	free(data);
	data=0;
    }
}

void NXAtomList::append(NXAtom anAtom)
{
    data = (NXAtom *)realloc(data,sizeof(NXAtom)*(numAtoms+1));
    data[numAtoms] = anAtom;
    numAtoms++;
}

NXAtom &NXAtomList::operator[](unsigned int i) const
{
    if(i<0) return data[0];
    if(i>=numAtoms) return data[numAtoms-1];
    return data[i];
}

unsigned int NXAtomList::count() const
{
    return numAtoms;
}

NXAtom &NXAtomList::last() const
{
    if(numAtoms==0) return atom_blank;
    return data[numAtoms-1];
}

NXAtomList *NXAtomList::copy() const
{
    NXAtomList *n = new NXAtomList();
    int len = sizeof(NXAtom)*(numAtoms);
    n->data = (NXAtom *)realloc(n->data,len);
    memcpy(n->data,data,len);
    n->numAtoms = numAtoms;
    return n;
}

void NXAtomList::print(FILE *f)
{
    unsigned int i;
    for(i=0;i<numAtoms;i++){
	fprintf(f,"%s",data[i]);
	if(i<numAtoms-1) fputc(',',f);
    }
}


