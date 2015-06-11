//
//  TMRadioOptionRowItem.h
//  Pods
//
//  Created by Zitao Xiong on 5/4/15.
//
//

#import "TMRowItem.h"
#import "TMRadioRowItem.h"

@interface TMRadioOptionRowItem : TMRowItem<TMRadioOptionRow>
@property (nonatomic, strong) TMRadioRowItemSelectionModel *model;
@end
