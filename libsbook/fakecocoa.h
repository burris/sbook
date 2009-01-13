#ifndef FAKECOCOA_H
#define FAKECOCOA_H

typedef struct _NSPoint {
    float x;
    float y;
} NSPoint;
typedef NSPoint *NSPointPointer;
typedef NSPoint *NSPointArray;
typedef struct _NSSize {
    float width;		/* should never be negative */
    float height;		/* should never be negative */
} NSSize;

typedef NSSize *NSSizePointer;
typedef NSSize *NSSizeArray;

typedef struct _NSRect {
    NSPoint origin;
    NSSize size;
} NSRect;

typedef NSRect *NSRectPointer;
typedef NSRect *NSRectArray;

NSPoint NSMakePoint(float x, float y);
NSSize  NSMakeSize(float w, float h);
NSRect  NSMakeRect(float x, float y, float w, float h);


#endif
