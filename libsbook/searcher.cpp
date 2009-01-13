/*
 * searcher:
 * create a tre and rapidly search it.
 */

using namespace std;

#include <stdio.h>
#include <string>

#define WORDS "/usr/share/dict/words"

class tre {
public:
    tre();
    void add(const u_char *buf,void (*action)(class tre *));
    void add(const char *buf,void (*action)(class tre *)) { add((const u_char *)buf,action);}
   
    void check(const u_char *buf);
    void check(const char *buf) { check((const u_char *)buf);}
    class tre *next[256];		// where to go next
    void (*action)(class tre *);	// what to do when you get here
};

tre::tre()
{
    memset(next,0,sizeof(next));
}

void tre::add(const u_char *buf,void (*action)(class tre *))
{
    class tre *where  = this;

    while(buf[0]){
	if(where->next[buf[0]]==0){
	    /* Need to create a new node */
	    where->next[buf[0]] = new tre();
	}
	/* Now there is a node at buf[0]. Change our vantage point*/
	where = where->next[buf[0]];
	buf++;			// go to the next character
    }
    /* At this point, we have walked through buf */
    where->action = action;
}

void tre::check(const u_char *buf)
{
    class tre *where = this;

    printf("Checking %s... ",buf);
    while(buf[0]){
	if(where->next[buf[0]]==0){
	    printf("Not in data structure\n");
	    return;
	}
	where = where->next[buf[0]];
	buf++;
    }
    (*where->action)(where);
}

void blurb(class tre *t)
{
    printf("In structure at %p\n",t);
}

int main(int argc,char **argv)
{
    class tre t;

    t.check("Simson");


    t.add("entries",blurb);
    t.add("entrycount",blurb);
    t.add("frame",blurb);
    t.add("divider",blurb);
    t.add("flags",blurb);
    t.add("searchmode",blurb);
    t.add("template",blurb);
    t.add("rtftemplate",blurb);
    t.add("defaultsortkey",blurb);
    t.add("defaultpersonflags",blurb);
    t.add("defaultusername",blurb);
    t.add("searchentrymode",blurb);
    t.add("entrycount",blurb);
    t.add("entry",blurb);
    t.add("filecreationdate",blurb);

    /* Now check */
    t.check("Simson");
    t.check("entries");
    t.check("entrycount");
    t.check("frame");
    t.check("divider");
    t.check("flags");
    t.check("searchmode");
    t.check("template");
    t.check("rtftemplate");
    t.check("defaultsortkey");
    t.check("defaultpersonflags");
    t.check("defaultusername");
    t.check("searchentrymode");
    t.check("entrycount");
    t.check("entry");
    t.check("filecreationdate");
    t.check("Garfinkel");
    

}
 
