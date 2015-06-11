//
//  EWVoiceSectionHeaderRowItem.h
//  Woke
//
//  Created by Zitao Xiong on 6/8/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "TMRowItem.h"

@interface EWVoiceSectionHeaderRowItem : TMRowItem
- (void)removeRelatedRowItem:(TMRowItem *)rowItem;
- (void)addRelatedRowItem:(TMRowItem *)rowItem;
@end
