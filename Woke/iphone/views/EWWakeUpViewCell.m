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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *peopleViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *peopleViewWidthConstraint;
@property (nonatomic, assign) BOOL open;

@end

@implementation EWWakeUpViewCell
- (void)setMedia:(EWMedia *)media{
    self.backgroundColor = [UIColor clearColor];
    //set value
    self.name.text = media.author.name;
    self.image.image = media.mediaFile.thumbnail?:media.author.profilePic;
    self.progress.progress = 0;
}

- (IBAction)onToggleButton:(id)sender {
    if (self.open) {
        self.open = NO;
        self.peopleViewWidthConstraint.priority = 750;
        self.peopleViewLeadingConstraint.priority = 749;
    }
    else {
        self.open = YES;
        self.peopleViewWidthConstraint.priority = 749;
        self.peopleViewLeadingConstraint.priority = 750;
    }
}

@end
