/*
 * AddressBook test.
 */

#import "AddressBookSyncer.h"
#import "ABPersonAdditions.h"
#import <AddressBook/ABAddressBook.h>


#import "tools.mm"
#import "getopt.h"

NSUserDefaults *defaults=nil;
int debug=0;


int main(int argc,char **argv)
{

    int opt_v = 0;
    int ch;
    char *match = 0;
    while((ch = getopt(argc,argv,"vu:")) != -1){
	switch(ch){
	case 'v':
	    opt_v = 1;
	    break;
	case 'u':
	    match = optarg;
	    break;
	}
	
    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    ABAddressBook *ab = [ABAddressBook sharedAddressBook];
    NSEnumerator *en= [[ab people] objectEnumerator];
    ABPerson *abp;
    if(match) printf("Searching for %s\n",match);

    while((abp = [en nextObject])){
	id r = [abp stringWithDefaultLabel:@"Home"];

	if(match && (strstr([r UTF8String],match)==0)) break;

	if(opt_v){
	    NSLog(@"\n\n******************** Read from AddressBook ******************");
	    NSLog(@"%@",abp);
	}
	printf("%s================\n",[r UTF8String]);
    }
}
