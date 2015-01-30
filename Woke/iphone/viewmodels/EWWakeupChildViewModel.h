//
//  EWWakeupChildViewModel.h
//  Woke
//
//  Created by Zitao Xiong on 1/25/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReactiveViewModel.h"

@class EWMedia;
@interface EWWakeupChildViewModel : RVMViewModel
@property (nonatomic, strong) NSArray *medias;
@property (nonatomic, strong) EWMedia *currentMedia;
@end
