//
//  WakeUpViewController.m
//  EarlyWorm
//
//  Created by Lei Zhang on 7/28/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWWakeUpViewController.h"
#import "EWMediaCell.h"
#import "EWMediaManager.h"
#import "EWMedia.h"
#import "EWAVManager.h"
#import "EWMediaSlider.h"
#import "EWWakeUpManager.h"
#import "EWPostWakeUpViewController.h"
#import "EWBackgroundingManager.h"
#import "EWUIUtil.h"
#import "EWActivity.h"
#import "UIView+Layout.h"
#import "UIViewController+Blur.h"
#import "FBKVOController.h"

#define cellIdentifier                  @"EWMediaViewCell"


@interface EWWakeUpViewController (){
    
    NSMutableArray *medias;
    CGRect headerFrame;
    NSTimer *timerTimer;
    NSUInteger timePast;
}
@end



@implementation EWWakeUpViewController
@synthesize tableView = _tableView;
@synthesize timer, header;
@synthesize person;
@synthesize footer;


- (EWWakeUpViewController *)init{
    self = [self initWithNibName:nil bundle:nil];
    
    //DATA
    [self initData];
    
    return self;
}


- (void)dealloc {
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kAudioPlayerDidFinishPlaying object:nil];
        [self.activity removeObserver:self forKeyPath:@"medias"];
    }
    @catch (NSException *exception) {
        DDLogError(@"error in deallocating WakeUpViewController: %@", exception.description);
    }
    
    DDLogVerbose(@"WakeUpViewController deallocated. Observers removed.");
}


//- (void)refresh{
//    [self initData];
//    [_tableView reloadData];
//    [self startPlayCells];
//}



#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //origin header frame
    headerFrame = header.frame;
    
    //HUD
    [self.view showLoopingWithTimeout:0];
    
    //[self initData];
    [self initView];
    
    [EWUIUtil dismissHUDinView:self.view];
    
    //start playing
    [self startPlayCells];
    
}


- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //timer updates
    timerTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
    [self updateTimer];
    
    //position the content
    [self scrollViewDidScroll:_tableView];
    [self.view setNeedsDisplay];
    
    //pre download everyone for postWakeUpVC
    [[EWPersonManager sharedInstance] getWakeesInBackgroundWithCompletion:NULL];
    
    //send currently played cell info to EWAVManager
    //[[EWWakeUpManager sharedInstance] playNext];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [self resignRemoteControlEventsListener];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAudioPlayerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewMediaNotification object:nil];
    [_activity removeObserver:self forKeyPath:@"medias"];
    
    NSLog(@"WakeUpViewController popped out of view: remote control event listner stopped. Observers removed.");
    
    //Resume to normal session
    [[EWBackgroundingManager sharedInstance] registerBackgroudingAudioSession];
    
    //invalid timer
    [timerTimer invalidate];
}

- (void)initData {
//    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:YES];
//    medias = [[_activity.medias allObjects] mutableCopy];
//    [medias sortUsingDescriptors:@[sort]];
    
    medias = [EWWakeUpManager sharedInstance].medias;
    [self.KVOController observe:self keyPath:@"medias" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        [self.tableView reloadData];
    }];
    
    //first time loop
    [EWWakeUpManager sharedInstance].playNext = YES;
    timePast = 1;
    [EWWakeUpManager sharedInstance].loopCount = kLoopMediaPlayCount;
    
    //notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextCell:) name:kAudioPlayerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kNewMediaNotification object:nil];
    //responder to remote control
    [self prepareRemoteControlEventsListener];
    
    //Active session
    [[EWAVManager sharedManager] registerActiveAudioSession];
    
    [EWWakeUpManager sharedInstance].isWakingUp = YES;
    
    [_tableView reloadData];
}

- (void)initView {
    
    header.layer.cornerRadius = 10;
    header.layer.masksToBounds = YES;
    header.layer.borderWidth = 1;
    header.layer.borderColor = [UIColor whiteColor].CGColor;
    header.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    
    timer.text = self.activity.time.date2timeShort;
    self.AM.text = self.activity.time.date2am;
    
    //table view
    //tableView_.frame = CGRectMake(0, 150, self.view.frame.size.width, self.view.frame.size.height-230);
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.contentInset = UIEdgeInsetsMake(40, 0, 80, 0);//the distance of the content to the frame of tableview
    
    //load MediaViewCell
    UINib *nib = [UINib nibWithNibName:@"EWMediaViewCell" bundle:nil];
    //register the nib
    [_tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
    
    //alpha mask
    [EWUIUtil applyAlphaGradientForView:_tableView withEndPoints:@[@0.2f, @0.9f]];
    
    //show button first
    footer.top = [UIScreen mainScreen].bounds.size.height;
    [self.wakeupButton setTitle:@"Shake To Wake Up!" forState:UIControlStateNormal];
    BOOL skipShake = NO;
#ifdef DEBUG
    skipShake = YES;
#endif
    if ([self.shakeProgress isShakeSupported] && !skipShake) {
        [self presentShakeProgressBar];
    }else{
        [_wakeupButton setTitle:@"Wake up!" forState:UIControlStateNormal];
        _shakeProgress.alpha = 0;
        [self.wakeupButton addTarget:self action:@selector(presentPostWakeUpVC) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)presentShakeProgressBar{
    self.shakeProgress.progress = 0;
    //[_wakeupButton removeTarget:self action:@selector(presentShakeProgressBar) forControlEvents:UIControlEventTouchUpInside];
    
    //[_wakeupButton setTitle:@"" forState:UIControlStateNormal];
    [UIView animateWithDuration:0.5 animations:^{
        //show bar
        _shakeProgress.alpha = 1;
    } completion:^(BOOL finished) {
        //start motion detect
        [_shakeProgress startUpdateProgressBarWithProgressingHandler:^{
            
        } CompleteHandler:^{
            
            //show
            [UIView animateWithDuration:0.5 animations:^{
                _shakeProgress.alpha = 0;
            } completion:^(BOOL success) {
                
                [_wakeupButton setTitle:@"Wake up!" forState:UIControlStateNormal];
                [_wakeupButton addTarget:self action:@selector(presentPostWakeUpVC) forControlEvents:UIControlEventTouchUpInside];
            }];
        }];
    }];
}



#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isKindOfClass:[EWActivity class]]) {
        if ([keyPath isEqualToString:@"medias"] && self.activity.medias.count != medias.count) {
            //observed task.media changed
            [_tableView reloadData];
        }
    }
}

#pragma mark - UI


- (void)OnCancel{
    [self.navigationController dismissBlurViewControllerWithCompletionHandler:^{
        [[EWWakeUpManager sharedInstance] stopPlayingVoice];
    }];
}

- (void)selectCellAtIndex:(NSUInteger)n{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:n inSection:0] animated:YES];
    });
    
    [EWWakeUpManager sharedInstance].playNext = NO;
}

-(void)presentPostWakeUpVC
{
    [self.view showLoopingWithTimeout:0];
    
    //stop music
    [[EWWakeUpManager sharedInstance] stopPlayingVoice];
    [EWWakeUpManager sharedInstance].playNext = NO;
    
    //release the pointer in wakeUpManager
    [[EWWakeUpManager sharedInstance] woke];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self scrollViewDidScroll:self.tableView];//prevent header move
    });
    
    EWPostWakeUpViewController * postWakeUpVC = [[EWPostWakeUpViewController alloc] initWithNibName:nil bundle:nil];
    postWakeUpVC.activity = _activity;
    
    [EWUIUtil dismissHUDinView:self.view];
    [self presentViewControllerWithBlurBackground:postWakeUpVC];
}

#pragma mark - tableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return medias.count;
}


#pragma mark - Table view
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

//Asks the data source for a cell to insert in a particular location of the table view. (required)
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    //Use reusable cell or create a new cell
    EWMediaCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    //get media item
    EWMedia *mi;
    if (indexPath.row >= (NSInteger)medias.count) {
        NSLog(@"@@@ WakupView asking for deleted media");
        mi = nil;
    }else{
        mi = [medias objectAtIndex:indexPath.row];
    }
    
    //title
    cell.name.text = mi.author.name;
    
    //control
    cell.controller = self;
    
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
        
        [[EWWakeUpManager sharedInstance].currentActivity removeMediasObject:currentMedia];
        
        //stop play if media is being played
        if ([EWWakeUpManager sharedInstance].currentMedia == (NSUInteger)indexPath.row) {
            //media is being played
            NSLog(@"Deleting current cell, play next");
            if ([tableView numberOfRowsInSection:0] > 1) {
                [[EWWakeUpManager sharedInstance] playNext];
            }
        }
        
        //remove from view with animation
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        //delete
        if (currentMedia.author == [EWPerson me]) {
            [currentMedia remove];
        }
        [EWSync save];
        
        
        //update UI
        [self scrollViewDidScroll:self.tableView];\
        [self.tableView reloadData];
        
    }
    if (editingStyle==UITableViewCellEditingStyleInsert) {
        //do something
    }
}

//when click one item in table, push view to detail page
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [[EWWakeUpManager sharedInstance] playVoiceAtIndex:indexPath.row];
    
    [self selectCellAtIndex:indexPath.row];
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
    
    
    //header
    //NSInteger tableOffsetY = scrollView.contentOffset.y;
    
    // mq
    
//    CGRect newFrame = headerFrame;
//    newFrame.origin.y = MAX(headerFrame.origin.y - (120 + scrollView.contentOffset.y), -70);
//    header.frame = newFrame;
//    //font size
//    CGRect f = self.timer.frame;
//    CGPoint c = self.timer.center;
//    f.size.width = 180 + newFrame.origin.y;
//    self.timer.frame = f;
//    self.timer.center = c;
    
    if (!footer) {
        
        return;
        
    }
    
    //footer
    CGRect footerFrame = footer.frame;
    if (scrollView.contentSize.height < 1) {
        //init phrase
        footerFrame.origin.y = self.view.frame.size.height - footerFrame.size.height;
    }else{
        CGPoint bottomPoint = [self.view convertPoint:CGPointMake(0, scrollView.contentSize.height) fromView:scrollView];
        //NSInteger footerOffset = scrollView.contentSize.height + scrollView.contentInset.top - (scrollView.contentOffset.y + scrollView.frame.size.height);
        footerFrame.origin.y = MAX(bottomPoint.y, self.view.frame.size.height - footerFrame.size.height) ;
    }
    
    footer.frame = footerFrame;
    
}


#pragma mark - Handle player events

/**
 *  Update the highlighted cell when playing
 */
- (void)updatePlayingCellAndProgress{
    //check active cell, switch if changed
    static NSUInteger currentPlayingCellIndex = 0;
    NSUInteger currentMediaIndex = [EWWakeUpManager sharedInstance].currentMediaIndex;
    
    //highlight
    if (currentMediaIndex != currentPlayingCellIndex) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:currentMediaIndex inSection:0];
        if ([_tableView cellForRowAtIndexPath:path]) {
            [_tableView selectRowAtIndexPath:path animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [_tableView deselectRowAtIndexPath:path animated:YES];
            });
        }
    }
    
    //update the progress
    self.currentCell.mediaBar.value = [EWWakeUpManager sharedInstance].playingProgress;
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

- (BOOL)canBecomeFirstResponder{
    return YES;
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
                [self startPlayCells];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                DDLogVerbose(@"Received remote control: Next");
                [[EWWakeUpManager sharedInstance] playNext];
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


@end




