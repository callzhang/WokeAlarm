//
//  EWMenuViewController.h
//  Woke
//
//  Created by Zitao Xiong on 21/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EWMenuViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *backgroundView;

- (void)collapseMenuWithComletion:(void (^)(void))completion;
@end
