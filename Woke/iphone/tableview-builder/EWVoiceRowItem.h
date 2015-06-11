//
//  EWSentVoiceRowItem.h
//  Woke
//
//  Created by Zitao Xiong on 6/8/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "TMRowItem.h"

@interface EWVoiceRowItem : TMRowItem
@property (nonatomic, strong) EWMedia *media;
@property (nonatomic, copy) void (^onDeleteRowHandler)(EWVoiceRowItem *rowItem);
@end
