//
//  UIStoryBoard+Extensions.m
//

#import "UIWindow+Extensions.h"
#import "AppDelegate.h"

@implementation UIWindow (Extensions)
+ (UIWindow *)mainWindow {
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    return delegate.window;
}

- (EWBaseNavigationController *)rootNavigationController {
    UIWindow *window = [[self class] mainWindow];
    EWBaseNavigationController *navigationController = (EWBaseNavigationController *)window.rootViewController;
    
    if ([navigationController isKindOfClass:[EWBaseNavigationController class]]) {
        return (EWBaseNavigationController *)navigationController;
    }
    else {
        DDLogError(@"root navigation controller is not a MSBaseNavigationController");
        return nil;
    }
}
@end
