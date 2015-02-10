//
//  MSFadeSegue.m
//  MakeSpace
//
//  Created by Zitao Xiong on 09/09/2014.
//  Copyright (c) 2014 Nanaimostudio. All rights reserved.
//

#import "MSPushFadeSegue.h"
#import "UIViewController+Blur.h"

@implementation MSPushFadeSegue
- (void)perform {
    CATransition* transition = [CATransition animation];
    
    transition.duration = 0.3;
    transition.type = kCATransitionFade;
    
    [[self.sourceViewController navigationController].view.layer addAnimation:transition forKey:kCATransition];
    [[self.sourceViewController navigationController] pushViewController:[self destinationViewController] animated:NO];
}
@end
