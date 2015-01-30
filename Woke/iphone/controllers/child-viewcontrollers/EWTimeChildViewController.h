//
//  EWTimeChildViewController.h
//  Woke
//
//  Created by Zitao Xiong on 1/11/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, EWTimeChildViewControllerType) {
    EWTimeChildViewControllerTypeNormal,
    EWTimeChildViewControllerTypeSmall,
};

@interface EWTimeChildViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *topLabelLine1;
@property (weak, nonatomic) IBOutlet UILabel *topLabelLine2;
@property (nonatomic, assign) EWTimeChildViewControllerType type;
@property (nonatomic, strong) NSDate *date;
@end
