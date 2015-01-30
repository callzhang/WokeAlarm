//
//  EWWakeUpViewCell.m
//  Woke
//
//  Created by Lei Zhang on 12/27/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWWakeUpViewCell.h"
#import "EWMediaFile.h"
#import "EWMedia.h"
#import "AssetCatalogIdentifiers.h"
#import "EWWakeUpManager.h"
#import "EWAVManager.h"
@interface EWWakeUpViewCell()
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *peopleViewLeadingConstraint;
@property (nonatomic, assign) BOOL open;
@property (weak, nonatomic) IBOutlet UIView *replyView;
@property (nonatomic, assign) NSInteger replyWidth;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *emojiButtons;
@property (weak, nonatomic) IBOutlet UIButton *heartButton;

@property (nonatomic, readonly) NSArray *buttonImageNames;

@end

@implementation EWWakeUpViewCell
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    [super awakeFromNib];

    //delay set constant
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.peopleViewLeadingConstraint.constant = self.replyView.frame.size.width;
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAVManagerDidFinishPlaying) name:kAVManagerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAVManagerDidFinishPlaying) name:kEWAVManagerDidStopPlayNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProgressDidUpdateNotification:) name:kEWAVManagerDidUpdateProgressNotification object:nil];
    
    [self prepareForReuse];
}

- (void)prepareForReuse {
    self.replyView.hidden = YES;
    self.playing = NO;
    
    self.progressView.progress = 0;
}

#pragma mark - 
- (void)setPlaying:(BOOL)playing {
    _playing = playing;
    if (playing) {
        self.playIndicator.hidden = NO;
    }
    else {
        self.playIndicator.hidden = YES;
    }
}

#pragma mark - AVManager
- (void)onAVManagerDidFinishPlaying {
    self.playing = NO;
    self.progressView.progress = 0;
}

- (void)onProgressDidUpdateNotification:(NSNotification *)notification {
    CGFloat progress = [notification.userInfo[@"progress"] floatValue];
    EWMedia *media = notification.userInfo[@"media"];
    if ([media isEqual:self.media]) {
        self.progressView.progress = progress;
        self.playing = YES;
    }
    else {
        self.playing = NO;
    }
}

#pragma mark - Media
- (void)setMedia:(EWMedia *)media{
    _media = media;
    
    self.backgroundColor = [UIColor clearColor];
    //set value
    self.name.text = media.author.name;
    self.image.image = media.mediaFile.thumbnail?:media.author.profilePic;
    self.progress.progress = 0;
}

- (NSArray *)buttonImageNames {
    static dispatch_once_t onceToken;
    static NSArray *buttonNames;
    dispatch_once(&onceToken, ^{
        buttonNames = @[[ImagesCatalog wokeResponseIconHeartNormalName],
                        [ImagesCatalog wokeResponseIconSmileNormalName],
                        [ImagesCatalog wokeResponseIconKissNormalName],
                        [ImagesCatalog wokeResponseIconSadNormalName],
                        [ImagesCatalog wokeResponseIconTearNormalName],
                        ];
    });
    
    return buttonNames;
}

#pragma mark - IBAction
- (IBAction)onEmojiButton:(UIButton *)sender {
    NSUInteger index = [self.emojiButtons indexOfObject:sender];
    if (index != NSNotFound) {
        DDLogInfo(@"button: %@ clicked", [self.buttonImageNames objectAtIndex:index]);
    }
    else {
        DDLogError(@"Emoji button can't find");
    }
    
    [self onToggleButton:nil];
}

- (IBAction)onToggleButton:(id)sender {
    self.replyView.hidden = NO;
    
    if (self.open) {
        self.open = NO;
    }
    else {
        self.open = YES;
    }
    
    if (self.open) {
        self.peopleViewLeadingConstraint.constant = 0;
    }
    else {
        self.peopleViewLeadingConstraint.constant = self.replyView.frame.size.width;
    }
    
    [self setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25f animations:^{
        [self layoutIfNeeded];
    }];
}

#pragma mark - Views
- (void)updateConstraints {
    [super updateConstraints];
}
@end
