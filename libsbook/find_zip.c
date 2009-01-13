#include "libsbook.h"

#include <stdio.h>
#include <sys/types.h>
#include <regex.h>


static	char *strdup_len(const char *buf,int len)
{
    char *b = (char *)malloc(len+1);
    memcpy(b,buf,len);
    b[len] = '\000';
    return b;
}

void	find_cityStateZip(const char *buf,char **city_,char **state_,char **zip_)
{
    regmatch_t pmatch[6];
    static int init=0;
    static	regex_t cszreg;
    if(init==0){
	if(regcomp(&cszreg,
		   "([^,]{2,})(,? +)([A-Za-z]{2,}\\.?)( +)([0-9]{5}(-[0-9]{4})?)",
		   REG_EXTENDED|REG_ICASE)){
	    perror("regcomp");
	}
	init = 1;
    }
    memset(pmatch,0,sizeof(pmatch));
    if(regexec(&cszreg,buf,6,pmatch,0)){
	return;			/* no match */
    }
    char  *city = strdup_len(buf+pmatch[1].rm_so,pmatch[1].rm_eo-pmatch[1].rm_so);
    int spaces1 = pmatch[2].rm_eo-pmatch[2].rm_so;
    char  *state = strdup_len(buf+pmatch[3].rm_so,pmatch[3].rm_eo-pmatch[3].rm_so);
    int spaces2 = pmatch[4].rm_eo-pmatch[4].rm_so;
    char  *zip = strdup_len(buf+pmatch[5].rm_so,pmatch[5].rm_eo-pmatch[5].rm_so);

    /* Now, if length of city, state and zip is "significantly" less than
     * the length of the original, declare this experiment a failure.
     * (we should also validate state with the state parser, alas).
     */

    int missed_chars = strlen(buf) - (strlen(city)+strlen(state)+strlen(zip)+spaces1+spaces2);

    if(missed_chars > 2){
	free(city);city = 0;
	free(state);state = 0;
	free(zip);zip = 0;
	return;
    }
    if(strlen(city)){
	if(city_) *city_ = city;
	else free(city);
    }
    if(strlen(state)){
	if(state_) *state_ = state;
	else free(state);
    }
    if(strlen(zip)){
	if(zip_) *zip_ = zip;
	else free(zip);
    }
}

const char *find_zip(const char *buf,int *len)
{
    regmatch_t pmatch[1];
    static	regex_t zipreg;
    static int init =0;
    if(init==0){
	if(regcomp(&zipreg,"[0-9][0-9][0-9][0-9][0-9](-[0-9][0-9][0-9][0-9])?",REG_EXTENDED)){
	    perror("regcomp");
	}
	init = 1;
    }

    if(regexec(&zipreg,buf,1,pmatch,0)){
	return 0;			/* no match */
    }
    if(len) *len = pmatch[0].rm_eo - pmatch[0].rm_so;
    return(buf+pmatch[0].rm_so);
}
