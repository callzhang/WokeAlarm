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
- (void)awakeFromNib {
    [super awakeFromNib];
    self.replyView.hidden = YES;
    self.playIndicator.hidden = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.peopleViewLeadingConstraint.constant = self.replyView.frame.size.width;
    });
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)setMedia:(EWMedia *)media{
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
        buttonNames = @[@"woke-response-icon-heart-normal",];
    });
    
    return buttonNames;
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

- (void)updateConstraints {
    [super updateConstraints];
}
@end
