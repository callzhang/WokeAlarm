//
//  EWPeopleArrayCollectionViewCell.m
//  Woke
//
//  Created by Zitao Xiong on 1/11/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWPeopleArrayCollectionViewCell.h"

@interface EWPeopleArrayCollectionViewCell ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
@end

@implementation EWPeopleArrayCollectionViewCell

- (void)setPerson:(EWPerson *)person {
    _person = person;
    self.imageView.image = person.profilePic;
    [self applyHexagonSoftMask];
    self.numberLabel.hidden = YES;
}

- (void)setNumberLabelText:(NSString *)text {
    self.numberLabel.text = text;
    self.imageView.hidden = YES;
    [self applyHexagonSoftMask];
    [self setNeedsDisplay];
}
@end
