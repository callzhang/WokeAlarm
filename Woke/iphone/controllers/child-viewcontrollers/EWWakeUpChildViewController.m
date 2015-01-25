//
//  EWWakeUpChildViewController.m
//  Woke
//
//  Created by Zitao Xiong on 1/12/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWWakeUpChildViewController.h"
#import "EWTimeChildViewController.h"
#import "SCSiriWaveformView.h"
#import "EWMedia.h"
#import "EWPerson+Woke.h"
#import "EWWakeUpManager.h"

@interface EWWakeUpChildViewController ()
@property (nonatomic, strong) EWTimeChildViewController *smallTimeChildViewController;
@property (nonatomic, strong) RACDisposable *timerDisposable;

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet SCSiriWaveformView *waveView;

@end

@implementation EWWakeUpChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    self.smallTimeChildViewController.type = EWTimeChildViewControllerTypeSmall;
    @weakify(self);
    self.timerDisposable = [[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSDate *date) {
        @strongify(self);
        self.smallTimeChildViewController.date = date;
    }];
}

- (void)startPlayMedia {
    EWMedia *media = self.medias.firstObject;
    self.profileImageView.image = media.author.profilePic;
}

- (NSArray *)medias {
    return [EWWakeUpManager sharedInstance].medias;
}
@end
