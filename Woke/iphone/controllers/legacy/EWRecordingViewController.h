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
@class SCSiriWaveformView;
@class EWPerson;

@interface EWRecordingViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) NSSet *wakees;

@property (strong, nonatomic) IBOutlet UIButton *playBtn;
@property (strong, nonatomic) IBOutlet UIButton *recordBtn;
@property (strong, nonatomic) IBOutlet UIButton *sendBtn;

@property (strong, nonatomic) IBOutlet UILabel *detail;
@property (strong, nonatomic) IBOutlet UICollectionView *peopleView;
@property (weak, nonatomic) IBOutlet SCSiriWaveformView *waveformView;
@property (strong, nonatomic) IBOutlet UAProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *wish;

@property (strong, nonatomic) IBOutlet UILabel *retakeLabel;

@property (strong, nonatomic) IBOutlet UILabel *playLabel;

@property (strong, nonatomic) IBOutlet UILabel *sendLabel;

- (IBAction)play:(id)sender;//or stop
- (IBAction)record:(id)sender;
- (IBAction)send:(id)sender;


//waveform
- (void)startWaveform;
- (void)stopWaveform;
@end
