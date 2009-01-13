#ifndef ENCRYPTED_OBJECT_H
#define ENCRYPTED_OBJECT_H

#include <string>
#include <map>
#include <vector>
#include <list>
#include "fakecocoa.h"

/*
 * Encrypted_Object.h:
 * The precise information that is saved in the SBookXML file.
 */

#define ENCRYPTED_OBJECT_DTD "<!DOCTYPE entries PUBLIC \"-//Simson L. Garfinkel// DTD SBook5 //EN//XML\" \"http://www.simson.net/sbook/1.0/EncryptedObject.dtd\">"

class Encrypted_Object  {
public:
    static bool is_encrypted_object(sstring *buf);

    /* Both of these methods allocate new sstring objects
     * that must be deleted.
     */

    static sstring *decrypt_object(sstring *buf,sstring *key);
    static sstring *encrypt_object(sstring *buf,sstring *key);
};

#endif
