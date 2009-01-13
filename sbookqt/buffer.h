/* Internal Buffer class.
 * A buffer points at an un-terminated string in memory.
 */

#ifndef BUFFER_H
#define BUFFER_H

#include <qstring.h>
#include <malloc.h>

class Buffer {
    int	    buflen;
    int	    min_(int x,int y) {return (x<y)?x:y;};
     char *latin1_buf;
public:
    const char *buf;
    Buffer(const char *buf_=0,int buflen_=0)
    {
	buf = buf_;
	buflen = buflen_;
	latin1_buf = 0;				  // default
    };
    ~Buffer()
    {
	if(latin1_buf) free(latin1_buf);		  // remove temp memory
    }
    const char *latin1(){
	latin1_buf = (char *)malloc(buflen+1);
	memcpy(latin1_buf,buf,buflen);
	latin1_buf[buflen] = 0;
	return latin1_buf;
    }
    Buffer mid(int start,int len){
	return Buffer(buf+start,min_(len,buflen-start));
    };
    QString lower(){
	return qstring().lower();
    };
    QString qstring(){
	char *str = (char *)alloca(buflen+1);
	memcpy(str,buf,buflen);
	str[buflen] = 0;
	return QString(str);
    };
    void setBuf(const char *str){
	buf = str;
	buflen = strlen(str);
    };
    int length(){return buflen;};
    int toInt(){
	char *str = (char *)alloca(buflen+1);
	memcpy(str,buf,buflen);
	str[buflen] = 0;
	return atoi(str);
    };
    void truncate(int pos){
	if(pos<buflen)buflen=pos;
    };
    char at(int x){
	if(x<0) return 0;
	if(x>=buflen) return 0;
	return buf[x];
    };
    int find(char ch,int pos){
	register int i;
	for(i=pos;i<buflen;i++){
	    if(buf[i]==ch) return i;
	}
	return -1;
    }
    int compare(const char *buf2){
	return strncmp(buf,buf2,buflen);
    }
};

#endif
