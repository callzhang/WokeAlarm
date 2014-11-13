//
//  PersonViewCell.m
//  EarlyWorm
//
//  Created by Lei Zhang on 7/28/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWMediaCell.h"
//TODO:#import "EWWakeUpViewController.h"
#import "EWAVManager.h"
#import "EWMediaSlider.h"
#import "EWDataStore.h"
#import "EWPersonViewController.h"
#import "EWUIUtil.h"
#import "UIView+Layout.h"
#import "UIViewController+Blur.h"

#define maxBytes            150000
#define progressBarLength   200

@implementation EWMediaCell
@synthesize media;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.name.text = @"";
        self.message.text = @"";
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
		self.profilePic.contentMode = UIViewContentModeScaleAspectFill;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:YES];
    // Configure the view for the selected state
}
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    [super setHighlighted:highlighted animated:YES];
}


- (IBAction)play:(id)sender {
    if (EWAVManager.sharedManager.player.isPlaying) {
        [EWAVManager.sharedManager stopAllPlaying];
        if ([EWAVManager.sharedManager.currentCell isEqual:self]) {
            return;
        }
    }
    //play this cell
    [EWAVManager.sharedManager playForCell:self];
    
}

- (void)setMedia:(EWMedia *)m{
    if (!m) return;
    if (media == m) return;
    media = m;
    if([media.type isEqualToString:kMediaTypeVoice]){
        self.mediaBar.hidden = NO;
        [self.icon setImage:[UIImage imageNamed:@"Voice Icon"] forState:UIControlStateNormal];
        
        //set media bar length
        NSError *err;
        AVAudioPlayer *p = [[AVAudioPlayer alloc] initWithData:media.audio error:&err];
        if (err) {
            NSLog(@"Failed to init av audio player:%@", err);
        }
        double len = p.duration;
        double ratio = len/30/2 + 0.5;
        if (ratio > 1.0) ratio = 1.0;
        self.mediaBar.width = progressBarLength * ratio;
        
        [self setNeedsDisplay];
    }else{
        [NSException raise:@"Unexpected media type" format:@"Reason: please support %@", media.type];
    }
    
    //date
    self.date.text = [media.updatedAt date2MMDD];
    
    //profile
    [self.profilePic setImage:media.author.profilePic forState:UIControlStateNormal];
    [EWUIUtil applyHexagonSoftMaskForView:self.profilePic.imageView];
    
    //description
    self.message.text = media.message;
    
}


- (IBAction)profile:(id)sender{
    if (!media.author) {
        return;
    }
    EWPersonViewController *profileVC = [[EWPersonViewController alloc] initWithPerson:media.author];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:profileVC];
    [self.controller presentViewControllerWithBlurBackground:navController completion:NULL];

}


//- (void)updateCell:(NSNotification *)notification{
//    NSString *path = notification.userInfo[kAudioPlayerNextPath];
//    NSString *localPath = [[EWDataStore sharedInstance] localPathForKey:media.audioKey];
//    if ([path isEqualToString:localPath] || [path isEqualToString:media.audioKey]) {
//        //matched media cell with playing path
//        [EWAVManager sharedManager].currentCell = self;
//    }
//}

@end
