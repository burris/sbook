/* MD5.H - header file for MD5C.C
 */

/* Copyright (C) 1991, RSA Data Security, Inc. All rights reserved.

   License to copy and use this software is granted provided that it
   is identified as the "RSA Data Security, Inc. MD5 Message-Digest
   Algorithm" in all material mentioning or referencing this software
   or this function.

   License is also granted to make and use derivative works provided
   that such works are identified as "derived from the RSA Data
   Security, Inc. MD5 Message-Digest Algorithm" in all material
   mentioning or referencing the derived work.  
                                                                    
   RSA Data Security, Inc. makes no representations concerning either
   the merchantability of this software or the suitability of this
   software for any particular purpose. It is provided "as is"
   without express or implied warranty of any kind.  
                                                                    
   These notices must be retained in any copies of any part of this
   documentation and/or software.  
 */

#ifndef _SLIB_MD5_H_
#define _SLIB_MD5_H_

#include <memory.h>
#include <string.h>
#include <stdio.h>

#ifdef  __cplusplus
extern "C" {
#endif

#ifdef __NEVER_DEFINED__
} // close extern "C" for emacs
#endif

#define MD5_LEN 16				  // RSA didn't put this in their include file

typedef unsigned long UINT4;
#define PROTO_LIST(x) x
#define POINTER char *

/* If MD5_DIGEST_LENGTH is defined, then the OpenSSL
 * md5.h has already been included. Don't include this one, because
 * the definitions for MD5_CTX are subtly different (although largely
 * compatiable.)
 *
 * If you are getting errors here, include OpenSSL *before* including slib.
 */

#ifndef MD5_DIGEST_LENGTH
/* MD5 context. */
typedef struct {
  UINT4 state[4];                                           /* state (ABCD) */
  UINT4 count[2];                /* number of bits, modulo 2^64 (lsb first) */
  unsigned char buffer[64];                                 /* input buffer */
} MD5_CTX;
#endif

void MD5Init PROTO_LIST ((MD5_CTX *));
void MD5Update PROTO_LIST ((MD5_CTX *, unsigned char *, unsigned int));
void MD5Final PROTO_LIST ((unsigned char [16], MD5_CTX *));

/* This one gets an MD5 for a C-string */
void MD5FromBuffer(unsigned char *buffer,unsigned int len,unsigned char result[16]);


#ifdef __NEVER_DEFINED__
{
#endif
#ifdef  __cplusplus
}
#endif

#endif // _SLIB_MD5_H_

