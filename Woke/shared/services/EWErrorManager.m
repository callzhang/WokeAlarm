//
//  EWErrorManager.m
//  Woke
//
//  Created by Zitao Xiong on 16/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWErrorManager.h"
#import "FBErrorUtility.h"
#import "FBSession.h"

NSString * const EWErrorDomain = @"com.wokealarm.error";
NSString * const EWErrorInfoDescriptionKey = @"Description";

@implementation EWErrorManager

+ (void)handleError:(NSError *)error {
#ifdef DEBUG
    NSString *errStr = [NSString stringWithFormat:@"%@", error];
    EWAlert(errStr);
#endif
    DDLogError(@"%@", error);
    
    if ([error.domain isEqualToString:FacebookSDKDomain]) {
        [self handleFacebookException:error];
    }
    else if ([error.domain isEqualToString:PFParseErrorDomain]) {
        NSString *str = [NSString stringWithFormat:@"Got Parse error: %@", error.localizedDescription];
        DDLogError(str);
        EWAlert(str);
    }
	else if ([error.domain isEqualToString:NSCocoaErrorDomain]){
		if (error.code == 1570 || error.code == 1560) {
			DDLogError(@"Failed to save core data: %@", error);
		}else{
			[NSException raise:@"UnhandledError" format:@"Core Data error passed in is not handled: %@", error];
		}
	}
    else {
        [NSException raise:@"UnhandledError" format:@"Error passed in is not handled: %@", error];
    }
}

+ (void)handleFacebookException:(NSError *)error{
    if (!error) {
        return;
    }
    NSString *alertText;
    NSString *alertTitle;
    // If the error requires people using an app to make an action outside of the app in order to recover
    
    if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
        alertTitle = @"Something went wrong";
        alertText = [FBErrorUtility userMessageForError:error];
        //[self showMessage:alertText withTitle:alertTitle];
    } else {
        
        // If the user cancelled login, do nothing
        if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
            //[MBProgressHUD hideHUDForView:[UIApplication sharedApplication].delegate.window.rootViewController.view animated:YES];
            DDLogInfo(@"User cancelled login");
            alertTitle = @"User Cancelled Login";
            alertText = @"Please Try Again";
            
            // Handle session closures that happen outside of the app
        } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
            alertTitle = @"Session Error";
            alertText = @"Your current session is no longer valid. Please log  in again.";
            //[self showMessage:alertText withTitle:alertTitle];
            
            // Here we will handle all other errors with a generic error messageaccessToken:.
            // We recommend you check our Handling Errors guide for more information
            // https://developers.facebook.com/docs/ios/errors/
            
            // Clear this token
            [FBSession.activeSession closeAndClearTokenInformation];
        } else if (error.code == 5){
            if (![EWSync isReachable]) {
                DDLogError(@"No connection: %@", error.description);
            }else{
                
                DDLogError(@"Error %@", error.description);
                alertTitle = @"Something went wrong";
                alertText = @"Operation couldn't be finished. We appologize for this. It may caused by weak internet connection.";
            }
        } else {
            //Get more error information from the error
            NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
            
            // Show the user an error message
            alertTitle = @"Something went wrong";
            alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
            //[self showMessage:alertText withTitle:alertTitle];
            DDLogError(@"Failed to login fb: %@", error.description);
            
            // Clear this token
            [FBSession.activeSession closeAndClearTokenInformation];
        }
    }
    
    if (!alertTitle) return;
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:alertTitle
                              message:alertText
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
    
}

+ (NSError *)noInternetConnectError{
    NSError *err = [[NSError alloc] initWithDomain:kWokeDomain code:kEWNoInternetReachabilityErrorCode userInfo:nil];
    return err;
}

+ (NSError *)invalidObjectError:(id)obj{
    NSString *des = [NSString stringWithFormat:@"The Object is invalid %@", obj];
    NSError *err = [[NSError alloc] initWithDomain:kWokeDomain code:kEWInvalidObjectErrorCode userInfo:@{NSLocalizedDescriptionKey: des}];
    return err;
}

+ (NSError *)noServerIDError{
	NSError *err = [[NSError alloc] initWithDomain:@"WokeAlarm" code:kEWSyncErrorNoServerID userInfo:@{NSLocalizedDescriptionKey: @"No object identification (objectId) available"}];
	return err;
}
@end
