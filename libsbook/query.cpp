/*
 * query.cpp:
 *
 * generic query tool for libsbook.
 * Also handles web stuff.
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#ifdef UNIX
#include <unistd.h>
#endif

#ifdef WIN32
#include <getopt.h>
#endif

#include "libsbook.h"



char *file = 0;
char *progname = "";

unsigned opt_b = 0;
int quiet = 0;
void usage()
{
    puts("query is for testing out the 'parse entry' stuff.");
    printf("usage: %s [options]\n",progname);
    puts("    -a <line> = explain a particular name, all parsers");
    puts("    -c <filename> = just print companies in the file (one per line)");
    puts("    -p <filename> = just print people (one per line)");
    puts("    -e <name> = explain a name");
    puts("    -w <name> = explain for the website (outputs HTML)");
    puts("    -b P_BUT_TELEPHONE  = each line that doesn't begin with a # must be a telephone and only a telephone");
    puts("    -f <file> = run parser on a file as if it were an entry.");
    puts("    -q    Quiet mode (no debugging)");
    puts("    -m <name1> -n <matchstr> = test matching system");
    puts("    -v <file> = run the vcard parser on an SBookASCII file");
    puts("    -V        - parse STDIN as vcard and output in HTML");
    puts("    -z <line> - try find_cityStateZip()");
    puts("    -w <name> = explain for the website");
    puts("    -r <line> = explain a particular name, all parsers");
    exit(0);
}

void explain_iflags(int flag)
{
    printf(" %8x = ",flag);
    if(flag &  P_TELEPHONE) printf(" P_TELEPHONE");
    if(flag & P_EMAIL ) printf(" P_EMAIL");
    if(flag & P_LABEL) printf(" P_LABEL");
    if(flag & P_ZIP) printf(" P_ZIP");
    if(flag & P_BLANKLINE) printf(" P_BLANKLINE");
    if(flag & P_ADDRESS) printf(" P_ADDRESS");
    if(flag & P_WEAK) printf(" P_WEAK");
    if(flag & P_COUNTRY) printf(" P_COUNTRY");
    if(flag & P_CITY) printf(" P_CITY");
    if(flag & P_STATE) printf(" P_STATE");
    if(flag & P_DATE) printf(" P_DATE");
    if(flag & P_DIRECTIONS) printf(" P_DIRECTIONS");
    if(flag & P_STREET) printf(" P_STREET");
    if(flag & P_ORG) printf(" P_ORG");
    if(flag & P_NEWS) printf(" P_NEWS");
    if(flag & P_OFFICE) printf(" P_OFFICE");
    if(flag & P_NAME) printf(" P_NAME");
    if(flag & P_NOT_TELEPHONE) printf(" P_NOT_TELEPHONE");
    if(flag & P_URL) printf(" P_URL");
    if(flag & P_ATTRIB_BOLD) printf(" P_ATTRIB_BOLD");
    if(flag & P_ATTRIB_ITALIC) printf(" P_ATTRIB_ITALIC");
    if(flag & P_ATTRIB_FLAGS) printf(" P_ATTRIB_FLAGS");
    puts("");
}


void explain_results_flags(int flag)
{
    printf("0x8%x ",flag);
    switch(flag & P_BUT_MASK){
    case P_BUT_EMAIL: printf(" P_BUT_EMAIL ");break;
    case P_BUT_ADDRESS: printf(" P_BUT_ADDRESS ");break;
    case P_BUT_TELEPHONE: printf(" P_BUT_TELEPHONE ");break;
    case P_BUT_LINK: printf(" P_BUT_LINK ");break;
    case P_BUT_PERSON: printf(" P_BUT_PERSON ");break;
    case P_BUT_COMPANY: printf(" P_BUT_COMPANY ");break;
    case P_NOT_ADDRESS: printf(" P_NOT_ADDRESS ");break;
    case P_BUT_IM:printf(" P_BUT_IM ");break;
    case P_BUT_FILE:printf(" P_BUT_FILE ");break;
    default: printf(" button %x ",flag & P_BUT_MASK);break;
    }
    
    if(flag & P_FOUND_LABEL) printf(" P_FOUND_LABEL ");
    if(flag & P_FOUND_ASTART) printf(" P_FOUND_ASTART ");
    if(flag & P_FOUND_AEND) printf(" P_FOUND_AEND ");

    puts("");
}


int explain_name(const char *str)
{
    int entryFlags = 0;
    int a = parse_address(str) | parse_email(str);

    printf("parse_company0(%s)=0x%x\n",str,parse_company0(str));
    printf("parse_stocks(%s)=%d\n",str,parse_stocks(str));
    printf("parse_address(%s)=0x%x  %s%s%s\n",
	   str,a,
	   a & P_EMAIL ? "P_EMAIL " : "",
	   a & P_ADDRESS ? "P_ADDRESS " : "",
	   a & P_TELEPHONE ? "P_TELEPHONE " : ""
	   );
    printf("parse_company(%s) = %d\n",str,parse_company(str));

    NXAtomList *atoms = atomsForNames(str,false);

    int isPerson= 0;

    printf("smartSortName(%s) = %s\n",str,smartSortName(str,entryFlags,*atoms,&isPerson));
    printf("isPerson = %d\n",isPerson);
    exit(0);
}

int webexplain(const char *word)
{
    int entryFlags = 0;
    int a = parse_company(word);
    int s = parse_stocks(word);
    int c0 = parse_company0(word);
    int a0 = parse_address(word) | parse_email(word);
    int j=0;
    const char *what = a ? "company" : "person";
    int isPerson;

    NXAtomList *alist = atomsForNames(word,false);

    printf("<b>%s</b> is a <b>%s</b><p>\n",
	   word,what);
    printf("<i>because:</i><br>\n");
    printf("<ul>");
    if(s){
	printf("<li>It looks like a publically traded company\n");
	j++;
    }
    if(c0){
	printf("<li>It reminds me of other companies that I know\n");
	j++;
    }
    if((a0 & P_ADDRESS) &&
       !(a0 & P_WEAK)){
	printf("<li>It looks like an address I've seen before\n");
	j++;
    }
    if(j==0){
	printf("<li>It just looks like a %s\n",what);
    }
    
    printf("</ul>\n");
    printf("This entry will be sorted under <b>%s</b><p>\n",
 	   smartSortName(word,entryFlags,*alist,&isPerson));
    exit(0);
    
    
	
}

void do_file(const char *fname)
{
    char *buf = (char *)malloc(0);
    char  **lines=0;
    unsigned int   *results=0;
    unsigned int   numLines=0;
    unsigned int   i=0;

    FILE *f = fopen(fname,"r");
    if(!f){
	perror(fname);
	return;
    }
    while(!feof(f)){
	char lbuf[1024];

	if(fgets(lbuf,sizeof(lbuf),f)){
	    buf = (char *)realloc(buf,strlen(buf)+strlen(lbuf)+1);
	    strcat(buf,lbuf);
	}
    }
    fclose(f);
    if(!quiet){
	parse_block(buf,&lines,&results,&numLines,0,0);
	printf("numLines: %d\n",numLines);
	for(i=0;i<numLines;i++){
	    printf("[%2d]: %-30s: ",i,lines[i]);
	    explain_results_flags(results[i]);
	}
	free_block(lines,results);
    }

#if 0
    char *vcard = parse_block_to_vcard(buf);
    printf("%s",vcard);
    free(vcard);
#endif
}

void match_test(char *name,char *str)
{
    NXAtomList *l1 = atomsForNames(name,false);

    fprintf(stdout,"sbookIncrementalMatch(");
    l1->print(stdout);
    fprintf(stdout," | %s) = %d\n",name,sbookIncrementalMatch(l1,str));
}


void do_webvcard()
{
    char buf[65536];
    char b2[65536];
    char vc[65536*2];

    if(isatty(fileno(stdin))){
	fprintf(stderr,"Enter an unparsed block of text:\n");
	fflush(stderr);
    }

    buf[0] = 0;
    while(!feof(stdin)){
	b2[0]  = 0;
	fgets(b2,sizeof(b2),stdin);
	strcat(buf,b2);
    }
    /* Now remove any '<' to deal with cross-site scripting bugs */
    char *cc;
    while((cc=index(buf,'>'))!=0){
	*cc = ' ';
    }

    memset(vc,0,sizeof(vc));
    parse_block_to_vcard(buf,0,vc,sizeof(vc));
    strcat(vc,"END: vCard\n");
    printf("<pre>\n%s</pre>\n",vc);
}

void do_vcard(const char *fname)
{
    char buf[65536];
    char b2[65536];

    FILE *vcardin = fopen(fname,"r");
    if(!vcardin){
	perror(fname);
	return;
    }
    int cards=0;
    buf[0] = 0;
    while(!feof(vcardin)){
	b2[0]  = 0;
	fgets(b2,sizeof(b2),vcardin);
	if(b2[0]==0 || b2[0]=='='){
	    char vc[65536];

	    parse_block_to_vcard(buf,0,vc,sizeof(vc));
	    strcat(buf,"END: vCard\n");
	    puts(buf);
	    puts("-------");
	    puts(vc);
	    puts("===========================");
	    buf[0] = 0;
	    b2[0] = 0;
	    cards++;
	}
	else{
	    strcat(buf,b2);
	}
    }
    fclose(vcardin);
    printf("cards parsed: %d\n",cards);
}

/* Print all of the lines the match the mask */
void match_lines(const char *file,int mask)
{
    FILE *f = fopen(file,"r");
    if(!f){
	perror(file);
	return;
    }
    while(!feof(f)){
	char buf[1024];
	if(fgets(buf,sizeof(buf),f)){
	    const char *lines[1] = {buf};
	    unsigned int results[1] = {0};
	    parse_lines(1,lines,0,0,results,0,0);

	    if(results[0] & mask){
		fputs(lines[0],stdout);
	    }
	}
    }
    fclose(f);
}

void results(const char *line)
{
    const char *lines[3] = {line,line,0};
    unsigned int results[2] = {0};
    unsigned int attributes[2];
    struct tm tm;
    extern int pa_debug;

    tm.tm_hour = -1;
    tm.tm_min  = -1;
    tm.tm_sec  = -1;
    tm.tm_mon  = -1;
    tm.tm_mday = -1;
    tm.tm_year = -1;

    printf("results(%s):\n",line);

    parse_lines(2,lines,0,attributes,results,0,0);
    parse_time(line,&tm);

    printf("parse_company(%s)=%x\n",line,parse_company(line));
    printf("parse_stocks(%s)=%x\n",line,parse_stocks(line));
    printf("parse_company0(%s)=%x\n",line,parse_company0(line));

    unsigned int arg;
    unsigned int res = parse_telephone(line,&arg);
    printf("parse_telephone(%s)=%x (arg=%d)\n",line,res,arg);


    printf("parse_address(%s)=%x (debug=%d)\n",line,parse_address(line),pa_debug);
    printf("parse_email(%s)=%x\n",line,parse_email(line));
    printf("parse_extra(%s)=%x\n",line,parse_extra(line));
    printf("parse_time(%s)=  %d:%d:%d %d/%d/%d\n",
	   line,tm.tm_hour,tm.tm_min,tm.tm_sec,tm.tm_mon+1,tm.tm_mday,tm.tm_year);
    printf("parse_lines(%s)=%x\n",line,results[0]);
    printf("identify_line(%s)=%x\n",line,identify_line(line));

    printf("first line results: ");explain_results_flags(results[0]);
    printf("second line results: ");explain_results_flags(results[1]);

    if(results[1] & P_FOUND_LABEL){
	char *f = (char *)malloc(strlen(line));
	extract_label(line,f);
	printf("  label: '%s'\n",f);
	free(f);
    }
}


int main(int argc,char **argv)
{
    int ch;
    int do_title = 1;
    int right = 0;
    int wrong = 0;
    char *opt_m = 0;
    char *opt_n = 0;
    char *city=0;
    char *state=0;
    char *zip=0;
    unsigned int entryFlags=0;

    progname = argv[0];
    while((ch = getopt(argc,argv,"c:p:e:w:b:a:f:qm:n:v:Vz:")) != -1){
	switch(ch){
	case 'q':
	    quiet=1;
	    break;
	case 'c':
	    match_lines(optarg,P_BUT_COMPANY);
	    return 0;
	case 'p':
	    match_lines(optarg,P_BUT_PERSON);
	    return 0;
	case 'e':
	    explain_name(optarg);
	    break;
	case 'w':
	    webexplain(optarg);
	    break;
	case 'a':
	    sbook_parser_debug = 1;
	    results(optarg);
	    return 0;
	case 'f':
	    sbook_parser_debug = 1;
	    do_file(optarg);
	    return 0;
	case 'b':
	    if(!strcasecmp(optarg,"P_BUT_TELEPHONE")){
		opt_b = P_BUT_TELEPHONE;
	    }
	    if(opt_b == 0){
		fprintf(stderr,"invalid -b option: '%s'\n",optarg);
		usage();
	    }
	    do_title = 0;
	    break;
	case 'm':
	    opt_m = optarg;
	    break;
	case 'n':
	    opt_n = optarg;
	    break;
	case 'v':
	    do_vcard(optarg);
	    return 0;
	case 'V':
	    do_webvcard();
	    return 0;
	case 'z':
	    find_cityStateZip(optarg,&city,&state,&zip);
	    printf("city=%s\nstate=%s\nzip=%s\n",city,state,zip);
	    return 0;
	default:
	    usage();
	}
    }
    argc -= optind;
    argv += optind;

    if(opt_m && opt_n){
	match_test(opt_m,opt_n);
	exit(0);
    }

    if(argc<1){
	printf("argc=%d\n",argc);
	usage();
    }
    file = argv[0];

    FILE *f = fopen(file,"r");

    if(do_title){
	printf("%-40s%-10s%6s%6s%6s\n","Name","Smart","Case?","Addr","Company");
    }
    char buf[1024];
    while(fgets(buf,sizeof(buf),f)){

	/* Skip a line that begins with a comment character */
	if(buf[0]=='#') continue;

	/* Remove carriage returns & linefeeds */
	char *cc = strchr(buf,'\n');
	if(cc) *cc = ' ';
	cc = strchr(buf,'\r');
	if(cc) *cc = ' ';

	/* If option B, run this line through the full parser */
	if(opt_b){
	    const char *lines[2];
	    unsigned int results[2];

	    lines[0] = "name";
	    lines[1] = buf;
	    results[0] = 0;
	    results[1] = 0;
	    
	    parse_lines(2,lines,0,0,results,0,0);

	    if((results[1] & P_BUT_MASK) == opt_b){
		right ++;
	    }
	    else{
		printf("parse_lines[1]('%s') = 0x%x (wanted 0x%x)\n",lines[1],results[1],opt_b);
		wrong ++;
	    }
	    
	    continue;
	}


	int isPerson;

	NXAtomList *atoms  = atomsForNames(buf,false);
	unsigned int	a = parse_case(buf);
	unsigned int	b = parse_address(buf);
	unsigned int    c = parse_company(buf);
	unsigned int    d = parse_email(buf);
	delete atoms;


	NXAtom  smartName = smartSortName(buf,entryFlags,*atoms,&isPerson);
	printf("%-40s%-10s%6x%6x%6x%6x\n",buf,smartName,a,b,c,d);
    }

    printf("right: %d\nwrong: %d\n",right,wrong);
    return 0;
}
