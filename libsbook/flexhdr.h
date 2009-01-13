/* this is used to make a flex file self-contained */

#include <stdlib.h>
#include <string.h>

#ifdef WIN32
#include <malloc.h>
#endif

/* Input System */
static  int Yeof=0;
static	const char *input_buf=0;			  // buffer we are reading
static  int input_len=0;

static void Yinput(char *buf,int *result,int max_size)
{
    int bytes 		= input_len;
    if(bytes>max_size) bytes=max_size;
    memcpy(buf,input_buf,bytes);
    *result		= bytes;
    input_buf		+=bytes;
    input_len           -= bytes;
    Yeof		= bytes==0;
}

#define	YY_USER_ACTION	if(Yeof) return 0;
#define YY_NEVER_INTERACTIVE  1			  // we are not interactive
#define YY_NO_UNPUT
#define	YY_INPUT(buf,result,max_size) Yinput(buf,&result,max_size)

#undef 	ECHO
#define	ECHO {}

#define YY_SKIP_YYWRAP

static void PSETUP(const char *base,int len)
{
    input_buf		= base;
    input_len		= len;
    yy_init		= 1;    
    yy_current_buffer	= 0;
    yy_c_buf_p 		= 0;
    yy_start		= 0;
    yyin		= 0;
    yyout		= 0;
    Yeof		= 0;
}

#define PSHUTDOWN if(yy_current_buffer){\
 yy_delete_buffer(yy_current_buffer); \
 yy_current_buffer	= 0; }\




