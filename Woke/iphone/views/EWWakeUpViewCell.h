//
//  EWWakeUpViewCell.h
//  Woke
//
//  Created by Lei Zhang on 12/27/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWMedia.h"

@interface EWWakeUpViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UIImageView *playIndicator;
@property (nonatomic, strong) EWMedia *media;
@end
