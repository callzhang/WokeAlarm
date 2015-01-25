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
@property (nonatomic, strong) id didPlayNextObserver;

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
    
    self.profileImageView.image = [self currentMedia].author.profilePic;
    
    self.didPlayNextObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kEWWakeUpDidPlayNextMediaNotification
                                                                                 object:nil queue:nil usingBlock:^(NSNotification *note) {
                                                                                   @strongify(self);
                                                                                     self.profileImageView.image = [self currentMedia].author.profilePic;
                                                                                 }];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[EWWakeUpManager sharedInstance] playNextVoice];
}

- (NSArray *)medias {
    return [EWWakeUpManager sharedInstance].medias;
}

- (EWMedia *)currentMedia {
    return [EWWakeUpManager sharedInstance].currentMedia;
}
@end
