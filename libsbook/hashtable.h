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
 * 2. threadsafe option.
 *
 *  Substantially modified by Simson L. Garfinkel, Sandstorm Enterprises.
 *  =================================================================== 
 *  hashtable.h : Data Structures and Functions for Hash Table 
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
 * Note: 
 * Sandstorm HashTables are special hash tables:
 * 1. They have strings as their index.
 * 2. At each node they have two instance variables:
 *    count - records the # of times a value has been added.
 *    value - a string value for the node with this name.
 *
 */



#ifndef _HASHTABLE_H
#define _HASHTABLE_H

#include <stdio.h>

/* Windows includes */
#ifdef WIN32
#include <windows.h>
#endif

/* UNIX includes */
#ifdef UNIX
#endif


#ifdef	__cplusplus
extern "C" {
#endif


/* Data Structure for Hash Table Node */

typedef struct HashTableNode {
    const char    *key;				  // the key
	unsigned int count;			  // # times this key added
	unsigned int serial;			  // serial number
    const char	*stringvalue;			  // string value
	struct  HashTableNode *spNext;		  
} HASHNODE;

#define HashTableMagic 0xdead1234

typedef struct HashTable_ {
	unsigned int magic;	  // magic number
	unsigned int	tableSize;		  // size of array
	HASHNODE		**table;	  // 
	unsigned int	next_serial;		  // 
    int copykeys;
    int copyvalues;
#ifdef WIN32
	CRITICAL_SECTION CS;			  // threadsafe
#endif
} HashTable;

#define is_hashtable(ht) (ht->magic == HashTableMagic)


/* Internal functions */
HASHNODE * HashTableInstall(HashTable *ht,const char *string);
HASHNODE * hashtable_lookup(HashTable *ht,const char *string);

/* External Interface for Hash Table Functions */

/* Create a hash table: */
HashTable	*hashtable_alloc(int copykeys,int copyvalues);

/* Free the hash table */
void		hashtable_free(HashTable *ht);

/* Total number of nodes in the hash table: */
unsigned int	hashtable_count(HashTable *ht);

/* return information associated with a key */
unsigned int	hashtable_keycount(HashTable *ht,const char *key);
const char	*hashtable_keyvalue(HashTable *ht,const char *key);
unsigned int	hashtable_keyserial(HashTable *ht,const char *key);


/* Returns an array of all the keys.
 * You must free the returned value.
 * If alloc=1, the strings are allocated for you,
 * and you must free them as well.
 */
const char **	hashtable_keys(HashTable *ht,int sorted,int alloc);


/* Debug print to stdout */
void		hashtable_printstats(FILE *f,HashTable *ht);
void		hashtable_print(HashTable *ht);

/* Adding functions */
HASHNODE	*hashtable_addkey(HashTable *ht,const char * string );
HASHNODE	*hashtable_addkeyvalue(HashTable *ht, const char *string, const char *value);

#ifdef  __cplusplus
}
#endif



#endif // _SLIB_HASHTABLE_H_

