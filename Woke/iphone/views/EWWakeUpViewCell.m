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

@implementation EWWakeUpViewCell
- (void)setMedia:(EWMedia *)media{
    //set value
    self.name.text = media.author.name;
    self.image.image = media.mediaFile.thumbnail?:media.author.profilePic;
    self.progress.progress = 0;
}
@end
