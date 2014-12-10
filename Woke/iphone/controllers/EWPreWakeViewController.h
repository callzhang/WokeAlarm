//
//  EWPreWakeViewController.h
//  Woke
//
//  Created by Lee on 12/9/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWBaseViewController.h"
@class EWMedia;

@interface EWPreWakeViewController : EWBaseViewController
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
- (IBAction)wakeUp:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (nonatomic, strong) NSArray *medias;
@property (nonatomic, strong) EWMedia *currentMedia;
@end
