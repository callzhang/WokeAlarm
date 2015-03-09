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
#import "EWWakeupChildViewModel.h"
#import "EWAVManager.h"
#import "FBTweakInline.h"

FBTweakAction(@"Sleeping VC", @"Wakeup Child VC", @"Stop Wave", ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ew.stopwave" object:nil];
});

@interface EWWakeUpChildViewController () {
    CADisplayLink *displayLink;
}
@property (nonatomic, strong) EWTimeChildViewController *smallTimeChildViewController;
@property (nonatomic, strong) RACDisposable *timerDisposable;

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet SCSiriWaveformView *waveView;
@property (nonatomic, strong) id didPlayNextObserver;
@property (nonatomic, strong) EWWakeupChildViewModel *model;

@end

@implementation EWWakeUpChildViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    self.model = [[EWWakeupChildViewModel alloc] init]; //init here, EWWakeupChildViewModel do not need params.
    
    self.smallTimeChildViewController.type = EWTimeChildViewControllerTypeSmall;
    @weakify(self);
    self.timerDisposable = [[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSDate *date) {
        @strongify(self);
        self.smallTimeChildViewController.date = date;
    }];
    
    [RACObserve(self, model.currentMedia) subscribeNext:^(EWMedia *currentMedia) {
       @strongify(self);
        self.profileImageView.image = self.model.currentMedia.author.profilePic;
        self.nameLabel.text = self.model.currentMedia.author.name;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWave) name:@"ew.stopwave" object:nil];
//    self.didPlayNextObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kEWWakeUpDidPlayNextMediaNotification
//                                                                                 object:nil queue:nil usingBlock:^(NSNotification *note) {
//                                                                                   @strongify(self);
//                                                                                     self.profileImageView.image = [self currentMedia].author.profilePic;
//                                                                                 }];
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress:)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    displayLink.paused = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)setActive:(BOOL)active {
    _active = active;
    if (active) {
        displayLink.paused = NO;
    }
    else {
        [[EWWakeUpManager sharedInstance] stopPlayingVoice];
        displayLink.paused = YES;
    }
}

#pragma mark - Wave
#pragma mark - Update progress
- (void)updateProgress:(CADisplayLink *)link {
    CGFloat progress = 0.0;
    if([EWAVManager sharedManager].player.isPlaying) {
        progress = (CGFloat) [EWAVManager sharedManager].player.currentTime /kMaxRecordTime;
        //set prpgress
        if (progress<1) {
            [self updateMeters];
        }
    }
}

- (void)updateMeters{
    [[EWAVManager sharedManager].recorder updateMeters];
    CGFloat normalizedValue = (float)pow (10, [[EWAVManager sharedManager].recorder averagePowerForChannel:0]/30);
    [self.waveView updateWithLevel:normalizedValue];
}

- (void)stopWave {
    self.active = NO;
    [self.waveView updateWithLevel:0.0];
}
@end
