//
//  EWMenuViewController.h
//  Woke
//
//  Created by Zitao Xiong on 21/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^MenuBackgroundTapHanlder)(void);
@interface EWMenuViewController : UIViewController


@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (nonatomic, copy) MenuBackgroundTapHanlder tapHandler;

- (void)collapseMenuWithComletion:(void (^)(void))completion;
@end
