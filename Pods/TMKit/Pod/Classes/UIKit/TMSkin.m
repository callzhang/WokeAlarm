//
//  TMSkin.m
//  Pods
//
//  Created by Zitao Xiong on 5/13/15.
//
//

#import "TMSkin.h"


NSString *const TMSignatureColorKey = @"TMSignatureColorKey";
NSString *const TMBackgroundColorKey = @"TMBackgroundColorKey";
NSString *const TMToolBarTintColorKey = @"TMToolBarTintColorKey";
NSString *const TMLightTintColorKey = @"TMLightTintColorKey";
NSString *const TMDarkTintColorKey = @"TMDarkTintColorKey";
NSString *const TMCaptionTextColorKey = @"TMCaptionTextColorKey";
NSString *const TMBlueHighlightColorKey = @"TMBlueHighlightColorKey";

@implementation UIColor (TMColor)

#define cachedColorMethod(m, r, g, b, a) \
+ (UIColor *)m { \
static UIColor *c##m = nil; \
static dispatch_once_t onceToken##m; \
dispatch_once(&onceToken##m, ^{ \
c##m = [[UIColor alloc] initWithRed:r green:g blue:b alpha:a]; \
}); \
return c##m; \
}

cachedColorMethod(tm_midGrayTintColor, 0./255., 0./255., 25./255., .22)
cachedColorMethod(tm_redColor, 255./255.,  59./255.,  48./255., 1.)
cachedColorMethod(tm_grayColor, 142./255., 142./255., 147./255., 1.)
cachedColorMethod(tm_darkGrayColor, 102./255., 102./255., 102./255., 1.)

#undef cachedColorMethod

@end

static NSMutableDictionary *colors() {
    
    static NSMutableDictionary *colors = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colors = [@{
                    TMSignatureColorKey : TMRGB(0x000000),
                    TMBackgroundColorKey : TMRGB(0xffffff),
                    TMToolBarTintColorKey : TMRGB(0xffffff),
                    TMLightTintColorKey : TMRGB(0xeeeeee),
                    TMDarkTintColorKey : TMRGB(0x888888),
                    TMCaptionTextColorKey : TMRGB(0xcccccc),
                    TMBlueHighlightColorKey : [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]
                    } mutableCopy];
    });
    return colors;
}

UIColor *TMColor(NSString *colorKey) {
    return colors()[colorKey];
}

void TMColorSetColorForKey(NSString *key, UIColor *color) {
    NSMutableDictionary *d = colors();
    d[key] = color;
}

const CGSize TMiPhone4ScreenSize = (CGSize){320, 480};
const CGSize TMiPhone5ScreenSize = (CGSize){320, 568};
const CGSize TMiPhone6ScreenSize = (CGSize){375, 667};
const CGSize TMiPhone6PlusScreenSize = (CGSize){414, 736};
const CGSize TMiPadScreenSize = (CGSize){768, 1024};

TMScreenType TMGetScreenTypeForBounds(CGRect bounds) {
    TMScreenType screenType = TMScreenTypeiPhone6;
    CGFloat maximumDimension = MAX(bounds.size.width, bounds.size.height);
    if (maximumDimension < TMiPhone4ScreenSize.height + 1) {
        screenType = TMScreenTypeiPhone4;
    } else if (maximumDimension < TMiPhone5ScreenSize.height + 1) {
        screenType = TMScreenTypeiPhone5;
    } else if (maximumDimension < TMiPhone6ScreenSize.height + 1) {
        screenType = TMScreenTypeiPhone6;
    } else if (maximumDimension < TMiPhone6PlusScreenSize.height + 1) {
        screenType = TMScreenTypeiPhone6Plus;
    } else {
        screenType = TMScreenTypeiPad;
    }
    return screenType;
}

TMScreenType TMGetScreenTypeForWindow(UIWindow *window) {
    if (!window) {
        window = [[[UIApplication sharedApplication] windows] firstObject];
    }
    return TMGetScreenTypeForBounds([window bounds]);
}

TMScreenType TMGetScreenTypeForScreen(UIScreen *screen) {
    TMScreenType screenType = TMScreenTypeiPhone6;
    if (screen == [UIScreen mainScreen]) {
        screenType = TMGetScreenTypeForBounds([screen bounds]);
    }
    return screenType;
}

CGFloat TMGetMetricForScreenType(TMScreenMetric metric, TMScreenType screenType) {
    static  const CGFloat metrics[TMScreenMetric_COUNT][TMScreenType_COUNT] = {
        // iPhone 6+,  iPhone 6,  iPhone 5,  iPhone 4,      iPad
        {        128,       128,       100,       100,       128},      // TMScreenMetricTopToCaptionBaseline
        {         35,        35,        32,        24,        35},      // TMScreenMetricFontSizeHeadline
        {         38,        38,        32,        28,        38},      // TMScreenMetricMaxFontSizeHeadline
        {         30,        30,        30,        24,        30},      // TMScreenMetricFontSizeSurveyHeadline
        {         32,        32,        32,        28,        32},      // TMScreenMetricMaxFontSizeSurveyHeadline
        {         17,        17,        17,        16,        17},      // TMScreenMetricFontSizeSubheadline
        {         62,        62,        51,        51,        62},      // TMScreenMetricCaptionBaselineToFitnessTimerTop
        {         62,        62,        43,        43,        62},      // TMScreenMetricCaptionBaselineToTappingLabelTop
        {         36,        36,        32,        32,        36},      // TMScreenMetricCaptionBaselineToInstructionBaseline
        {         30,        30,        28,        24,        30},      // TMScreenMetricInstructionBaselineToLearnMoreBaseline
        {         44,        44,        20,        14,        44},      // TMScreenMetricLearnMoreBaselineToStepViewTop
        {         40,        40,        30,        14,        40},      // TMScreenMetricLearnMoreBaselineToStepViewTopWithNoLearnMore
        {         36,        36,        20,        12,        36},      // TMScreenMetricContinueButtonTopMargin
        {         40,        40,        20,        12,        40},      // TMScreenMetricContinueButtonTopMarginForIntroStep
        {         44,        44,        40,        40,        44},      // TMScreenMetricIllustrationToCaptionBaseline
        {        198,       198,       194,       152,       297},      // TMScreenMetricIllustrationHeight
        {        300,       300,       176,       152,       300},      // TMScreenMetricInstructionImageHeight
        {        150,       150,       146,       146,       150},      // TMScreenMetricContinueButtonWidth
        {        162,       162,       120,       116,       162},      // TMScreenMetricMinimumStepHeaderHeightForMemoryGame
        {         60,        60,        60,        44,        60},      // TMScreenMetricTableCellDefaultHeight
        {         55,        55,        55,        44,        55},      // TMScreenMetricTextFieldCellHeight
        {         36,        36,        36,        26,        36},      // TMScreenMetricChoiceCellFirstBaselineOffsetFromTop,
        {         24,        24,        24,        18,        24},      // TMScreenMetricChoiceCellLastBaselineToBottom,
        {         24,        24,        24,        24,        24},      // TMScreenMetricChoiceCellLabelLastBaselineToLabelFirstBaseline,
        {         30,        30,        20,        20,        30},      // TMScreenMetricLearnMoreButtonSideMargin
        {         10,        10,         0,         0,        10},      // TMScreenMetricHeadlineSideMargin
        {         44,        44,        44,        44,        44},      // TMScreenMetricToolbarHeight
        {         48,        51,        52,        48,        48},      // TMScreenMetricVerticalScaleHorizontalMargin
    };
    return metrics[metric][screenType];
}

CGFloat TMGetMetricForWindow(TMScreenMetric metric, UIWindow *window) {
    return TMGetMetricForScreenType(metric, TMGetScreenTypeForWindow(window));
}

const CGFloat TMLayoutMarginWidthiPad = 115.0;
const CGFloat TMLayoutMarginWidthThinBezelRegular = 20.0;
const CGFloat TMLayoutMarginWidthRegularBezel = 15.0;

CGFloat TMTableViewCellLeftMargin(UITableViewCell *cell) {
    CGFloat margin = 0;
    switch (TMGetScreenTypeForWindow(cell.window)) {
        case TMScreenTypeiPhone4:
        case TMScreenTypeiPhone5:
        case TMScreenTypeiPhone6:
            margin = TMLayoutMarginWidthRegularBezel;
            break;
        case TMScreenTypeiPhone6Plus:
        case TMScreenTypeiPad:
        default:
            margin = TMLayoutMarginWidthThinBezelRegular;
            break;
    }
    return margin;
}

CGFloat TMStandardMarginForView(UIView *view) {
    CGFloat margin = 0;
    switch (TMGetScreenTypeForWindow(view.window)) {
        case TMScreenTypeiPhone4:
        case TMScreenTypeiPhone5:
        case TMScreenTypeiPhone6:
        case TMScreenTypeiPhone6Plus:
        default:
            margin = TMTableViewCellLeftMargin(view);
            break;
        case TMScreenTypeiPad:
            margin = TMLayoutMarginWidthiPad;
            break;
    }
    return margin;
}

UIEdgeInsets TMDefaultTableViewCellLayoutMargins(UITableViewCell *cell) {
    return (UIEdgeInsets){.left=TMTableViewCellLeftMargin(cell),
        .right=TMTableViewCellLeftMargin(cell),
        .bottom=8,
        .top=8};
}

UIEdgeInsets TMDefaultFullScreenViewLayoutMargins(UIView *view) {
    UIEdgeInsets layoutMargins = UIEdgeInsetsZero;
    TMScreenType screenType = TMGetScreenTypeForWindow(view.window);
    if (screenType == TMScreenTypeiPad) {
        layoutMargins = (UIEdgeInsets){.left=TMStandardMarginForView(view), .right=TMStandardMarginForView(view)};
    }
    return layoutMargins;
}

UIEdgeInsets TMDefaultScrollIndicatorInsets(UIView *view) {
    UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsZero;
    TMScreenType screenType = TMGetScreenTypeForWindow(view.window);
    if (screenType == TMScreenTypeiPad) {
        scrollIndicatorInsets = (UIEdgeInsets){.left=-TMStandardMarginForView(view), .right=-TMStandardMarginForView(view)};
    }
    return scrollIndicatorInsets;
}

void TMUpdateScrollViewBottomInset(UIScrollView *scrollView, CGFloat bottomInset) {
    UIEdgeInsets insets = scrollView.contentInset;
    if (!TMCGFloatNearlyEqualToFloat(insets.bottom, bottomInset)) {
        CGPoint savedOffset = scrollView.contentOffset;
        
        insets.bottom = bottomInset;
        scrollView.contentInset = insets;
        
        insets = scrollView.scrollIndicatorInsets;
        insets.bottom = bottomInset;
        scrollView.scrollIndicatorInsets = insets;
        
        scrollView.contentOffset = savedOffset;
    }
}
