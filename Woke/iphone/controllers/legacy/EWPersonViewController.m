//
//  EWPersonViewController.m
//  EarlyWorm
//
//  Created by Lei on 9/5/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

//#define X-Parse-REST-API-Key @""

#import "EWPersonViewController.h"
// Util
#import "EWUIUtil.h"
#import "NSDate+Extend.h"
#import "UIView+Extend.h"

// Model
#import "EWPerson.h"
#import "EWAlarm.h"
//#import "EWMedia.h"
//#import "EWAchievement.h"
#import "EWAccountManager.h"

//manager
#import "EWAlarmManager.h"
#import "EWPersonManager.h"
//#import "EWMediaManager.h"
#import "EWCachedInfoManager.h"
//#import "EWNotificationManager.h"
#import "PFFacebookUtils.h"

//view
#import "EWRecordingViewController.h"
#import "EWLogInViewController.h"
#import "EWFriendsViewController.h"
#import "EWSettingsViewController.h"

//blur
#import "EWBlurNavigationControllerDelegate.h"
#import "UIViewController+Blur.h"

// ImageBrowser
#import "GKImagePicker.h"
#import "IDMPhotoBrowser.h"
#import "APTimeZones.h"

#define kProfileTableArray              @[@"Friends", @"People woke me up", @"People I woke up", @"Last Seen", @"Next wake-up time", @"Wake-ability Score", @"Average wake up time"]


NSString *const taskCellIdentifier = @"taskCellIdentifier";
NSString *const profileCellIdentifier = @"ProfileCell";
NSString *const activitiyCellIdentifier = @"ActivityCell";
@interface EWPersonViewController()<GKImagePickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, IDMPhotoBrowserDelegate>{
    NSArray *dates;
}
@property (strong,nonatomic)GKImagePicker *imagePicker;
@property (strong,nonatomic)NSMutableArray *photos;
@property (strong,nonatomic)IDMPhotoBrowser *photoBrower;
@property (nonatomic) NSDictionary *activities;

@end

@interface EWPersonViewController (UITableView) <UITableViewDataSource, UITableViewDelegate>
@end

@implementation EWPersonViewController
@synthesize person;


- (void)viewDidLoad {
    [super viewDidLoad];
	
	//set me
	if (!person) {
		self.person = [EWPerson me];
	}
    
    //data source
    stats = [[EWCachedInfoManager alloc] init];
    self.activities = [NSDictionary new];
    profileItemsArray = kProfileTableArray;
    
    //table view
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [UIColor clearColor];
	_tableView.backgroundView = nil;
	[self.tableView setTableHeaderView:self.headerView];
    //UINib *taskNib = [UINib nibWithNibName:@"EWTaskHistoryCell" bundle:nil];
    //[tableView registerNib:taskNib forCellReuseIdentifier:taskCellIdentifier];
	//[EWUIUtil applyAlphaGradientForView:_tableView withEndPoints:@[@0.10]];
    //tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    
    //default state
    [EWUIUtil applyHexagonSoftMaskForView:self.picture];
    self.name.text = @"";
    self.location.text = @"";
    self.statement.text = @"";
	
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //navigation
    if (self.navigationController) {
        self.navigationItem.leftBarButtonItem = [self.mainNavigationController menuBarButtonItem];
    }else{
        [EWUIUtil addTransparantNavigationBarToViewController:self withLeftItem:nil rightItem:nil];
        //self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    }
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MoreButton"] style:UIBarButtonItemStylePlain target:self action:@selector(more:)];

    if (!person.isMe && person.isOutDated) {
        DDLogInfo(@"Person %@ is outdated and needs refresh in background", person.name);
        [person refreshShallowWithCompletion:^(NSError *error){
			[self initData];
			[self initView];
        }];
	}else{
		[self initData];
		[self initView];
	}
}

- (void)initData {
    if (person) {
        //tasks = [[EWTaskStore sharedInstance] pastTasksByPerson:person];
        _activities = person.cachedInfo[kActivityCache];
        dates = _activities.allKeys;
        dates = [dates sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            NSInteger n1 = [obj1 integerValue];
            NSInteger n2 = [obj2 integerValue];
            if (n1>n2) {
                return NSOrderedDescending;
            } else if (n1<n2) {
                return NSOrderedAscending;
            } else {
                return NSOrderedSame;
            }
        }];
        
        //TODO: improve stats manager structure
        stats.person = person;
        
        if (!_photos) {
            _photos = [[NSMutableArray alloc] init];
            [_photos addObjectsFromArray:person.images];
        }
        
    }
}

//init data related view
- (void)initView {
    if (!person) return;
    //======= Person =======
    
    if (!person.isMe) {
        //other user
        if (person.isFriend) {
            [self.addFriend setImage:[UIImage imageNamed:@"FriendedIcon"] forState:UIControlStateNormal];
        }else if (person.friendWaiting){
            [self.addFriend setImage:[UIImage imageNamed:@"Add Friend Button"] forState:UIControlStateNormal];
        }else if(person.friendPending){
            [self.addFriend setImage:[UIImage imageNamed:@"Add Friend Button"] forState:UIControlStateNormal];
            self.addFriend.alpha = 0.2;
        }else{
            [self.addFriend setImage:[UIImage imageNamed:@"Add Friend Button"] forState:UIControlStateNormal];
        }
		//wake him/her up
		[self.wakeBtn setTitle:[NSString stringWithFormat:@"Wake %@ up", person.genderObjectiveCaseString] forState:UIControlStateNormal];
        
    }else{//self
        self.addFriend.hidden = YES;
		self.wakeBtn.hidden = YES;
    }
    [_tableView reloadData];
	
    //UI
    [self.picture setImage:person.profilePic forState:UIControlStateNormal];
    self.name.text = person.name;
    self.location.text = person.city;
    if (person.location && !person.isMe) {
        CLLocation *loc0 = [EWPerson me].location;
        CLLocation *loc1 = person.location;
        float distance = [loc0 distanceFromLocation:loc1]/1000;
        if (person.city) {
            self.location.text =[NSString stringWithFormat:@"%@ | ",person.city];
            self.location.text = [self.location.text stringByAppendingString:[NSString stringWithFormat:@"%1.f km",distance]];
        }
        else {
            self.location.text = [NSString stringWithFormat:@"%1.f km",distance];
        }
    }
    
    //statement
    NSString *str;
    if (person.statement) {
        str = person.statement;
    }
    else{
        str = @"No statement written";
    }
    self.statement.text = [NSString stringWithFormat:@"\"%@\"",str];
    
    //next alarm
    NSDate *time = [[EWAlarmManager sharedInstance] nextAlarmTimeForPerson:person];
	if (person.location) {
		NSTimeZone *userTimezone = [[APTimeZones sharedInstance] timeZoneWithLocation:person.location];
		NSDate *userTime = [time mt_inTimeZone:userTimezone];
		self.nextAlarm.text = [NSString stringWithFormat:@"Next Alarm: %@ (%@)", userTime.date2detailDateString, userTimezone.abbreviation];
	}else{
		self.nextAlarm.text = [NSString stringWithFormat:@"Next Alarm: %@", time.date2detailDateString];
	}
}


#pragma mark - UI Events
//this is the button next to profile pic
- (IBAction)extProfile:(id)sender{
    if (person.isMe) {
        //this button is hidden
        return;
    }else if (person.isFriend) {
        //is friend: show a check sign, do nothing
        return;
    } else if(person.friendWaiting){
        UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Accept friend", nil];
        [as showInView:self.view];
        return;
    }else if (person.friendPending){
        [[[UIAlertView alloc] initWithTitle:@"Friendship pending" message:@"You have already requested friendship to this person." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }else{
        UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add friend", nil];
        [as showInView:self.view];
    }
}

- (IBAction)close:(id)sender {
    if (self.navigationController) {
        if ([[self.navigationController viewControllers] objectAtIndex:0] == self || !self.navigationController) {
            [self.navigationController dismissBlurViewControllerWithCompletionHandler:NULL];
        }else{
            [self.navigationController popViewControllerAnimated:YES];
        }
    }else if (self.presentingViewController){
        [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    }
}

- (IBAction)login:(id)sender {
    
    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        //EWLogInViewController *loginVC = [[EWLogInViewController alloc] init];
        //[loginVC connect:nil];
        return;
        
    }
    
    NSMutableArray *urlArray = [person.images mutableCopy];
    
    if (!urlArray) {
        urlArray = [[NSMutableArray alloc] init];
    }
    
    [urlArray insertObject:person.profilePic atIndex:0];
    _photoBrower = [[IDMPhotoBrowser alloc] initWithPhotoURLs:urlArray];
    
    _photoBrower.delegate = self;
    
    if (person.isMe) {
        
        _photoBrower.actionButtonTitles = @[@"Uplode from library",@"Upload from taking photo",@"delete this image",@"Set this as profile"];
        
     
    }else{
        
        _photoBrower.displayActionButton = NO;
        
    }
    
    [self presentViewController:_photoBrower animated:YES completion:nil];
}


- (IBAction)more:(id)sender {
    UIActionSheet *sheet;
    if (person.isMe) {
        
        sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Close" destructiveButtonTitle:nil otherButtonTitles:@"Preference",@"Log out", nil];
#ifdef DEBUG
        [sheet addButtonWithTitle:@"Add friend"];
        [sheet addButtonWithTitle:@"Send Voice Greeting"];
#endif
    }else{
        //sheet.destructiveButtonIndex = 0;
        if (person.isFriend) {
            sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Close" destructiveButtonTitle:nil otherButtonTitles:@"Flag", @"Unfriend", @"Send Voice Greeting", @"Friend history", @"Block", nil];
        }else{
            
            sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Close" destructiveButtonTitle:nil otherButtonTitles:@"Add friend", @"Block", nil];
        }
    }
    
    [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

- (IBAction)photos:(id)sender{
	//show photo
}

- (IBAction)addFriend:(id)sender {
	//add friend
}

- (IBAction)wake:(id)sender {
	//wake
}

#pragma mark - Actionsheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
 
    
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    

    
    if ([title isEqualToString:@"Add friend"]) {
        
        //friend
        [[EWPerson me] requestFriend:person];
        [self.view showSuccessNotification:@"Request sent"];
        
    }else if ([title isEqualToString:@"Unfriend"]){
        
        //unfriend
        [[EWPerson me] unfriend:person];
        [self.view showSuccessNotification:@"Unfriended"];
        
    }else if ([title isEqualToString:@"Accept friend"]){
        
        [[EWPerson me] acceptFriend:person];
        [self.view showSuccessNotification:@"Added"];
        
    }else if ([title isEqualToString:@"Send Voice Greeting"]){
        [self sendVoice];
    }else if ([title isEqualToString:@"Block"]){
        //
    }else if ([title isEqualToString:@"Friendship history"]){
        //
    }else if ([title isEqualToString:@"Preference"]){
        EWSettingsViewController *prefView = [[EWSettingsViewController alloc] init];
        [self.navigationController pushViewController:prefView animated:YES];
        
    }else if ([title isEqualToString:@"Log out"]){
        [[EWAccountManager sharedInstance] logout];
//        EWLogInViewController *loginVC = [EWLogInViewController new];
//        [[UIApplication sharedApplication].delegate.window.rootViewController dismissBlurViewControllerWithCompletionHandler:^{
//            [[UIApplication sharedApplication].delegate.window.rootViewController presentViewControllerWithBlurBackground:loginVC];
//        }];
    }
    else if([title isEqualToString:@"Take Photo"])
    {
        UIActionSheet  *sheet;
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            
        {
            sheet  = [[UIActionSheet alloc] initWithTitle:@"Take Photo" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Cancel" otherButtonTitles:@"Take Photo",@"Select From Album", nil];
            
        }
        
        else {
            
            sheet = [[UIActionSheet alloc] initWithTitle:@"Take Photo" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Cancel" otherButtonTitles:@"Select From Album", nil];
            
        }
        
        sheet.tag = 255;
        
        [sheet showInView:self.view];
    }
        
    [self initView];
}

- (void)showSuccessNotification:(NSString *)alert{
    [self initView];
    [self.view showSuccessNotification:nil];
}

- (void)sendVoice{
    //EWRecordingViewController *controller = [[EWRecordingViewController alloc] initWithPerson:self.person];
    //[self.navigationController pushViewController:controller animated:YES];
}

@end



#pragma mark - TableView DataSource

@implementation EWPersonViewController(UITableView)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //alarm shown in sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return profileItemsArray.count;
}



//display cell
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    //if (tabView.selectedSegmentIndex == 0){
        //summary
        UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:profileCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:profileCellIdentifier];
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        cell.textLabel.text = [profileItemsArray objectAtIndex:indexPath.row];
        BOOL male = [person.gender isEqualToString:@"male"] ? YES:NO;
        
        
        switch (indexPath.row) {
            case 0://friends
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)person.friends.count];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            case 1:
            {
                NSArray *receivedMedias = person.receivedMedias.allObjects;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)receivedMedias.count];
                if (!person.isMe) {
                    cell.textLabel.text = male? @"People woke him up":@"People woke her up";
                }
            }
                break;
            case 2:
            {
                NSArray *medias = person.sentMedias.allObjects;
                cell.textLabel.text = male? @"People he woke up":@"People she woke up";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)medias.count];
                if (person.isMe) {
                    cell.textLabel.text = @"People I woke up";
                }
            }
                break;
            case 3://last seen, get it async
            {
                __block NSDate *date = person.updatedAt;
                if (!date) {
                    __block UIActivityIndicatorView *loader = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
                    cell.accessoryView = loader;
                    __block __weak UITableViewCell *blockCell = cell;
                    [loader startAnimating];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        date = person.parseObject.updatedAt;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            __strong UITableViewCell *strongCell = blockCell;
                            strongCell.accessoryView = nil;
                            [loader stopAnimating];
                            strongCell.detailTextLabel.text = [NSString stringWithFormat:@"%@ ago", date.timeElapsedString];
                        });
                    });
                }else{
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ ago", date.timeElapsedString];
                }
                
                break;
            }
            case 4://next task time
            {
                NSDate *date = [[EWAlarmManager sharedInstance] nextAlarmTimeForPerson:person];
                cell.detailTextLabel.text = [[date time2HMMSS] stringByAppendingString:[date date2am]];
                break;
            }
            case 5://wake-ability
            {
                cell.detailTextLabel.text =  stats.wakabilityStr;
                break;
            }
                
            case 6://average wake up time
            {
                cell.detailTextLabel.text =  stats.aveWakingLengthString;
            }
                
            default:
                break;
        }
        
        return cell;
//    }else if (tabView.selectedSegmentIndex == 1) {
//        //activities
//        
//        NSDictionary *activity = _activities[dates[indexPath.section]];
//        
//        UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:activitiyCellIdentifier];
//        
//        if (!cell) {
//            
//            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:activitiyCellIdentifier];
//            cell.textLabel.textColor = [UIColor lightGrayColor];
//            cell.selectionStyle = UITableViewCellSelectionStyleNone;
//            cell.textLabel.font = [UIFont systemFontOfSize:17];
//            
//        }
//        switch (indexPath.row) {
//            case 0:{
//                NSDate *time = activity[kActivityTime];
//                NSDate *completed = activity[kWokeTime];
//                if (!completed) {
//                    completed = [time timeByAddingMinutes:kMaxWakeTime];
//                }
//                float elapsed = [completed timeIntervalSinceDate:time];
//                if (completed && elapsed < kMaxWakeTime) {
//                    
//                    cell.textLabel.text = [NSString stringWithFormat:@"Woke up at %@ (%@)", completed.date2String, completed.timeElapsedString];
//                }
//                else
//                {
//                    cell.textLabel.numberOfLines = 0;
//                    cell.textLabel.text = [NSString stringWithFormat:@"Failed to wake up at %@",[time date2String]];
//
//                }
//                
//            }
//                break;
//                
//            case 1:{
//                NSArray *wokeBy = activity[kWokeBy];
//                if ([wokeBy isEqual: @0]) {
//                    wokeBy = [NSArray new];
//                }
//                cell.textLabel.text = [NSString stringWithFormat:@"Helped by %ld people", (unsigned long)[wokeBy count]];
//            }
//                break;
//            case 2:{
//                //advanced query
//                NSArray *wokeTo = activity[kWokeTo];
//                if ([wokeTo isEqual: @0]) {
//                    wokeTo = [NSArray new];
//                }
//                cell.textLabel.text = [NSString stringWithFormat:@"Woke up %lu people",(unsigned long)[wokeTo count]];
//
//                break;
//            }
//            default:
//                break;
//        }
//        
//        return cell;
//        
//    }
//    return nil;
    
}


//change cell bg color
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.backgroundColor = [UIColor clearColor];
}


//tap cell
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UIViewController *controller ;
    switch (indexPath.row) {
        case 0:
        {
            if (self.navigationController.viewControllers.count < kMaxPersonNavigationConnt && [person.friends count]>0) {
                EWFriendsViewController *tempVc= [[EWFriendsViewController alloc] initWithPerson:person];
                controller = tempVc;
                
                [self.navigationController pushViewController:controller animated:YES];
                return;
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"Accessory button tapped");
}


#pragma mark - USER LOGIN EVENT
- (void)userLoggedIn:(NSNotification *)note{
    if (self.person.isMe) {
        NSLog(@"PersonVC: user logged in, starting refresh");
        [self initData];
        [self initView];
    }
}

#pragma mark - IDMPhotoBrowserDelegate 

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didShowPhotoAtIndex:(NSUInteger)pageIndex
{
    //id <IDMPhoto> photo = [photoBrowser photoAtIndex:pageIndex];
    //NSLog(@"Did show photoBrowser with photo index: %lu, photo caption: %@", (unsigned long)pageIndex, photo.caption);
}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)pageIndex
{
    //id <IDMPhoto> photo = [photoBrowser photoAtIndex:pageIndex];
    //NSLog(@"Did dismiss photoBrowser with photo index: %lu, photo caption: %@", (unsigned long)pageIndex, photo.caption);
}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissActionSheetWithButtonIndex:(NSUInteger)buttonIndex photoIndex:(NSUInteger)photoIndex
{
    //id <IDMPhoto> photo = [photoBrowser photoAtIndex:photoIndex];
    //NSLog(@"Did dismiss actionSheet with photo index: %lu, photo caption: %@", (unsigned long)photoIndex, photo.caption);
    
    if (buttonIndex == 2) {
        
//        [photoBrowser deleteButtonPressed:nil];
        
        return ;
    }else if (buttonIndex == 3){
        UIImage *image = [photoBrowser photoAtIndex:photoIndex].underlyingImage;
        // upload my profile and move to first place
        NSString *fileUrl = [EWUtil uploadImageToParseREST:[EWPerson me].profilePic];
        [EWUtil deleteFileFromParseRESTwithURL:[EWPerson me].images[photoIndex]];
        [_photos insertObject:fileUrl atIndex:0];
        // set my profile
        [EWPerson me].profilePic = image;
        
        // delete original pic in array;
        [_photos removeObjectAtIndex:photoIndex];
        
//        [EWSync save];
        [photoBrowser.view showSuccessNotification:@"Success,Reopen To See"];
        
        return;
        
    }else{
        
        _imagePicker = [[GKImagePicker alloc] init];
        _imagePicker.cropSize = CGSizeMake(self.view.frame.size.height-100, self.view.frame.size.width-100);
        _imagePicker.delegate = self;
        _imagePicker.resizeableCropArea = YES;
        //imagePicker.imagePickerController.allowsEditing = YES;
        
        //determine upload from library or camera
        _imagePicker.imagePickerController.sourceType = buttonIndex;
        
        
        [photoBrowser presentViewController:_imagePicker.imagePickerController animated:YES completion:^{}];
    }
    

}
-(void)photoBrowser:(IDMPhotoBrowser *)photoBrowser detelePhotoAtIndexPath:(NSInteger)path
{
    [photoBrowser setInitialPageIndex:0];
    NSURL *url = [NSURL URLWithString:_photos[path-1]];
    [EWUtil deleteFileFromParseRESTwithURL:url];
    [_photos removeObjectAtIndex:path-1];
    
    [photoBrowser reloadData];
    
     [_photoBrower.view showSuccessNotification:@"Deleted"];
}


-(void)didDisAppearePhotoBrowser
{
    if (person.isMe) {
        // 结束时候保存一次
        [EWPerson me].images = _photos;
        [person save];
    }
}

#pragma mark - Upload Photo
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    [picker dismissViewControllerAnimated:YES completion:^(){
        [_photoBrower.view showLoopingWithTimeout:0];
        UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
        image = [EWUIUtil resizeImageWithImage:image scaledToSize:CGSizeMake(640, 960)];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSString *fileUrl = [EWUtil uploadImageToParseREST:image];
            
            [_photos addObject:fileUrl];
            
            [EWPerson me].images = _photos;
            //        [EWSync save];
            
            [EWUIUtil dismissHUDinView:_photoBrower.view];
            
            [_photoBrower.view showSuccessNotification:@"Uploaded"];
            
//            [_photoBrower addPhotoInBrowser:fileUrl];
        });
        
        
        
//        [UIView animateWithDuration:0 delay:0.6 options:UIViewAnimationOptionLayoutSubviews animations:^(){
//            
//        [_photoBrower dismissViewControllerAnimated:NO completion:nil];
//            
//        } completion:^(BOOL finished){[self login:nil];}];
      
        

    }];
//    imageView.image = image;
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
//    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
//    
//    
//    [manager POST:@"替换成你要访问的地址"parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
//        
//        
//        [formData appendPartWithFileData :imageData name:@"1" fileName:@"1.png" mimeType:@"image/jpeg"];
//        
//        
//    } success:^(AFHTTPRequestOperation *operation,id responseObject) {
//        NSLog(@"Success: %@", responseObject);
//        
//        
//    } failure:^(AFHTTPRequestOperation *operation,NSError *error) {
//        NSLog(@"Error: %@", error);
//        
//        
//    }];
    
   
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)imagePickerDidCancel:(GKImagePicker *)imagePicker
{
    [_imagePicker.imagePickerController dismissViewControllerAnimated:YES completion:^(){
    }];

}
-(void)imagePicker:(GKImagePicker *)imagePicker pickedImage:(UIImage *)image
{
	[_imagePicker.imagePickerController dismissViewControllerAnimated:YES completion:^(){
    
        [_photoBrower.view showLoopingWithTimeout:0];
		
        NSMutableString *urlString = [NSMutableString string];
        [urlString appendString:kParseUploadUrl];
        [urlString appendFormat:@"files/imagefile.jpg"];
        
        NSURL *url = [NSURL URLWithString:urlString];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request addValue:kParseApplicationId forHTTPHeaderField:@"X-Parse-Application-Id"];
        [request addValue:kParseRestAPIId forHTTPHeaderField:@"X-Parse-REST-API-Key"];
        [request addValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:UIImagePNGRepresentation(image)];
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        NSString *fileUrl = [httpResponse allHeaderFields][@"Location"];
        
        NSLog(@"Uploaded image with URL:%@",fileUrl);
		if (!fileUrl) {
			DDLogWarn(@"Failed to upload image and get address");
			[self.view showFailureNotification:@"Failed"];
			return;
		}
        
        [_photos addObject:fileUrl];
        
        [EWPerson me].images = _photos;
        [person save];
        
        [EWUIUtil dismissHUDinView:_photoBrower.view];
        
        [_photoBrower.view showSuccessNotification:@"Uploaded"];
        
//        [_photoBrower addPhotoInBrowser:fileUrl];
    }];
}
@end
