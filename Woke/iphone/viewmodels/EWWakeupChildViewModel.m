//
//  EWWakeupChildViewModel.m
//  Woke
//
//  Created by Zitao Xiong on 1/25/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWWakeupChildViewModel.h"
#import "EWWakeUpManager.h"

@implementation EWWakeupChildViewModel
- (instancetype)init {
    self = [super init];
    if (self) {
        @weakify(self);
        [RACObserve([EWWakeUpManager sharedInstance], currentMediaIndex) subscribeNext:^(NSNumber *number) {
            @strongify(self);
            self.medias = [EWWakeUpManager sharedInstance].medias;
            self.currentMedia = [EWWakeUpManager sharedInstance].currentMedia;
        }];
    }
    return self;
}
@end
