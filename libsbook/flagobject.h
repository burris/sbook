#ifndef FLAG_OBJECT_H
#define FLAG_OBJECT_H

class FlagObject {
public:
    FlagObject() {flags = 0;}
    unsigned long flags;
    void setFlags(int x) { flags = x;}
    int  getFlags() { return flags;}
    void setFlag(unsigned long mask,bool aValue) { flags = (flags & ~mask) | (aValue ? mask : 0);}
    void addFlag(unsigned long aFlag) {flags |= aFlag;}
    void removeFlag(unsigned long aFlag) { flags &= ~aFlag; }
    bool queryFlag(unsigned long mask) {return (flags & mask) ? true : false;}
};


#endif
