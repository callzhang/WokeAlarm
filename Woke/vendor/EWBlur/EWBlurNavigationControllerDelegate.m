//
//  NavigationControllerDelegate.h
//  NavigationTransitionController
//
//  Created by Lei Zhang 7/12/2014
//  Copyright (c) 2014 BlackFog. All rights reserved.
//

#import "EWBlurNavigationControllerDelegate.h"
#import "EWBlurAnimator.h"

@interface EWBlurNavigationControllerDelegate ()

@property (weak, nonatomic) UINavigationController *fromNavigationController;
@property (weak, nonatomic) UIViewController *toViewController;
@property (strong, nonatomic) EWBlurAnimator* animator;
//@property (strong, nonatomic) UIPercentDrivenInteractiveTransition* interactionController;

@end

@implementation EWBlurNavigationControllerDelegate

- (EWBlurAnimator *)animator{
	if (!_animator) {
		_animator = [EWBlurAnimator new];
	}
	return _animator;
}


- (EWBlurNavigationControllerDelegate *)init{
    self = [super init];
    self.animator = [EWBlurAnimator new];
    return self;
}

- (void)setNavigationController:(UINavigationController *)fromNavigationController{
	NSParameterAssert([fromNavigationController isKindOfClass:[UINavigationController class]]);
	_fromNavigationController = fromNavigationController;
	fromNavigationController.delegate = self;
	UIScreenEdgePanGestureRecognizer* panRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
	panRecognizer.edges = UIRectEdgeLeft;
	[self.fromNavigationController.view addGestureRecognizer:panRecognizer];
}

- (void)pan:(UIPanGestureRecognizer*)recognizer
{
    UIView* view = self.fromNavigationController.view;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint location = [recognizer locationInView:view];
        if (location.x < CGRectGetMidX(view.bounds)){
			self.animator.type = kInteractivePush;
			[self.fromNavigationController pushViewController:self.toViewController animated:YES];
        }
		else{
			self.animator.type = kInteractivePop;
			[self.fromNavigationController popViewControllerAnimated:YES];
		}
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:view];
        // fabs() 求浮点数的绝对值
        CGFloat d = fabs(translation.x / CGRectGetWidth(view.bounds));
		//[self.animator updateInteractiveTransition:d];
		[self.animator setProgress:d];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ([recognizer velocityInView:view].x < 0) {
            [self.animator finishInteractiveTransition];
        } else {
            [self.animator cancelInteractiveTransition];
        }
		self.animator = nil;
    }
}

#pragma mark - UINavigationViewControllerDelegate
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
	self.fromNavigationController = navigationController;
	self.toViewController = toVC;
    if (operation == UINavigationControllerOperationPush) {
        self.animator.type = UINavigationControllerOperationPush;
		//return self.animator;
    }else if (operation == UINavigationControllerOperationPop){
        self.animator.type = UINavigationControllerOperationPop;
		//return self.animator;
    }
    return self.animator;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    return self.animator;
}

- (id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator{
	return nil; // We don't want to use interactive transition to dismiss the modal view, we are just going to use the standard animator.
}

#pragma mark - UIViewController transitioning
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    self.animator.type = kModelViewPresent;
    return self.animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissedZ{
    self.animator.type = kModelViewDismiss;
    return self.animator;
}


@end
