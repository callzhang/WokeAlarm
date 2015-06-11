//
//  TMSkin.h
//  Pods
//
//  Created by Zitao Xiong on 5/13/15.
//
//

#import <Foundation/Foundation.h>
@import UIKit;
#import "TMMacros.h"
#import "TMHelper.h"

NS_ASSUME_NONNULL_BEGIN

/// Color used for toolbar
TM_EXTERN NSString *const TMToolBarTintColorKey;

/// Color used for view's backgroud
TM_EXTERN NSString *const TMBackgroundColorKey;

/// Color used for signature
TM_EXTERN NSString *const TMSignatureColorKey;

/// Color used for a light-colored tint
TM_EXTERN NSString *const TMLightTintColorKey;

/// Color used for a dark-colored tint
TM_EXTERN NSString *const TMDarkTintColorKey;

/// Color used for caption text
TM_EXTERN NSString *const TMCaptionTextColorKey;

/// Caption used for a "blue" highlight
TM_EXTERN NSString *const TMBlueHighlightColorKey;

/// Return the color for a specified TM..ColorKey
UIColor *TMColor(NSString *colorKey);

/// Modify the color for a specified TM..ColorKey. (for customization)
void TMColorSetColorForKey(NSString *key, UIColor *color);

@interface UIColor (TMColor)

+ (UIColor *)tm_midGrayTintColor;
+ (UIColor *)tm_redColor;
+ (UIColor *)tm_grayColor;
+ (UIColor *)tm_darkGrayColor;

@end

typedef NS_ENUM(NSInteger, TMScreenMetric) {
    TMScreenMetricTopToCaptionBaseline,
    TMScreenMetricFontSizeHeadline,
    TMScreenMetricMaxFontSizeHeadline,
    TMScreenMetricFontSizeSurveyHeadline,
    TMScreenMetricMaxFontSizeSurveyHeadline,
    TMScreenMetricFontSizeSubheadline,
    TMScreenMetricCaptionBaselineToFitnessTimerTop,
    TMScreenMetricCaptionBaselineToTappingLabelTop,
    TMScreenMetricCaptionBaselineToInstructionBaseline,
    TMScreenMetricInstructionBaselineToLearnMoreBaseline,
    TMScreenMetricLearnMoreBaselineToStepViewTop,
    TMScreenMetricLearnMoreBaselineToStepViewTopWithNoLearnMore,
    TMScreenMetricContinueButtonTopMargin,
    TMScreenMetricContinueButtonTopMarginForIntroStep,
    TMScreenMetricIllustrationToCaptionBaseline,
    TMScreenMetricIllustrationHeight,
    TMScreenMetricInstructionImageHeight,
    TMScreenMetricContinueButtonWidth,
    TMScreenMetricMinimumStepHeaderHeightForMemoryGame,
    TMScreenMetricTableCellDefaultHeight,
    TMScreenMetricTextFieldCellHeight,
    TMScreenMetricChoiceCellFirstBaselineOffsetFromTop,
    TMScreenMetricChoiceCellLastBaselineToBottom,
    TMScreenMetricChoiceCellLabelLastBaselineToLabelFirstBaseline,
    TMScreenMetricLearnMoreButtonSideMargin,
    TMScreenMetricHeadlineSideMargin,
    TMScreenMetricToolbarHeight,
    TMScreenMetricVerticalScaleHorizontalMargin,
    TMScreenMetric_COUNT
};

typedef NS_ENUM(NSInteger, TMScreenType) {
    TMScreenTypeiPhone6Plus,
    TMScreenTypeiPhone6,
    TMScreenTypeiPhone5,
    TMScreenTypeiPhone4,
    TMScreenTypeiPad,
    TMScreenType_COUNT
};

TMScreenType TMGetScreenTypeForWindow(UIWindow *__nullable window);
CGFloat TMGetMetricForScreenType(TMScreenMetric metric, TMScreenType screenType);
CGFloat TMGetMetricForWindow(TMScreenMetric metric, UIWindow *__nullable window);

CGFloat TMTableViewCellLeftMargin(UIView *view);
CGFloat TMStandardMarginForView(UIView *view);
UIEdgeInsets TMDefaultTableViewCellLayoutMargins(UIView *view);
UIEdgeInsets TMDefaultFullScreenViewLayoutMargins(UIView *view);
UIEdgeInsets TMDefaultScrollIndicatorInsets(UIView *view);
void TMUpdateScrollViewBottomInset(UIScrollView *scrollView, CGFloat bottomInset);

NS_ASSUME_NONNULL_END
