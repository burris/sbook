/*
 * $Id: hashtable.cpp,v 1.4 2004/07/21 03:18:14 simsong Exp $
 * $Date: 2004/07/21 03:18:14 $
 */

/*
 * "Copyright (C) 2000 by Sandstorm Enterprises, Inc.
 * This software is the exclusive property of Sandstorm.
 * This copy of the software may not be used or copied 
 * unless it is licensed from Sandstorm, and used 
 * under the exact terms and conditions contained 
 * in such license.  All source code and source code related 
 * information for this software is CONFIDENTIAL property of 
 * Sandstorm, and may not be accessed, disclosed, transferred 
 * or used except as may be permitted in the Sandstorm license 
 * applicable to this program copy. SANDSTORM HAS NO 
 * LIABILITY FOR INJURY OR LOSS THAT MAY BE CAUSED BY 
 * USE OF THIS SOFTWARE."
 *
 */

/*
 * Things to add:
 * 1. case insensetivity option.
 *
 *  HashTable.c:
 *  A highly-efficient, multi-threaded hash table designed for text processing.
 *  Copyright (C) 1999, Simson L. Garfinkel, Sandstorm Enterprises, Inc.
 *  Based on a hash table developed by Mark Austin and David Mazzoni.
 *
 * Note: 
 * Sandstorm HashTables are special hash tables:
 * 1. They have strings as their index.
 * 2. At each node they have two instance variables:
 *    count - records the # of times a key has been added.
 *    stringvalue - a string value for the node with this name.
 * 3. All memory management is automatic.
 *
 *  Original Copyright message follows:
 *  =================================================================== 
 *  hashtable.c : Data Structures and Functions for Hash Table 
 *                                                                     
 *  Copyright (C) 1993-96 by Mark Austin and David Mazzoni.
 *                                                                     
 *  This software is provided "as is" without express or implied warranty.
 *  Permission is granted to use this software on any computer system,
 *  and to redistribute it freely, subject to the following restrictions:
 * 
 *  1. The authors are not responsible for the consequences of use of
 *     this software, even if they arise from defects in the software.
 *  2. The origin of this software must not be misrepresented, either
 *     by explicit claim or by omission.
 *  3. Altered versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  4. This notice is to remain intact.
 *                                                                    
 *  Written by: Mark Austin                                October 1993
 *  ===================================================================
 *
 */

#include "hashtable.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#ifdef WIN32
#pragma warning( disable: 4115 )
#include <windows.h>
#else
#endif

#include <assert.h>

enum{ HashTableSize = 40009 };		 // a reasonably-sized prime number

/* Simson's very fast and somewhat generic 32-bit hash.
 * Optimzied for ASCII strings that look a lot alike. 
 * Works really well on ASCII strings that are different.
 */ 
unsigned int hash(const char *key)
{
	const char *cc;
	int	code=0;
	for(cc=key;*cc;cc++){
		code = (code<<7) ^ ((code>>24) ^ 0x80) ^ *cc;  
	}
	return code;
}

static const char *alloc_string(const char *string)
{
	if(string==0) string="";
	return strdup(string);
}

/*
 * Create a hash table
 */

HashTable *hashtable_alloc(int copykeys,int copyvalues)
{
	HashTable *ht;

	ht	= (HashTable *)calloc(sizeof(HashTable),1);
#ifdef WIN32
	InitializeCriticalSection(&ht->CS);
#endif
	ht->magic	= HashTableMagic;
	ht->tableSize	= HashTableSize;
	ht->table	= (HASHNODE **)calloc(sizeof(HASHNODE),HashTableSize);
	ht->copykeys	= copykeys;
	ht->copyvalues	= copyvalues;
	ht->next_serial = 1;

	return ht;
}

/*
 * Free a hash table
 */

void	hashtable_free(HashTable *ht)
{
	HASHNODE *spNext;
	HASHNODE *spNode;
	unsigned int i;

	assert(is_hashtable(ht));
	assert(ht->tableSize>0);

	for(i = 0; i < ht->tableSize; i++) {
		spNode = ht->table[ i ];
		while (spNode != NULL) {
			spNext = spNode->spNext;
			if(spNode->key)		free( (void *)spNode->key );
			if(spNode->stringvalue)	free( (void *)spNode->stringvalue  );
			free( spNode );

			spNode = spNext;
		}
		ht->table[ i ] = NULL;
	}
	free(ht->table);
#ifdef WIN32
	DeleteCriticalSection(&ht->CS);
#endif
	free(ht);
}

/* 
 *  =============================================================
 *  Lookup key name. return NULL if not found
 *  
 *  Input  :  char *key -- Pointer to name item in hash table.
 *  Output :  HASHNODE *   -- Pointer to node in hash table.
 *  =============================================================
 */ 

HASHNODE *hashtable_lookup(HashTable *ht,const char * key )
{
    HASHNODE *spNode;
    int   iHashValue;
    HASHNODE *rsp = NULL;

    assert(is_hashtable(ht));
    assert(ht->tableSize>0);

#ifdef WIN32
    EnterCriticalSection(&ht->CS);
#endif
    iHashValue = hash( key ) % ht->tableSize;

    for( spNode = ht->table[iHashValue];
	 spNode != NULL;
	 spNode = spNode->spNext) {

	if(strcmp( key , spNode->key) == 0) {
	    rsp = spNode;
	    break;
	}
    }
	
#ifdef WIN32
    LeaveCriticalSection(&ht->CS);
#endif
    assert(ht->tableSize>0);
    return rsp;
}

unsigned int	hashtable_keycount(HashTable *ht,const char *key)
{
	HASHNODE *hn;

	assert(is_hashtable(ht));
	hn = hashtable_lookup(ht,key);
	return hn ? hn->count : 0;
}

const char *hashtable_keyvalue(HashTable *ht,const char *key)
{
	HASHNODE *hn;

	assert(is_hashtable(ht));
	hn = hashtable_lookup(ht,key);
	return hn ? hn->stringvalue : 0;
}

unsigned  int hashtable_keyserial(HashTable *ht,const char *key)
{
	HASHNODE *hn;

	assert(is_hashtable(ht));
	hn = hashtable_lookup(ht,key);
	return hn ? hn->serial : 0;
}


/* 
 *  =============================================================
 *  hashtable_addkey(): Install new node into Hash Table if not already present
 *  
 *  Input  :  char *key -- Pointer to name item in hash table.
 *  Output :  HASHNODE *   -- Pointer to new hash table node.
 *  =============================================================
 */ 

HASHNODE *hashtable_addkeyvalue(HashTable *ht,
				const char *key,
				const char *value )
{
	HASHNODE *spNode;
	int   iHashValue;

	assert(is_hashtable(ht));
	assert(ht->tableSize>0);
   
#ifdef WIN32
	EnterCriticalSection(&ht->CS);
#endif

	/* Make sure node isn't already in hash table */
	spNode = hashtable_lookup( ht,key );

	assert(ht->tableSize>0);

	if( spNode != NULL) {

		/* We already have a node with this key.
		 * Increment count, replace the stringvalue, and return.
		 */
		spNode->count++;
		if(spNode->stringvalue){
			free((void *)spNode->stringvalue);
			spNode->stringvalue = 0;
		}
		if(value){
			spNode->stringvalue = ht->copyvalues ? alloc_string(value): value;
		}
		goto done;
	}

	assert(ht->tableSize>0);

	/* No node exists with this key.
	 * Allocate memory for new hash node
	 */
	spNode = (HASHNODE *) calloc( sizeof(HASHNODE), 1);
	spNode->key	= ht->copykeys ? alloc_string(key): key;
	spNode->count	= 1;
	spNode->stringvalue = ht->copyvalues ? alloc_string(value): value;
	spNode->serial	= ht->next_serial++;

	/* Link new node into front of list */

	iHashValue     = hash( key ) % ht->tableSize;
	spNode->spNext = ht->table[ iHashValue ];
	ht->table[ iHashValue ] = spNode;

 done:
#ifdef WIN32
	LeaveCriticalSection(&ht->CS);
#endif
	return spNode;
}

HASHNODE *hashtable_addkey(HashTable *ht,const char * key)
{
	return hashtable_addkeyvalue(ht,key,0);
}

unsigned int hashtable_count(HashTable *ht)
{
	HASHNODE *spNode;
	unsigned int		i;
	unsigned int		count=0;

	assert(is_hashtable(ht));
	assert(ht->tableSize>0);


#ifdef WIN32
	EnterCriticalSection(&ht->CS);
#endif
    for(i = 0; i < ht->tableSize; i++) {
        for(spNode = ht->table[ i ]; spNode != NULL; spNode = spNode->spNext) {
			count++;
		}
	}
#ifdef WIN32
	LeaveCriticalSection(&ht->CS);
#endif
	return count;
}

static int strcompare( const void *arg1, const void *arg2 )
{
	return strcmp( * ( char** ) arg1, * ( char** ) arg2 );
}

const char **hashtable_keys(HashTable *ht,int sorted,int alloc)
{
	unsigned int		count;
	const char **keys;
	unsigned int		i;

	assert(is_hashtable(ht));
	assert(ht->tableSize>0);

#ifdef WIN32
	EnterCriticalSection(&ht->CS);
#endif
	count = hashtable_count(ht);				  // keys in table
	keys = (const char **)calloc(count+1,sizeof(char *)); // allocate space for the keys
	count = 0;									  // reset counter

	/* Now get the keys */
    for(i = 0; i < ht->tableSize; i++) {
		HASHNODE *spNode;

        for(spNode = ht->table[ i ]; spNode != NULL; spNode = spNode->spNext) {
			keys[count++] = alloc ? alloc_string(spNode->key) : spNode->key;
		}
	}
	if(sorted){
		qsort(keys,count,sizeof(char *),strcompare);
	}
#ifdef WIN32
	LeaveCriticalSection(&ht->CS);
#endif
	return keys;
}

/****************************************************************
 * DEBUG
 ****************************************************************/


/* 
 *  ============================
 *  Print contents of Hash Table 
 *  ============================
 */ 

enum { Ncol = 4 };

void hashtable_print(HashTable *ht)
{
	HASHNODE *spNode;
	unsigned int   i, iCount;

	assert(is_hashtable(ht));
	assert(ht->tableSize>0);

#ifdef WIN32
	EnterCriticalSection(&ht->CS);
#endif
    for(i = 0; i < ht->tableSize; i++) {

        iCount = 0;
        printf("\n INFO >> i = %3d : ", i);

        for(spNode = ht->table[ i ]; spNode != NULL; spNode = spNode->spNext) {

            printf("%17s (%d) ", spNode->key,spNode->count );
            iCount = iCount + 1;
            if( iCount%Ncol == 0 && spNode->spNext != NULL) {
                iCount = 0;
                printf("\n                    ");
            }
        }
    }
    printf("\n");
#ifdef WIN32
	LeaveCriticalSection(&ht->CS);
#endif
}


void hashtable_printstats(FILE *f,HashTable *ht)
{
	unsigned int i;
	int maxdepth=0;
	int filled=0;

	assert(is_hashtable(ht));
	assert(ht->tableSize>0);

#ifdef WIN32
	EnterCriticalSection(&ht->CS);
#endif

    for(i = 0; i < ht->tableSize; i++) {
		if(ht->table[i]){
			int		depth=0;
			HASHNODE *spNode = ht->table[i];

			filled++;
			while(spNode != NULL){
				depth++;
				spNode = spNode->spNext;
			}
			if(depth>maxdepth) maxdepth=depth;
		}
	}
#ifdef WIN32
	LeaveCriticalSection(&ht->CS);
#endif
	fprintf(f,"HashTable           %lx\n",(unsigned long )ht);
	fprintf(f,"Table size:         %d\n",ht->tableSize);
	fprintf(f,"Filled slots:       %d (%2d%%)\n",filled,filled*100/ht->tableSize);
	fprintf(f,"Maximum slot depth: %d\n",maxdepth);
}
