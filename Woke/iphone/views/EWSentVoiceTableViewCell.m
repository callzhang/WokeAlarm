//
//  EWSentVoiceTableViewCell.m
//  Woke
//
//  Created by Zitao Xiong on 2/7/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWSentVoiceTableViewCell.h"
#import "EWMedia.h"
#import "EWWakeUpManager.h"
#import "EWAVManager.h"
#import "EWMediaFile.h"

@interface EWSentVoiceTableViewCell()
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIImageView *playingIndicator;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIImageView *repliedImageView;

@property (nonatomic, assign, getter=isPlaying) BOOL playing;
@end

@implementation EWSentVoiceTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAVManagerDidFinishPlaying) name:kAVManagerDidFinishPlaying object:nil];
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAVManagerDidFinishPlaying) name:kEWAVManagerDidStopPlayNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProgressDidUpdateNotification:) name:kEWAVManagerDidUpdateProgressNotification object:nil];
    
    [self prepareForReuse];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)prepareForReuse {
    self.playing = NO;
    self.progressView.progress = 0;
}

- (void)setMedia:(EWMedia *)media {
    if (_media != media) {
        _media = media;
        
        self.profileImageView.image = media.mediaFile.thumbnail?:media.receiver.profilePic;
        [self.profileImageView applyHexagonSoftMask];
        
        self.nameLabel.text = self.media.receiver.name;
        
        self.progressView.progress = 0;
        
        NSString *imageName = borderlessImageAssetNameFromEmoji(self.media.response);
        if (imageName) {
            self.repliedImageView.image = [UIImage imageNamed:imageName];
        }
        else {
            self.repliedImageView.image = [UIImage new];
        }
    }
}

#pragma mark - AVManager Notification
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

#pragma mark -
- (void)setPlaying:(BOOL)playing {
    _playing = playing;
    if (playing) {
        self.playingIndicator.hidden = NO;
    }
    else {
        self.playingIndicator.hidden = YES;
    }
}
@end
