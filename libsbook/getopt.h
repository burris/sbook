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



#ifndef _GETOPT_H_
#define _GETOPT_H_


#ifdef  __cplusplus
extern "C" {
#endif

#ifdef __NEVER_DEFINED__
} // close extern "C" for emacs
#endif


int	getopt(int argc, char * const *argv, const char *opts);
extern  int optind;
extern	int optopt;
extern	char *optarg;

#ifdef __NEVER_DEFINED__
{
#endif
#ifdef  __cplusplus
}
#endif

#endif
