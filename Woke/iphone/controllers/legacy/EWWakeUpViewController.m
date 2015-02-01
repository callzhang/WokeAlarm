//
//  WakeUpViewController.m
//  EarlyWorm
//
//  Created by Lei Zhang on 7/28/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWWakeUpViewController.h"
#import "EWWakeUpManager.h"
#import "EWUIUtil.h"
#import "UIView+Layout.h"
#import "EWWakeUpViewCell.h"
#import "EWAVManager.h"
#import "EWMedia.h"
#import "EWMediaFile.h"

#define cellIdentifier                  @"EWWakeUpViewCell"


@interface EWWakeUpViewController (){
    CGRect headerFrame;
    NSTimer *timeTimer;
    NSTimer *progressTimer;
}
@end



@implementation EWWakeUpViewController
//@synthesize tableView = _tableView;
//@synthesize timer, header, footer;
//@synthesize person = _person;


#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //origin header frame
    //headerFrame = header.frame;
    
    //HUD
    //[self.view showLoopingWithTimeout:0];
    
    //Refresh for new media
    [[NSNotificationCenter defaultCenter] addObserverForName:kNewMediaNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if ([EWSession sharedSession].wakeupStatus == EWWakeUpStatusWakingUp) {
            [self.tableView reloadData];
        }
    }];
    //update view when new media starts playing
    [[NSNotificationCenter defaultCenter] addObserverForName:kAVManagerDidStartPlaying object:nil queue:nil usingBlock:^(NSNotification *note) {
        //nothing
    }];
    
    //responder to remote control
    [self prepareRemoteControlEventsListener];
    
    [EWUIUtil dismissHUDinView:self.view];
    
    //register cell
    [self.tableView registerClass:[EWWakeUpViewCell class] forCellReuseIdentifier:cellIdentifier];
    
    //start playing
    [self updatePlayingCellAndProgress];
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //nav button
    self.navigationItem.leftBarButtonItem = [self.mainNavigationController menuBarButtonItem];
    //add background
    UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"woke-background"]];
    background.frame = self.view.frame;
    [self.view insertSubview:background atIndex:0];
    //[self initView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //timer updates
    //timeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
    progressTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(updatePlayingCellAndProgress) userInfo:nil repeats:YES];
    //[self updateTimer];
    
    //position the content
    [self scrollViewDidScroll:self.tableView];
    
    //alpha mask
    [EWUIUtil applyAlphaGradientForView:self.tableView withEndPoints:@[@0.2f, @0.9f]];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    //remove AVManager state
    [[EWWakeUpManager sharedInstance] stopPlayingVoice];
    
    [self resignRemoteControlEventsListener];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAVManagerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewMediaNotification object:nil];
    
    //[timeTimer invalidate];
    [progressTimer invalidate];
    NSLog(@"WakeUpViewController popped out of view: remote control event listner stopped. Observers removed.");
}

//- (void)initView {
//    
//    header.layer.cornerRadius = 10;
//    header.layer.masksToBounds = YES;
//    header.layer.borderWidth = 1;
//    header.layer.borderColor = [UIColor whiteColor].CGColor;
//    header.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
//    
//    timer.text = _activity.time.date2timeShort;
//    self.AM.text = _activity.time.date2am;
//    
//    //table view
//    //tableView_.frame = CGRectMake(0, 150, self.view.frame.size.width, self.view.frame.size.height-230);
//    _tableView.dataSource = self;
//    _tableView.delegate = self;
//    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    _tableView.contentInset = UIEdgeInsetsMake(40, 0, 80, 0);//the distance of the content to the frame of tableview
//    
//    //load MediaViewCell
//    UINib *nib = [UINib nibWithNibName:@"EWMediaViewCell" bundle:nil];
//    //register the nib
//    [_tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
//    
//    //alpha mask
//    [EWUIUtil applyAlphaGradientForView:_tableView withEndPoints:@[@0.2f, @0.9f]];
//    
//    //show button first
//    footer.top = [UIScreen mainScreen].bounds.size.height;
//    [self.wakeupButton setTitle:@"Shake To Wake Up!" forState:UIControlStateNormal];
//    BOOL skipShake = NO;
//#ifdef DEBUG
//    skipShake = YES;
//#endif
//    if ([self.shakeProgress isShakeSupported] && !skipShake) {
//        [self presentShakeProgressBar];
//    }else{
//        [_wakeupButton setTitle:@"Wake up!" forState:UIControlStateNormal];
//        _shakeProgress.alpha = 0;
//        [self.wakeupButton addTarget:self action:@selector(presentPostWakeUpVC) forControlEvents:UIControlEventTouchUpInside];
//    }
//}

//- (void)presentShakeProgressBar{
//    self.shakeProgress.progress = 0;
//    //[_wakeupButton removeTarget:self action:@selector(presentShakeProgressBar) forControlEvents:UIControlEventTouchUpInside];
//    
//    //[_wakeupButton setTitle:@"" forState:UIControlStateNormal];
//    [UIView animateWithDuration:0.5 animations:^{
//        //show bar
//        _shakeProgress.alpha = 1;
//    } completion:^(BOOL finished) {
//        //start motion detect
//        [_shakeProgress startUpdateProgressBarWithProgressingHandler:^{
//            
//        } CompleteHandler:^{
//            
//            //show
//            [UIView animateWithDuration:0.5 animations:^{
//                _shakeProgress.alpha = 0;
//            } completion:^(BOOL success) {
//                
//                [_wakeupButton setTitle:@"Wake up!" forState:UIControlStateNormal];
//                [_wakeupButton addTarget:self action:@selector(presentPostWakeUpVC) forControlEvents:UIControlEventTouchUpInside];
//            }];
//        }];
//    }];
//}

#pragma mark - UI
//- (void)OnCancel{
//    [self.navigationController dismissBlurViewControllerWithCompletionHandler:^{
//        [[EWWakeUpManager sharedInstance] stopPlayingVoice];
//    }];
//}

- (void)highlightCellAtIndex:(NSUInteger)n{
    NSIndexPath *path = [NSIndexPath indexPathForRow:n inSection:0];
    [self.tableView selectRowAtIndexPath:path animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView deselectRowAtIndexPath:path animated:YES];
    });
    
    //[EWWakeUpManager sharedInstance].continuePlay = NO;
}

-(void)done {
    [self.view showLoopingWithTimeout:0];
    
    //stop music
    [[EWWakeUpManager sharedInstance] stopPlayingVoice];
    [EWWakeUpManager sharedInstance].continuePlay = NO;
    
//    EWPostWakeUpViewController * postWakeUpVC = [[EWPostWakeUpViewController alloc] initWithNibName:nil bundle:nil];
//    postWakeUpVC.activity = _activity;
//    
//    [self presentViewControllerWithBlurBackground:postWakeUpVC];
    [EWUIUtil dismissHUDinView:self.view];
}

#pragma mark - tableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [EWWakeUpManager sharedInstance].medias.count;
}


#pragma mark - Table view
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

//Asks the data source for a cell to insert in a particular location of the table view. (required)
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    //Use reusable cell or create a new cell
    EWWakeUpViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    //get media item
    EWMedia *mi;
    if (indexPath.row >= (NSInteger)[EWWakeUpManager sharedInstance].medias.count) {
        DDLogError(@"@@@ WakupView asking for deleted media");
        mi = nil;
    }else{
        mi = [[EWWakeUpManager sharedInstance].medias objectAtIndex:indexPath.row];
    }
    
    //media -> set type and UI
    cell.media = mi;
    
    return cell;
}


//remove item
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.view showLoopingWithTimeout:0];
    [self scrollViewDidScroll:tableView];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        EWMedia *currentMedia = [EWWakeUpManager sharedInstance].medias[indexPath.row];
        
        [currentMedia remove];
        
        //stop play if media is being played
        if ([EWWakeUpManager sharedInstance].currentMediaIndex == (NSUInteger)indexPath.row) {
            //media is being played
            NSLog(@"Deleting current cell, play next");
            if ([tableView numberOfRowsInSection:0] > 1) {
                [[EWWakeUpManager sharedInstance] playNextVoice];
            }
        }
        
        //remove from view with animation
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [currentMedia save];
        
        //update UI
        [self scrollViewDidScroll:self.tableView];
        [self.tableView reloadData];
        
    }
    if (editingStyle==UITableViewCellEditingStyleInsert) {
        //do something
    }
}

//when click one item in table, push view to detail page
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [[EWWakeUpManager sharedInstance] playMediaAtIndex:indexPath.row];
    
    [self highlightCellAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"Avoid";
}

- (NSString *)tableView:(UITableView *)tableView titleForSwipeAccessoryButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Like";
}

- (void)tableView:(UITableView *)tableView swipeAccessoryButtonPushedForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.view showSuccessNotification:@"Liked"];
    
    // Hide the More/Delete menu.
    [self setEditing:NO animated:YES];
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{

//    
//    if (!footer) {
//        
//        return;
//        
//    }
//    
//    //footer
//    CGRect footerFrame = footer.frame;
//    if (scrollView.contentSize.height < 1) {
//        //init phrase
//        footerFrame.origin.y = self.view.frame.size.height - footerFrame.size.height;
//    }else{
//        CGPoint bottomPoint = [self.view convertPoint:CGPointMake(0, scrollView.contentSize.height) fromView:scrollView];
//        //NSInteger footerOffset = scrollView.contentSize.height + scrollView.contentInset.top - (scrollView.contentOffset.y + scrollView.frame.size.height);
//        footerFrame.origin.y = MAX(bottomPoint.y, self.view.frame.size.height - footerFrame.size.height) ;
//    }
//    
//    footer.frame = footerFrame;
    
}


#pragma mark - Update player events

/**
 *  Update the highlighted cell when playing
 */
- (void)updatePlayingCellAndProgress{
    //check active cell, switch if changed
    static NSUInteger currentPlayingCellIndex = 0;
    NSUInteger currentMediaIndex = [EWWakeUpManager sharedInstance].currentMediaIndex;
    
    
    if (currentMediaIndex != currentPlayingCellIndex) {
        //highlight
        [self highlightCellAtIndex:currentMediaIndex];
        //reset UI
        NSIndexPath *path = [NSIndexPath indexPathForRow:currentPlayingCellIndex inSection:0];
        EWWakeUpViewCell *cell = (EWWakeUpViewCell *)[self.tableView cellForRowAtIndexPath:path];
        cell.progress.progress = 0;
        currentPlayingCellIndex = currentMediaIndex;
    }
    
    //update the progress
    NSIndexPath *path = [NSIndexPath indexPathForRow:currentMediaIndex inSection:0];
    EWWakeUpViewCell *cell = (EWWakeUpViewCell *)[self.tableView cellForRowAtIndexPath:path];
    cell.progress.progress = [EWAVManager sharedManager].playingProgress;
}


#pragma mark - Remote Control Event
- (void)prepareRemoteControlEventsListener{
    
    //register for remote control
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    // Set itself as the first responder
    BOOL success = [self becomeFirstResponder];
    if (success) {
        DDLogInfo(@"APP degelgated %@ remote control events", [self class]);
    }else{
        DDLogWarn(@"@@@ %@ failed to listen remote control events @@@", self.class);
    }
}

- (void)resignRemoteControlEventsListener{
    
    // Turn off remote control event delivery
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    // Resign as first responder
    BOOL sucess = [self resignFirstResponder];
    
    if (sucess) {
        DDLogInfo(@"%@ resigned as first responder", self.class);
        
    }else{
        DDLogWarn(@"%@ failed to resign first responder", self.class);
    }
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        EWAVManager *manager = [EWAVManager sharedManager];
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlPlay:{
                DDLogVerbose(@"Received remote control: play");
                if (![manager.player play]) {
                    [manager playMedia:manager.media];
                }
            }
                
                break;
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                DDLogVerbose(@"Received remote control: Previous");
                [[EWWakeUpManager sharedInstance] playNextVoice];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                DDLogVerbose(@"Received remote control: Next");
                [[EWWakeUpManager sharedInstance] playNextVoice];
                break;
                
            case UIEventSubtypeRemoteControlStop:
                DDLogVerbose(@"Received remote control Stop");
                [manager stopAllPlaying];
                break;
                
            case UIEventSubtypeRemoteControlPause:{
                DDLogVerbose(@"Received remote control pause");
                if (manager.player.isPlaying) {
                    EWMedia *m0 = manager.media;
                    [manager.player pause];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (m0 == manager.media && !manager.player.isPlaying) {
                            //continue play
                            [manager.player play];
                        }
                    });
                } else {
                    [manager.player play];
                }
            }
                break;
                
            default:
                DDLogVerbose(@"Received remote control %ld", (long)receivedEvent.subtype);
                break;
        }
    }
}

/*
#pragma mark - Timer update
- (void)updateTimer{
    NSDate *t = [NSDate date];
    NSString *ts = [t date2timeShort];
    self.timer.text = ts;
    NSTimeInterval time = [t timeIntervalSinceDate:self.activity.time];
    
    if (time < 0) {
        time = 0;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"ss"];
    NSString *string = [formatter stringFromDate:t];
    self.seconds.text = [NSString stringWithFormat:@"%@\"", string];
    timePast++;
    self.timeDescription.text = [NSString stringWithFormat:@"%ld minutes past", (unsigned long)time/60];
    
    self.AM.text = [t date2am];
}
*/

- (IBAction)finish:(id)sender {
}
@end




