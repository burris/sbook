/*
 * (C) Copyright 1992 by Simson Garfinkel and Associates, Inc.
 *
 * All Rights Reserved.
 *
 * Use of this module is covered by your source-code license agreement with
 * Simson Garfinkel and Associates, Inc.  Use of this module, or any code
 * that it contains, without a valid source-code license agreement is a
 * violation of copyright law.
 *
 */

#include "Entry.h"
#include "Parser.h"
#include "Identifier.h"
#include "IdentifierList.h"
#include <libsbook.h>

#ifndef MIN
#define MIN(a,b) (a)<(b)?(a):(b)
#endif

Parser *theParser = 0;

Parser::Parser()
{
    zip = new IdentifierList();

    zip->addPattern("[A-Z][A-Za-z]*[,. ]*[0-9][0-9][0-9][0-9][0-9]",false);
    zip->addPattern("[A-Z][0-9][A-Z][ ][0-9][A-Z][0-9]",false);      /*CANADA*/
    zip->addPattern("[A-Z][0-9][A-Z][0-9][A-Z]",false);              /*CANADA*/
    zip->addPattern("[A-Z][A-Z][0-9][A-Z][ ][0-9][A-Z][A-Z]",false);/*UK*/

    notphone = new IdentifierList();
    notphone->addPattern("[$][0-9][0-9]*",false);
    notphone->addPattern("room",true);

    /* These telephone patterns are better handled here than in flex.
     * But international phone numbers are handled in the flex file.
     */
    telephones = new IdentifierList();
    telephones->addPattern("[^0-9][0-9A-Z][0-9A-Z][0-9][- .][0-9][0-9][0-9][0-9][^0-9]",false,true);

    telephones->addPattern("[^0-9][0-9A-Z][0-9A-Z][0-9] - [0-9][0-9][0-9][0-9][^0-9]",false,true);
    telephones->addPattern("[ xX][0-9]-[0-9][0-9][0-9]",false,true);
    telephones->addPattern("[ ]phone.*[0-9][0-9][0-9]",true,true);

    label 	= new Identifier("^[a-z0-9()',.{}!@#$%^&*()`~/ ]*:[ ]*$",true);

    address = new IdentifierList();

    address->addPattern("[, ]p[. ]*o[. ]*b[ox]*",true,true);
    address->addPattern("[, ]box[ 0-9]",true,true);
    address->addPattern("[,. ]RR[ 0-9]",false,true);
    address->addPattern("[,. ]RFD[ 0-9]",false,true);
    address->addPattern("[A-Z][A-Za-z], [A-Z][A-Z]",false);

    blankLine = new Identifier("^[ ]*$",false);

    lineFlags = (int *)malloc(0);
    addresses = new SButtonList();
    emails = new SButtonList();
    e_telephones = new SButtonList();

    numLines=0;
}

int Parser::identifyLine(const char *aLine)
{
    int	res = 0;

    res |= parse_address(aLine);
    res |= parse_case(aLine);
    
    //    if(strchr(aLine,ICON_CHAR))	res |= P_PUSHBUTTON;

    if(zip->match(aLine)) 	res |= (P_ZIP | P_ADDRESS);
    if(label->match(aLine))	res |= P_LABEL;
    if(address->match(aLine))	res |= P_ADDRESS;

    if(res & (P_ADDRESS|P_EMAIL)){
	/* Paper and electronic addresses cannot be telephone numbers */
	res	&= ~P_TELEPHONE;
    }
    else{
	/* Things to check if we are not an address */
	if(telephones->match(aLine))	res |= P_TELEPHONE;
	if(notphone->match(aLine))	res &= ~P_TELEPHONE;
	if(blankLine->match(aLine))	res |= P_BLANKLINE;

	/* fix the bug with Office */
	if(res & P_OFFICE){
	    if(telephones->match(aLine)){
		res	&= ~P_ADDRESS;
		res	|= P_TELEPHONE;
	    }
	}
    }
    return res;
}

void Parser::setEntryAndParse(class Entry *entry_)
{
    entry = entry_;

    /* Now allocate the new one */

    parseEntry();
}

QString Parser::addressN(unsigned int n)
{
    int a1;
    QString ret;
    int i;

    n = MIN(n,address->count()-1);

    if(addresses->count()==0){
	return "";
    }
    
    ret.append(entry->getLine(0));			  // get the name in
    ret.append('\n');
    a1 = *(addresses->at(n));

    printf("address %d starts at line %d\n",n,a1);

    for(i = a1;i<numLines && (lineFlags[i] & P_NOT_ADDRESS)==0;i++){
	ret.append(entry->getLine(i));
	ret.append('\n');
    }
    return ret;
}


QString Parser::emailN(unsigned int n)
{
    n = MIN(n,emails->count()-1);

    if(emails->count()==0){
	return "";
    }
    return entry->getLine(*emails->at(n));
}

QString Parser::telephoneN(unsigned int n)
{
    n = MIN(n,e_telephones->count()-1);

    if(e_telephones->count()==0){
	return "";
    }
    return entry->getLine(*e_telephones->at(n));
}


#if 0

    int i;
    int parsed_lines = lines();

    if(lineFlags){
	free(lineFlags);
	lineFlags = 0;
    }

    lineFlags = (int *)calloc(sizeof(int),parsed_lines);

    for(i=0;i<parsed_lines;i++){
	QString s = getLine(i);
	lineFlags[i] = parse_address(s.latin1());
    }

/* Parse the entire text */
#endif

void Parser::parseEntry()
{
    int	i;

    numLines = entry->lines();			  // get number of lines
    lineFlags = (int *)realloc(lineFlags,sizeof(int)*numLines);
    addresses->clear();
    emails->clear();
    e_telephones->clear();

    //[self	removeAllButSpecialIcons];

    for(i=0;i<numLines;i++){ 
	lineFlags[i]	= identifyLine(entry->getLine(i));

#if 0
	/* put in the icons */
	[text	setParIndent:NOLABEL_INDENT start:1 end:paragraphs];
	[text	setSel:0 :0];
	
	/* Unindent any lines that have buttons already */
	for(i=1;i<paragraphs;i++){
		if(ld[i] & P_PUSHBUTTON){
			[text setParIndent:LABEL_INDENT start:i end:i];
		}
	}
#endif
    }

    /* Now scan and parse... */
    for(i=1;i<numLines;i++){
	//bool	bold,ital;
	int	hasbut	= lineFlags[i] & P_PUSHBUTTON;

#if 0
	if(dontParseFlag & (DONT_PARSE_ITALIC|DONT_PARSE_BOLD)){
	    [text	getAttribForGraph:(int)i ital:&ital bold:&bold];
	    
	    if(ital && (dontParseFlag & DONT_PARSE_ITALIC)) continue;
	    if(bold && (dontParseFlag & DONT_PARSE_BOLD)) 	continue;
	}
#endif	
	
#if 0
	/* undent the labels */
	if((lineFlags[i] & P_LABEL) || hasbut){
	    [text setParIndent:LABEL_INDENT start:i end:i];
	    [text setSelProp:NX_INDENT to:NOLABEL_INDENT];
	    [text setSelProp:NX_ADDTAB to:NOLABEL_INDENT];
	    [text setSel:0 :0];
	    if(lineFlags[i] & P_LABEL) continue;
	}
#endif

	/* Insert a telephone button */
	if(lineFlags[i] & P_TELEPHONE){
	    e_telephones->push_back(i);

	    if(!hasbut){
		//[text insertButton:BUTTON_TELEPHONE_NEW atGraph:i];
	    }
	    continue;
	}

	if(lineFlags[i] & P_EMAIL){
	    emails->push_back(i);		  // remember this loc
	    if(!hasbut){
		//[text insertButton:BUTTON_EMAIL_NEW atGraph:i ];
	    }
	    continue;
	}
	if(lineFlags[i] & P_BLANKLINE){
	    if(entry->dontParseFlag & DONT_PARSE_AFTER_BLANK) break;
	    continue;
	}
	/* Hm... Haven't identified this line.  Could be address
	 * or blank.
	 *
	 * Scan for the last line that is either blank or address in
	 * this block.  Then, if two lines are addresses, delcare this
	 * an address...
	 */
	float	alines=0;
	int	ziplines=0;
	int	countryLine=0;
	int	stateCountry=0;
	int	linesInBlock=0;
	int	dirlines = 0;
	int	j;
	bool	hasbut2 = 0;
	
	/* Scan forward to see if we can find the end of the block.
	 * Count all of the things that we found in this block on the
	 * way down.
	 */
	for(j=i;j<numLines;j++){
	    int	flag;
		
	    flag	= lineFlags[j];
		
	    if(flag & P_NOT_ADDRESS){
		j--;
		break; /* not aline or blank */
	    }
	    linesInBlock++;
	    if(flag & P_ZIP)		ziplines++;
	    if(flag & P_PUSHBUTTON)	hasbut2  = true;
	    if(flag & P_COUNTRY)	countryLine = linesInBlock;
	    if(flag & (P_STATE|P_COUNTRY))	stateCountry = linesInBlock;
	    if(flag & P_DIRECTIONS) dirlines++;
	    if(flag & P_ADDRESS) 	alines += 1.0;
	}
#ifdef FOO
	printf("countryLine=%d alines=%f ziplines=%d\n",
	       countryLine,alines,ziplines);
#endif		
	if(linesInBlock>1){
	    if(((countryLine>0) && (countryLine+1>=linesInBlock))
	       || (stateCountry==linesInBlock)
	       || alines>1
	       || (alines==1 && ziplines==1)
	       || (alines==1 && linesInBlock==2 && dirlines==0)){
		if(dirlines<2 && hasbut2==0){
		    /* We found an address. Note it at line i */
		    
		    addresses->push_back(i);
#if 0
		    [text
		    insertButton:BUTTON_ENVELOPE_NEW
		    atGraph:i];
#endif
		}
	    }
	}
	if(j>i) i = j;
    }
}




#if 0

- insertCell:(int)kind atGraph:(int)i
{
	int	start,end;
	NXRect	rect;
	id 	cell = [[ActiveCell alloc] initCell:kind
		      		forSLC:slc
		      		person:[slc personDisplayed]];

	[text		getParagraph:i start:&start
       			end:&end rect:&rect];
	[text 		setSel:end-1 :end-1];
	[text		replaceSel:"\n"];
	[text 		replaceSelWithCell:cell];
	[text		alignSelRight:self];
	[slc		setTextChanged:YES];
	return self;
}

/* Remove all of the icons from the text object except those that were specially set... */
- removeAllButSpecialIcons
{
	NXStream	*textStream = NXOpenMemory(0,0,NX_READWRITE);
	char		*addr;
	int 		len,maxlen;
	char		*cc;
	NXStream	*richStream = NXOpenMemory(0,0,NX_READWRITE);

	[text		writeText:textStream];
	NXPutc(textStream,'\000');

	NXGetMemoryBuffer(textStream,&addr,&len,&maxlen);

	/* Start at the end of the text, get each cell, and look at its flag... */
	while(cc = rindex(addr,ICON_CHAR)){
		int	start = cc-addr;
		int	activeCellsWritten = [ActiveCell activeCellsWritten];

		[text	writeRichText:richStream from:start to:start+1];
		if(activeCellsWritten != [ActiveCell activeCellsWritten]){
			/* an active cell was written; what kind was it? */
			if(([ActiveCell lastFlagWritten] & INSERTED_BY_HAND) == 0){
				int	delLen = 1;

				if(cc[1]=='\t') delLen=2; /* delete the \t as well */

				/* okay. delete it */
				[text	setSel:cc-addr :cc-addr+delLen]; /* set the selection here */
				[text	replaceSel:""];	/* gone */
			}
		}
		*cc	= '\000';	/* ignore this char and the rest */
	}
	NXCloseMemory(richStream,NX_FREEBUFFER); /* get rid of the rich stream */
	NXCloseMemory(textStream,NX_FREEBUFFER);

	return self;
}
#endif

#if 0
-(int)findGraphOfFirstButton:(int)type
{
	int	i;

	for(i=0;;i++){
		int	res = [self	identifyGraph:i];

		if(res==-1) return -1;	/* couldn't find */
		if(res & P_PUSHBUTTON){
			/* found a button; check to see if it is right type */
			char	*buf;

			buf	= [text getRichParagraph:i];
		}
	}
	return 0;
}
#endif


#if 0
/* Called to possibly do something interesting with the previous
 * line when return is pressed...
 */

-processLine:(const char *)line paragraph:(int)paragraph
{
	int	type = [Parser identifyLine:line];
	int	addButton = 0;
	int	addGraph  = paragraph;
	BOOL	ital,bold;
	int	dpf = [[slc doc] dontParseFlag];
	int	start,end;

	if(paragraph==0) return self;	/* don't do the first one */

	[text	getAttribForGraph:paragraph ital:&ital bold:&bold];
	if(ital && (dpf & DONT_PARSE_ITALIC)) return self;
	if(bold && (dpf & DONT_PARSE_BOLD)) return self;

	if(type & P_PUSHBUTTON) return self; /* already labled */

	if(type & P_TELEPHONE){
		addButton = BUTTON_TELEPHONE_NEW;
		goto add;
	}
	if(type & P_EMAIL){
		addButton = BUTTON_EMAIL_NEW;
		goto add;
	}
	if((type & (P_STATE|P_COUNTRY|P_ZIP)) && !(type & P_STREET)){
		/* End of address code
		 * Read the contents, then
		 * search up for the first line of the address
		 */
		int	i;

		for(i=paragraph-1;i>0;i--){
			type = [self identifyGraph:i];
			if(type & P_PUSHBUTTON){
				int	iconType;
				char	*buf;

				/* A pushbutton.  If it is an envelope, don't
				 * put in a bushbutton.  Otherwise, label the
				 * previous line.
				 */

				buf	= [text getRichParagraph:i];
				iconType = [ActiveCell findCellTypeForParagraph:0
				  		inBuf:buf];
				free(buf);
				if(iconType==BUTTON_ENVELOPE_NEW){
					return self; /* already labled with env */
				}
				break;	/* label next */
			}

			if(type & P_NOT_ADDRESS){
				break;
			}
		}
		addButton = BUTTON_ENVELOPE_NEW;
		addGraph = i+1;
		goto add;
	}
	return self;			/* nothing found */

      add:
	[text	insertButton:addButton atGraph:addGraph];
	[text	getParagraph:paragraph+1 start:&start end:&end];
	[text	setSel:start :start];	/* return  cursor */
	return self;
}

#endif


