//
//  EWRecordingViewController.h
//  EarlyWorm
//
//  Created by Lei on 12/24/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

//#import "EWViewController.h"
#import "EWAVManager.h"
#import "UAProgressView.h"
#import "EWManagedNavigiationItemsViewController.h"
@class SCSiriWaveformView;
@class EWPerson;

@interface EWRecordingViewController : EWManagedNavigiationItemsViewController


@property (weak, nonatomic) IBOutlet SCSiriWaveformView *waveformView;
@property (strong, nonatomic) IBOutlet UAProgressView *progressView;

- (IBAction)onPlayButton:(id)sender;//or stop
- (IBAction)onRecordButton:(id)sender;
- (IBAction)onSendButton:(id)sender;

@property (nonatomic, strong) EWPerson *person;
@end
