//
//  EWMessage.m
//  EarlyWorm
//
//  Created by Lei on 10/11/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWMessage.h"
@class EWPerson;


@implementation EWMessage
- (EWPerson *)ownerObject{
    return self.sender;
}
@end
