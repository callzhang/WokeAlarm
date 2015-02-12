//
//  EWSleepManager.m
//  SleepManager
//  Manage the backgrounding. Currently only support backgrounding during sleep.
//  Will support sleep music and statistics later
//
//  Created by Lee on 8/6/14.
//  Copyright (c) 2014 Woke. All rights reserved.
//

#import "EWBackgroundingManager.h"
#import "EWSession.h"

OBJC_EXTERN void CLSLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

@interface EWBackgroundingManager(){
    NSTimer *backgroundingtimer;
    UIBackgroundTaskIdentifier backgroundTaskIdentifier;
    UILocalNotification *backgroundingFailNotification;
    BOOL BACKGROUNDING_FROM_START;
}
@property (nonatomic) AVPlayer *player;
@end

@implementation EWBackgroundingManager
@synthesize player;
+ (EWBackgroundingManager *)sharedInstance{
    static EWBackgroundingManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWBackgroundingManager alloc] init];
    });
    
    return manager;
}

- (id)init{
    self = [super init];
    if (self) {
        
        BACKGROUNDING_FROM_START = NO;
        
        
        //enter background
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        //enter foreground
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        //resign active
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        //become active
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didbecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        //terminate
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSDate *start = backgroundingtimer.userInfo[@"start"];
            [UIDevice currentDevice].batteryMonitoringEnabled = YES;
            NSString *words = [NSString stringWithFormat:@"Application will terminate after %.1f hours of running. Current battery level is %.1f%%", -start.timeIntervalSinceNow/3600, [UIDevice currentDevice].batteryLevel*100];
            DDLogError(words);
        }];
        //AvaudioSession
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionInterruptionNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            static BOOL wasBackgrounding;
            NSNumber *type = (NSNumber *)note.userInfo[AVAudioSessionInterruptionTypeKey];
            if (type.integerValue == AVAudioSessionInterruptionTypeEnded) {
                NSNumber *option = note.userInfo[AVAudioSessionInterruptionOptionKey];
                NSInteger optionValue = option.integerValue;
                if (optionValue == AVAudioSessionInterruptionOptionShouldResume) {
                    if (wasBackgrounding) {
                        if (self.isBackgrounding || BACKGROUNDING_FROM_START) {
                            [self startBackgrounding];
#ifdef DEBUG
                            UILocalNotification *n = [UILocalNotification new];
                            n.alertBody = @"Woke is active";
                            [[UIApplication sharedApplication] scheduleLocalNotification:n];
#endif
                        }
                        
                    }
                    
                }
            }
            else if (type.integerValue == AVAudioSessionInterruptionTypeBegan){
                if (self.isBackgrounding) {
                    wasBackgrounding = YES;
                }
                if (backgroundingFailNotification) {
                    [[UIApplication sharedApplication] cancelLocalNotification:backgroundingFailNotification];
                }
            }

        }];
		
        [self registerBackgroudingAudioSession];
    }
    
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

+ (BOOL)supportBackground{
    BOOL supported;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]){
        supported = [[UIDevice currentDevice] isMultitaskingSupported];
    }else {
        EWAlert(@"Your device doesn't support background task. Alarm will not fire. Please change your settings.");
        supported = NO;
    }
    return supported;
}

- (BOOL)isBackgrounding{
    return backgroundingFailNotification != nil;
}

#pragma mark - Application state change
- (void)enterBackground{
    if ([EWSession sharedSession].wakeupStatus == EWWakeUpStatusSleeping || self.isBackgrounding || BACKGROUNDING_FROM_START) {
        [self startBackgrounding];
    }
}

- (void)enterForeground{
	if (![EWSession sharedSession].wakeupStatus == EWWakeUpStatusWakingUp) {
		[self registerBackgroudingAudioSession];
	}
	
    [backgroundingtimer invalidate];
    
    [self endBackgrounding];

    
    for (UILocalNotification *note in [UIApplication sharedApplication].scheduledLocalNotifications) {
        if ([note.userInfo[kLocalNotificationTypeKey] isEqualToString:kLocalNotificationTypeReactivate]) {
            [[UIApplication sharedApplication] cancelLocalNotification:note];
        }
    }
}


- (void)willResignActive{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    //Timer will fail automatically
    //backgroundTask will stop automatically
    //notification needs to be cancelled (or delayed)
    
    if (backgroundingFailNotification) {
        [[UIApplication sharedApplication] cancelLocalNotification:backgroundingFailNotification];
    }
}

- (void)didbecomeActive{
    // This method is called to let your app know that it moved from the inactive to active state. This can occur because your app was launched by the user or the system.
    
    //resume backgrounding
    UIApplication *app = [UIApplication sharedApplication];
    if (app.applicationState != UIApplicationStateActive) {
        UILocalNotification *notif = [[UILocalNotification alloc] init];
        notif.alertBody = @"Woke become active!";
        [app scheduleLocalNotification:notif];
    }
}

#pragma mark - Backgrounding
- (void)startBackgrounding{
	if ([EWSession sharedSession].wakeupStatus != EWWakeUpStatusWakingUp) {
		[self registerBackgroudingAudioSession];
	}
    [self backgroundKeepAlive:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kBackgroundingStartNotice object:self];
    DDLogInfo(@"Start Backgrounding");
}

- (void)endBackgrounding{
    DDLogInfo(@"End Backgrounding");
    //self.sleeping = NO;
    
    UIApplication *application = [UIApplication sharedApplication];
    
    if (backgroundTaskIdentifier != UIBackgroundTaskInvalid){
        //end background task
        [application endBackgroundTask:backgroundTaskIdentifier];
    }
    //stop timer
    if ([backgroundingtimer isValid]){
        [backgroundingtimer invalidate];
    }
    
    //stop backgrounding fail notif
    if (backgroundingFailNotification) {
        [[UIApplication sharedApplication] cancelLocalNotification:backgroundingFailNotification];
    }else{
        for (UILocalNotification *n in [UIApplication sharedApplication].scheduledLocalNotifications) {
            if ([n.userInfo[kLocalNotificationTypeKey] isEqualToString:kLocalNotificationTypeReactivate]) {
                [[UIApplication sharedApplication] cancelLocalNotification:n];
            }
        }
    }
	[[NSNotificationCenter defaultCenter] postNotificationName:kBackgroundingEndNotice object:self];
}

#pragma mark Background worker
- (void)backgroundKeepAlive:(NSTimer *)timer{
	
	//start silent sound
	[self playSilentSound];
	
	UIApplication *application = [UIApplication sharedApplication];
	NSMutableDictionary *userInfo;
	if (timer) {
		NSInteger count;
		NSDate *start = timer.userInfo[@"start_date"];
		count = [(NSNumber *)timer.userInfo[@"count"] integerValue];
		DDLogInfo(@"Backgrounding started at %@ is checking the %ld times, backgrounding length: %.1f hours", start, (long)count, -[start timeIntervalSinceNow]/3600);
		count++;
		timer.userInfo[@"count"] = @(count);
		userInfo = timer.userInfo;
	}else{
		//first time
		userInfo = [NSMutableDictionary new];
		userInfo[@"start_date"] = [NSDate date];
		userInfo[@"count"] = @0;
	}
	
	//keep old background task
	UIBackgroundTaskIdentifier tempID = backgroundTaskIdentifier;
	//begin a new background task
	backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
		DDLogError(@"The backgound task ended!");
	}];
	//end old bg task
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[application endBackgroundTask:tempID];
	});
	
	//check time left
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		double timeLeft = application.backgroundTimeRemaining;
		DDLogInfo(@"Background time left: %.1f", timeLeft>999?999:timeLeft);
		
		//schedule timer
		if ([backgroundingtimer isValid]) [backgroundingtimer invalidate];
		NSInteger randomInterval = kAlarmTimerCheckInterval + arc4random_uniform(40);
		if(randomInterval > timeLeft) randomInterval = timeLeft - 10;
		backgroundingtimer = [NSTimer scheduledTimerWithTimeInterval:randomInterval target:self selector:@selector(backgroundKeepAlive:) userInfo:userInfo repeats:NO];
		DDLogVerbose(@"Scheduled background timer %ld", (long)randomInterval);
	});
	
	
	//alert user
	if (backgroundingFailNotification) {
		[[UIApplication sharedApplication] cancelLocalNotification:backgroundingFailNotification];
	}
#ifdef DEBUG
		backgroundingFailNotification= [[UILocalNotification alloc] init];
		backgroundingFailNotification.fireDate = [[NSDate date] dateByAddingTimeInterval:200];
		backgroundingFailNotification.alertBody = @"Woke stopped running. Tap here to reactivate it.";
		backgroundingFailNotification.alertAction = @"Activate";
		backgroundingFailNotification.userInfo = @{kLocalNotificationTypeKey: kLocalNotificationTypeReactivate};
		backgroundingFailNotification.soundName = backgroundingFailureSound;
		[[UIApplication sharedApplication] scheduleLocalNotification:backgroundingFailNotification];
#endif
}

- (void)playSilentSound{
#if !TARGET_IPHONE_SIMULATOR
    //set up player
    NSArray *soundArray = [backgroundingSound componentsSeparatedByString:@"."];
    NSURL *path = [[NSBundle mainBundle] URLForResource:soundArray.firstObject withExtension:soundArray.lastObject];
    player = [AVPlayer playerWithURL:path];
    [player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    player.volume = 0.1;
	[player play];
    
    if (player.status == AVPlayerStatusFailed) {
        DDLogVerbose(@"!!! AV player not ready to play.");
    }else{
        DDLogVerbose(@"Play silent sound");
    }
#endif
}


//register the BACKGROUNDING audio session
- (void)registerBackgroudingAudioSession{
	//[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
	NSError *error = nil;
	//set category
	BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback
													withOptions: AVAudioSessionCategoryOptionMixWithOthers
														  error:&error];
	if (!success) DDLogVerbose(@"AVAudioSession error setting category:%@",error);
	[self playSilentSound];
}

@end
