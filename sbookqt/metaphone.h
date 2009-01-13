/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law.
 *
 */

/*
**  Metaphone
**  Convert text into a metaphone form (similar to soundex)
**
**  Computer Language, December 1990  p.41
**  Converted from the original Pick BASIC to C by William Adams
**
**  Exceptions:
**	Initial  kn-, gn-, pn-, ae-, wr-		->	drop first letter
**	Initial  x					-> 	change to 's'
**	Initial  wh-					->	change to 'w'
*/
 
#define	SOUNDEX_LENGTH	6

#import <objc/HashTable.h>

char 	*metaphone(const char *name, char *metaph);
NXAtom	metaphoneName(const char *name);


