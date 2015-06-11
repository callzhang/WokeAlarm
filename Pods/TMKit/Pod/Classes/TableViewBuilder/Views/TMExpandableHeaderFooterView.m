//
//  TMExpandableHeaderFooterView.m
//  Pods
//
//  Created by Zitao Xiong on 5/7/15.
//
//

#import "TMExpandableHeaderFooterView.h"

@implementation TMExpandableHeaderFooterView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        UIButton *expandButton = [UIButton buttonWithType:UIButtonTypeCustom];
        expandButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:expandButton];
        
        NSArray *constrants = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[expandButton]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(expandButton)];
        [self addConstraints:constrants];
        constrants = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[expandButton]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(expandButton)];
        [self addConstraints:constrants];
        
        self.expandButton = expandButton;
    }
    
    return self;
}
@end
