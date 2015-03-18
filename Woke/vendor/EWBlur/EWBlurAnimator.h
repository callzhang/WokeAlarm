//
//  GPUBlurAnimator.h
//  WokeAlarm
//
//  Created by Lei Zhang on 9/28/13.
//  Copyright (c) 2013 Woke. All rights reserved.
//

#define kModelViewPresent       101
#define kModelViewDismiss       102
#define kInteractivePush		201
#define kInteractivePop			202

#define kGPUImageViewTag        201
#define kBackgroundImageTag     804


#import <Foundation/Foundation.h>

@class GPUImageDissolveBlendFilter;
@class GPUImagePicture;
@class GPUImagePixellateFilter;
@class GPUImageView;


@interface EWBlurAnimator : UIPercentDrivenInteractiveTransition<UIViewControllerAnimatedTransitioning,UIViewControllerInteractiveTransitioning>

@property (nonatomic) BOOL interactive;
@property (nonatomic) CGFloat progress;
@property (nonatomic) NSInteger type;
@property (nonatomic) BOOL isPresented;

- (void)finishTransition;
- (void)cancelInteractiveTransition;

@end
