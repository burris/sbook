#include "base64.h"
#include "libsbook.h"

#ifndef __APPLE__
NSPoint NSMakePoint(float x, float y) {
    NSPoint p;
    p.x = x;
    p.y = y;
    return p;
}

NSSize NSMakeSize(float w, float h) {
    NSSize s;
    s.width = w;
    s.height = h;
    return s;
}

NSRect NSMakeRect(float x, float y, float w, float h) {
    NSRect r;
    r.origin.x = x;
    r.origin.y = y;
    r.size.width = w;
    r.size.height = h;
    return r;
}

#endif


sstring *stringForB64SString(const sstring &str)
{
    int	decode_len         = str.size()+16;
    char *buf = (char *)malloc(decode_len);
    int  datasize;
	    
    datasize = b64_pton_slg(str.c_str(),
			    str.size(),
			    (unsigned char *)buf,
			    decode_len);

    if(datasize<0){
	fprintf(stderr,"dataForB64String: failed. decode_len=%d ",decode_len);
	return 0;
    }
    sstring *ret = new sstring(buf,datasize);
    free(buf);
    return ret;
}

sstring *b64stringForSString(const sstring &str)
{
    sstring *ostr = new sstring;

    int buflen = str.size()*2;
    char *buf = (char *)malloc(buflen);
    int  len  = b64_ntop((const unsigned char *)str.data(),
			 str.size(),
			 buf,buflen);
    ostr->assign(buf,len);
    free(buf);
    return ostr;
}
