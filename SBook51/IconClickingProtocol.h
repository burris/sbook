/*
 *  IconClickingProtocol.h
 *  SBook5
 *
 *  Created by Simson Garfinkel on Tue Dec 30 2003.
 *  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
 *
 */

@class SLC,Person;
@protocol IconClickingProtocol
- (void)mouseClicked:(NSEvent *)anEvent
  icon:(int)icon slc:(SLC *)slc person:(Person *)person line:(int)line;
@end

// Local Variables:
// mode:ObjC
// End:
