/*
 * encrypted_object.cpp:
 *
 * Support for reading and writing encrypted XML objects.
 */

#include "libsbook.h"
#include "encrypted_object.h"
#include "xmlparse.h"
#include "nxatom.h"
#include "blowfish.h"
#include "base64.h"
#include "md5.h"
#include <err.h>

#define SIZE_FMT "%d"

#ifdef __APPLE__
#undef SIZE_FMT
#define SIZE_FMT "%ld"
#endif


/* the data structure used for the reader */

struct Encrypted_XML {
    sstring	*buf;			// the actual data being read

    sstring	*edata;		// encrypted object we read
    sstring	*md5;
    unsigned long length;

    int		depth;
    int		list_flags;	// set at end to prevent sorting on each addition
    int		process;	// do we want this element?
    int		level1;
    int		level2;
    int		level3;

};

static void startDoc(void *userData,const XML_Char *doctypeName)
{
}

static void endDoc(void *userData)
{
}

/* Handle the data between tags */
static void characterDataHandler(void *userData,const XML_Char *s,int len)
{
    struct Encrypted_XML *data = (struct Encrypted_XML *)userData;

    if(data->buf==0){
	data->buf = new sstring;
    }
    data->buf->append(s,len);
}

static void startElement(void *userData, const char *name_, const char **atts)
{
    struct Encrypted_XML *data = (struct Encrypted_XML *)userData;

    if(data->buf){
	delete data->buf;
	data->buf = 0;			// don't need it
    }


    data->depth ++;

    /* Special stuff that needs to be done at the beginning of an element */
    switch(data->depth){
    case 1:				// outermost
	if(!strcmp(name_,"EncryptedObject")){
	    data->process = 1;
	}
	return;
    default:
	break;
    }
}

static void endElement(void *userData, const char *name_)
{
    struct Encrypted_XML *data = (struct Encrypted_XML *)userData;

    if(data->process){
	if(!strcmp(name_,"edata")){
	    data->edata = data->buf;
	    data->buf = 0;
	}
	if(!strcmp(name_,"length")){
	    data->length = atoi(data->buf->c_str());
	}
	if(!strcmp(name_,"md5")){
	    data->md5   = data->buf;
	    data->buf = 0;
	}
    }
    if(data->buf){
	delete data->buf;
	data->buf = 0;
    }
    data->depth --;
}

sstring *Encrypted_Object::decrypt_object(sstring *buf,sstring *key)
{
    XML_Parser parser = XML_ParserCreate(NULL);
    struct Encrypted_XML data;
    sstring *res = 0;

    /* Set up the parser */
    memset(&data,0,sizeof(data));

    XML_SetUserData(parser, &data);
    XML_SetDoctypeDeclHandler(parser, startDoc, endDoc);
    XML_SetElementHandler(parser, startElement, endElement);
    XML_SetCharacterDataHandler(parser,characterDataHandler);

    if (!XML_Parse(parser, buf->data(), buf->size(), 1)) {
	char buf[2048];
	sprintf(buf,"XML Error: %s at line %d",
		XML_ErrorString(XML_GetErrorCode(parser)),XML_GetCurrentLineNumber(parser));
	fprintf(stderr,"%s:\n",buf);
	return 0;
    }
    XML_ParserFree(parser);

    unsigned char md5[16];		// holds the md5

    if(data.edata && data.md5){
	BF_KEY bfkey;
	unsigned char iv[256];			// initialization vector

	int ebuf_len = data.length + 16;
	unsigned char *ebuf = (unsigned char *)malloc(ebuf_len);
	memset(ebuf,'A',data.length);
	if(ebuf){
	    b64_pton_slg(data.edata->data(),
			 data.edata->length(),
			 ebuf,
			 ebuf_len);


	    /* Set up the key */
	    BF_set_key(&bfkey,key->size(),(unsigned char *)key->data());
	    memset(iv,0,sizeof(iv));

	    /* Decrypt the data */
	    BF_cbc_encrypt(ebuf, ebuf,
			   data.length,
			   &bfkey, iv, 0);
	    
	    /* Calcuate the MD5 of the decrypted data */
	    MD5FromBuffer(ebuf,data.length,md5);

	    /* Convert the MD5 that we read from Base64 to binary */
	    unsigned char decoded_md5[64];
	    b64_pton_slg(data.md5->data(),
			 data.md5->length(),
			 decoded_md5,
			 sizeof(decoded_md5));

	    /* If they match, create the resultant */
	    if(!memcmp((char *)md5,(char *)decoded_md5,16)){
		res = new sstring;

		res->append((char *)ebuf,data.length);
	    }
	}
	if(ebuf) free(ebuf);
    }
    return res;				// not sure what we got
}


bool Encrypted_Object::is_encrypted_object(sstring *buf)
{
    /* Quick and dirty check to see if this is an encrypted object */
    return true;
}

sstring *Encrypted_Object::encrypt_object(sstring *buf,sstring *key)
{
    sstring *xml = new sstring;
    unsigned char *ebuf;				// encrypted buffer
    int ebuf_len;
    char *ebuf_base64;			// encrypted buffer, base64
    unsigned int  ebuf_base64_len;

    unsigned char md5[16];		// holds the md5
    char md5_base64[32];		// holds the md5, base 64
    
    BF_KEY bfkey;
    unsigned char iv[256];			// initialization vector

    /* Calculate the MD5 of the unencrypted string */
    MD5FromBuffer((unsigned char *)buf->data(), buf->size(), md5);
    memset(md5_base64,0,sizeof(md5_base64));
    b64_ntop(md5,16,md5_base64,sizeof(md5_base64));


    ebuf_len = (buf->size()+16) & 0xfffffff0;
    ebuf     = (unsigned char *)malloc(ebuf_len);
    if(ebuf==0) return 0;		// whoops.
    memcpy(ebuf,buf->data(),buf->size());

    /* Set up the key */
    BF_set_key(&bfkey,key->size(),(unsigned char *)key->data());
    memset(iv,0,sizeof(iv));


    /* Encrypt the data */
    BF_cbc_encrypt(ebuf, ebuf, buf->size(), &bfkey, iv, 1);

    ebuf_base64_len = buf->size()*2+16;
    ebuf_base64 = (char *)malloc(ebuf_base64_len);
    if(ebuf_base64==0){
	free(ebuf);
	return 0;
    }

    /* Compute the Base64 representation */
    b64_ntop(ebuf,ebuf_len,ebuf_base64,ebuf_base64_len);

    (*xml) = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" ENCRYPTED_OBJECT_DTD "\n";
    (*xml) += "<EncryptedObject>\n";
    (*xml) += "<edata>";
    (*xml) += ebuf_base64;
    (*xml) += "</edata>\n";

    char bytes[256];
    sprintf(bytes,"<length>%ld</length>\n",buf->size());
    (*xml) += bytes;

    sprintf(bytes,"<md5>%s</md5>\n",md5_base64);
    (*xml) += bytes;
    (*xml) += "</EncryptedObject>\n";

    return xml;
}
