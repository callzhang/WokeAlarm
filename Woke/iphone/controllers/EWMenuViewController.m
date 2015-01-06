//
//  EWMenuViewController.m
//  Woke
//
//  Created by Zitao Xiong on 21/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWMenuViewController.h"
#import <pop/pop.h>
#import "EWAccountManager.h"
#import "EWAlarmViewController.h"

#define kTopOriginDefaultConstraint 20
#define kHomeOriginDefaultConstraint 66
#define kMenuDefaultStepperConstraint 54
#define kFromOriginStepper 30

@interface EWMenuViewController ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *homeTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *notificationTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *alarmTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *voiceTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *meTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *settingsTopLayoutConstraint;

@property (weak, nonatomic) IBOutlet UIButton *home;
@property (weak, nonatomic) IBOutlet UIButton *notification;
@property (weak, nonatomic) IBOutlet UIButton *alarm;
@property (weak, nonatomic) IBOutlet UIButton *voice;
@property (weak, nonatomic) IBOutlet UIButton *me;
@property (weak, nonatomic) IBOutlet UIButton *settings;
@end

@implementation EWMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)];
    [self.view addGestureRecognizer:tap];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self showMenu];
}

#pragma mark - Segue actions
- (IBAction)onAlarms:(id)sender {
    [self.mainNavigationController toogleMenuCompletion:^{
//        [self performSegueWithIdentifier:@"MenuToAlarmReplace" sender:self];
    }];
}

- (IBAction)onHome:(id)sender {
    [self.mainNavigationController toogleMenuCompletion:^{
//        [self performSegueWithIdentifier:@"MenuToHomeReplace" sender:self];
    }];
}
- (IBAction)onVoice:(id)sender {
    [self.mainNavigationController toogleMenuCompletion:^{
//        [self performSegueWithIdentifier:@"MenuToVoiceReplace" sender:self];
        
    }];
}
#pragma mark -
- (void)onTap {
    if (self.tapHandler) {
        self.tapHandler();
    }
}

- (void)showMenu {
    self.backgroundView.alpha = 0.0f;
    POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.fromValue = @(0.0);
    anim.toValue = @(1.0);
    [self.backgroundView pop_addAnimation:anim forKey:@"backgroundFade"];
    
    [self addAnimationToConstraint:self.homeTopLayoutConstraint index:0 forKey:@"homtTop" speed:10.f bounciness:14.f delay:0.03];
    [self addAnimationToConstraint:self.notificationTopLayoutConstraint index:1 forKey:@"notificationTop" speed:15.0f bounciness:14.0f delay:0.03];
    [self addAnimationToConstraint:self.alarmTopLayoutConstraint index:2 forKey:@"alarmTop" speed:20.0f bounciness:14.0f delay:0.03];
    [self addAnimationToConstraint:self.voiceTopLayoutConstraint index:3 forKey:@"voiceTop" speed:25.0f bounciness:14.0f delay:0.03];
    [self addAnimationToConstraint:self.meTopLayoutConstraint index:4 forKey:@"meTop" speed:30.0f bounciness:14.0f delay:0.03];
    [self addAnimationToConstraint:self.settingsTopLayoutConstraint index:5 forKey:@"settignsTop" speed:35.0f bounciness:14.0f delay:0.03];
    
    [self addFadeInAnimationToView:self.home forKey:@"home FadeIn"];
    [self addFadeInAnimationToView:self.notification forKey:@"notification FadeIn"];
    [self addFadeInAnimationToView:self.alarm forKey:@"alarm FadeIn"];
    [self addFadeInAnimationToView:self.voice forKey:@"voice FadeIn"];
    [self addFadeInAnimationToView:self.me forKey:@"me FadeIn"];
    [self addFadeInAnimationToView:self.settings forKey:@"settings FadeIn"];
}

- (void)closeMenu {
    [self addBackAnimationToConstraint:self.homeTopLayoutConstraint index:0 forKey:@"home back"];
    [self addBackAnimationToConstraint:self.notificationTopLayoutConstraint index:1 forKey:@"notification back"];
    [self addBackAnimationToConstraint:self.alarmTopLayoutConstraint index:2 forKey:@"alarm back"];
    [self addBackAnimationToConstraint:self.voiceTopLayoutConstraint index:3 forKey:@"voice back"];
    [self addBackAnimationToConstraint:self.meTopLayoutConstraint index:4 forKey:@"me back"];
    [self addBackAnimationToConstraint:self.settingsTopLayoutConstraint index:5 forKey:@"setting back"];
    
    [self addBackFadeoutToView:self.home forKey:@"home fade"];
    [self addBackFadeoutToView:self.notification forKey:@"notification fade"];
    [self addBackFadeoutToView:self.alarm forKey:@"alarm fade"];
    [self addBackFadeoutToView:self.voice forKey:@"voice fade"];
    [self addBackFadeoutToView:self.me forKey:@"me fade"];
    [self addBackFadeoutToView:self.settings forKey:@"settings fade"];
}

#pragma mark - Animation Helper
- (void)addFadeInAnimationToView:(UIView *)view forKey:(NSString *)key{
    POPBasicAnimation *fadeIn = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
    fadeIn.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    fadeIn.fromValue = @(0.0);
    fadeIn.toValue = @(1.0);
    
    [view pop_addAnimation:fadeIn forKey:key];
}

- (void)addAnimationToConstraint:(NSLayoutConstraint *)constraint index:(NSUInteger)index forKey:(NSString *)key speed:(CGFloat)speed bounciness:(CGFloat)bounciness delay:(CGFloat)delay{
    POPSpringAnimation *notificationAnim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    notificationAnim.springSpeed = speed;
    notificationAnim.springBounciness = 7.0f;
//    notificationAnim.beginTime = CACurrentMediaTime() + delay;
    notificationAnim.fromValue = @(kTopOriginDefaultConstraint + kFromOriginStepper * index);
    notificationAnim.toValue = @(kHomeOriginDefaultConstraint + kMenuDefaultStepperConstraint * index);
    constraint.constant = [notificationAnim.fromValue floatValue];
    [constraint pop_addAnimation:notificationAnim forKey:key];
}

- (void)addBackAnimationToConstraint:(NSLayoutConstraint *)constraint index:(NSUInteger)index forKey:(NSString *)key{
    POPSpringAnimation *notificationAnim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    notificationAnim.springSpeed = 15.0f;
    notificationAnim.springBounciness = 0.0f;
//    notificationAnim.beginTime = CACurrentMediaTime() + 0.03;
    notificationAnim.toValue = @(kTopOriginDefaultConstraint);
    notificationAnim.fromValue = @(kHomeOriginDefaultConstraint + kMenuDefaultStepperConstraint * index);
    constraint.constant = [notificationAnim.fromValue floatValue];
    [constraint pop_addAnimation:notificationAnim forKey:key];
}

- (void)addBackFadeoutToView:(UIView *)view forKey:(NSString *)key{
    POPBasicAnimation *fadeOut = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
    fadeOut.fromValue = @(1.0);
    fadeOut.toValue = @(0.0);
    fadeOut.duration = 0.2f;
    [view pop_addAnimation:fadeOut forKey:key];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MenuLogoutFadeToLoginGate"]) {
        [[EWAccountManager shared] logout];
    }
}
@end
