/*
 * sbookreader.cpp:
 * 
 * Test the program.
 */

#include "libsbook.h"

/* C++ stuff */
#include <string>

#include "xmlparse.h"
#include "nxatom.h"
#include "encrypted_object.h"

#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <err.h>
#include <stdio.h>
#include <iostream>

int opt_c = 0;
int opt_cgi = 0;

using namespace std;

void errorfunc(const char *buf)
{
    puts(buf);
}

void usage()
{
    printf("sbookreader: testing for SBook XML\n");
    printf("usage: sbookreader [options] <filename>\n");
    printf("options:\n");
    printf("   -s str - search for str\n");
    printf("   -w file - write the file to file\n");
    printf("   -k key  - specify the encryption key\n");
    printf("   -e      - encrypt filename\n");
    printf("   -d      - decrypt filename\n");
    printf("   -1      - print every entry 'last, first'\n");
    printf("   -g <gid> - print the entry with the given GID\n");
    printf("   -G       - like -g, but take each gid on stdin and print each followed by a .\n");
    printf("   -c       - HTML/CGI mode (default if run as CGI)\n");
    exit(0);
}

int main(int argc,char **argv)
{
    char *data;
    int  len;
    int  fd;
    char *opt_w = 0;
    char *opt_s = 0;
    char *opt_k = 0;
    char *opt_g = 0;
    int opt_e = 0;
    int opt_d = 0;
    int opt_1 = 0;
    int opt_G = 0;
    int ch;

    if(getenv("GATEWAY_INTERFACE")){
	opt_cgi = 1;
    }

    while((ch = getopt(argc,argv,"w:s:k:ed1g:G")) != -1 ){
	switch(ch){
	case '1':
	    opt_1++;
	    break;
	case 'w':
	    opt_w = optarg;
	    break;
	case 's':
	    opt_s = optarg;
	    break;
	case 'k':
	    opt_k = optarg;
	    break;
	case 'e':
	    opt_e++;
	    break;
	case 'd':
	    opt_d++;
	    break;
	case 'g':
	    opt_g = optarg;
	    break;
	case 'G':
	    opt_G++;
	    break;
	default:
	    usage();
	case 'c':
	    opt_c = 1;
	    break;
	}
    }

    argc -= optind;
    argv += optind;
    

    if(argc<1){
	usage();
    }

    const char *fn = argv[0];

    fd = open(fn,O_RDONLY);
    if(fd<0) err(1,fn);
    len = lseek(fd,0,SEEK_END);
    if(len<0) err(1,"lseek: %s",fn);
    lseek(fd,0,0);			// back to beginning

    data = (char *)malloc(len+1);
    if(read(fd,data,len)!=len) err(1,"read: %s",fn);
    data[len] = '\000';			// null terminate
    close(fd);

    /* If we are encrypting or decrypting, do it */
    sstring key("a key");
    sstring sdata(data,len);
    if(opt_e){
	sstring *str = Encrypted_Object::encrypt_object(&sdata,&key);
	printf("%s\n",str->c_str());
	return(0);
    }

    if(opt_d){
	sstring *str = Encrypted_Object::decrypt_object(&sdata,&key);
	if(!str) err(1,"decrypt_object failed: \n");
	printf("%s\n",str->c_str());
	return(0);
    }


    EntryList *e = EntryList::xmlread(data,len,0,errorfunc);

    if(opt_1){
	for(EntryIterator it = e->begin(); it != e->end(); it++){
	    Entry *ent = *it;
	    printf("  %30s  -> %30s\n",
		   ent->cellName(0).c_str(),
		   ent->cellName(1).c_str());
	}
    }

    if(opt_s){
	if(!opt_cgi) printf("Searching for '%s'...\n",opt_s);
	
	EntryVector *ev = e->doSearch(opt_s,SEARCH_WORD_MATCH);

	if(!opt_cgi) printf("Found %d items:\n",(int)ev->size());
	for(EntryIterator it = ev->begin(); it != ev->end(); it++){
	    Entry *ent = *it;
	    if(!opt_cgi) cout << "  ";
	    cout << ent->gid << ":";

	    if(!opt_cgi) cout << "  ";
	    cout << ent->cellName() << "\n";

	    //sstring xml;

	    //ent->xml_make(&xml);
	    //printf(" Here is the XML for this entry:\n%s\n\n\n",xml.c_str());
	}
    }

    if(opt_g){
	Entry *ent = e->entryWithGid(opt_g);
	if(ent){
	    cout << *ent << "\n";
	}
    }

    if(opt_G){
	while(!feof(stdin)){
	    char buf[1024];
	    if(fgets(buf,sizeof(buf),stdin)==0) return 0;
	    char *cc = index(buf,'\n');
	    if(cc) *cc='\000';
	    cout << buf << "\n";
	    Entry *ent = e->entryWithGid(buf);
	    if(ent){
		cout << *ent;
	    }
	    cout << ".\n";
	}
    }

    if(opt_w){
	sstring xml;
	e->xml_make(&xml);

	FILE *out = fopen(opt_w,"w");
	fwrite(xml.data(),1,xml.size(),out);
	fclose(out);
    }

}
