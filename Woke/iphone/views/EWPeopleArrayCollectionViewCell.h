//
//  EWPeopleArrayCollectionViewCell.h
//  Woke
//
//  Created by Zitao Xiong on 1/11/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWPerson.h"

@interface EWPeopleArrayCollectionViewCell : UICollectionViewCell
@property (nonatomic, strong) EWPerson *person;
- (void)setNumberLabelText:(NSString *)text;
@end
