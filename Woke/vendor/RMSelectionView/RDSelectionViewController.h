
#import <UIKit/UIKit.h>



@class RDSelectionViewController;

/**
 This block is called when the user selects a certain date if blocks are used.
 
 @param vc The date selection view controller that just finished selecting a date.
 
 @param aDate The selected date.
 */

typedef void (^EWSelectionBlock)(RDSelectionViewController *vc);

/**
 This block is called when the user cancels if blocks are used.
 
 @param vc The date selection view controller that just got canceled.
 */
typedef void (^EWCancelBlock)(RDSelectionViewController *vc);

@protocol EWSelectionViewControllerDelegate <NSObject>



/**
 This delegate method is called when the user selects a certain date.
 
 @param vc The date selection view controller that just finished selecting a date.
 
 @param aDate The selected date.
 */
- (void)dateSelectionViewController:(RDSelectionViewController *)vc;

/**
 This delegate method is called when the user selects the cancel button or taps the darkened background (if `backgroundTapsDisabled` is set to NO).
 
 @param vc The date selection view controller that just canceled.
 */
- (void)dateSelectionViewControllerDidCancel:(RDSelectionViewController *)vc;

@optional

/**
 *  This delegate is called when the now button of the date selection view controller has been pressed.
 *
 *  Implementation of this delegate is optional. If you choose to implement it, you are responsible to do whatever should be done when the now button has been pressed. If you do not choose to implement it, the default behavior is to set the date selection control to the current date.
 *
 *  @param vc The date selection view controller whose now button has been pressed.
 */


@end

@interface RDSelectionViewController : UIViewController

/// @name Properties

/**
 Will return the instance of UIDatePicker that is used.
 */

@property (nonatomic,strong) UIPickerView *picker;

/**
 Will return the label that is used as a title for the picker. You can use this property to set a title and to customize the appearance of the title.
 
 If you want to set a title, be sure to set it before showing the picker view controller as otherwise the title will not be shown.
 */
@property (nonatomic, strong, readonly) UILabel *titleLabel;

/**
 Used to set the delegate.
 
 The delegate must conform to the `RMDateSelectionViewControllerDelegate` protocol.
 */
@property (weak) id<EWSelectionViewControllerDelegate> delegate;

/**
 Used to set the text color of the buttons but not the date picker.
 */
@property (strong, nonatomic) UIColor *tintColor;

/**
 Used to set the background color.
 */
@property (strong, nonatomic) UIColor *backgroundColor;

/**
 *  Used to set the background color when the user selets a button.
 */
@property (strong, nonatomic) UIColor *selectedBackgroundColor;

/**
 Used to enable or disable motion effects. Default value is NO.
 */
@property (assign, nonatomic) BOOL disableMotionEffects;

/**
 Used to enable or disable bouncing effects when sliding in the date selection view. Default value is NO.
 */
@property (assign, nonatomic) BOOL disableBouncingWhenShowing;

/**
 When YES the now button is hidden. Default value is NO.
 
 Must be set before -[RMDateSelectionViewController show] or -[RMDateSelectionViewController showFromViewController:] is called or otherwise this property has no effect.
 */
@property (assign, nonatomic) BOOL hideNowButton;

/**
 *  When YES taps on the background view are ignored. Default value is NO.
 */
@property (assign, nonatomic) BOOL backgroundTapsDisabled;

/// @name Class Methods

/**
 This returns a new instance of `RMDateSelectionViewController`. Always use this class method to get an instance. Do not initialize an instance yourself.
 
 @return Returns a new instance of `RMDateSelectionViewController`
 */

/**
 Set a localized title for the select button. Default is 'Now'
 */
+ (void)setLocalizedTitleForNowButton:(NSString *)newLocalizedTitle;

/**
 Set a localized title for the select button. Default is 'Cancel'.
 */
+ (void)setLocalizedTitleForCancelButton:(NSString *)newLocalizedTitle;

/**
 Set a localized title for the select button. Default is 'Select'.
 */
+ (void)setLocalizedTitleForSelectButton:(NSString *)newLocalizedTitle;

/// @name Instance Methods






-(id)initWithPickerDelegate:(id)vc;


/**
 This shows the date selection view controller as child view controller of the root view controller of the current key window.
 
 The content of the rootview controller will be darkened and the date selection view controller will be shown on top.
 
 Make sure the delegate property is assigned. Otherwise you will not get any calls when a date is selected or the selection has been canceled.
 */
- (void)show;

/**
 This shows the date selection view controller as child view controller of the root view controller of the current key window.
 
 The content of the rootview controller will be darkened and the date selection view controller will be shown on top.
 
 After a date has been selected the selectionBlock will be called. If you assigned a delegate the corresponding delegate method will be called, too. Keep in mind that when the user cancels selection you will only get calls if you assigned a delegate.
 
 @param selectionBlock The block to call when the user selects a date.
 */
- (void)showWithSelectionHandler:(EWSelectionBlock)selectionBlock;

/**
 This shows the date selection view controller as child view controller of the root view controller of the current key window.
 
 The content of the rootview controller will be darkened and the date selection view controller will be shown on top.
 
 After a date has been selected the selectionBlock will be called. If the user choses to cancel the selection, the cancel block will be called. If you assigned a delegate the corresponding delegate methods will be called, too.
 
 @param selectionBlock The block to call when the user selects a date.
 @param cancelBlock The block to call when the user cancels the selection.
 */
- (void)showWithSelectionHandler:(EWSelectionBlock)selectionBlock andCancelHandler:(EWCancelBlock)cancelBlock;

/**
 This shows the date selection view controller as child view controller of aViewController.
 
 The content of aViewController will be darkened and the date selection view controller will be shown on top.
 
 @param aViewController The date selection view controller will be displayed as a child view controller of this view controller.
 */
- (void)showFromViewController:(UIViewController *)aViewController;

/**
 This will remove the date selection view controller from whatever view controller it is currently shown in.
 */
- (void)dismiss;

@end
