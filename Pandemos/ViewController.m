//
//  ViewController.m
//  Pandemos
//
//  Created by Michael Sevy on 12/13/15.
//  Copyright © 2015 Michael Sevy. All rights reserved.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>
#import <Bolts/BFTask.h>
#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import <FBSDKLoginKit/FBSDKLoginManager.h>
#import <ParseFacebookUtilsV4.h>
#import <Parse/PFConstants.h>
#import <Parse/PFUser.h>
#import <FBSDKGraphRequest.h>
#import <FBSDKGraphRequestConnection.h>
#import "UserData.h"
#import <Parse/Parse.h>
#import "UserData.h"
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "MessagingViewController.h"
#import <MessageUI/MessageUI.h>


@interface ViewController ()<FBSDKGraphRequestConnectionDelegate,
UIGestureRecognizerDelegate,
UINavigationControllerDelegate,
CLLocationManagerDelegate,
MFMailComposeViewControllerDelegate>

//View elemets
@property (weak, nonatomic) IBOutlet UIImageView *userImage;
@property (weak, nonatomic) IBOutlet UIButton *greenButton;
@property (weak, nonatomic) IBOutlet UIButton *redButton;
@property (weak, nonatomic) IBOutlet UILabel *nameAndAge;
@property (weak, nonatomic) IBOutlet UILabel *jobLabel;
@property (weak, nonatomic) IBOutlet UILabel *educationLabel;
@property (weak, nonatomic) IBOutlet UIView *userInfoView;
@property (weak, nonatomic) IBOutlet UIButton *image1Indicator;
@property (weak, nonatomic) IBOutlet UIButton *image2Indicator;
@property (weak, nonatomic) IBOutlet UIButton *image3Indicator;
@property (weak, nonatomic) IBOutlet UIButton *image4Indicator;
@property (weak, nonatomic) IBOutlet UIButton *image5Indicator;
@property (weak, nonatomic) IBOutlet UIButton *image6Indicator;
@property (weak, nonatomic) IBOutlet UIView *fullDescView;
@property (weak, nonatomic) IBOutlet UILabel *fullDescNameAndAge;
@property (weak, nonatomic) IBOutlet UILabel *fullAboutMe;
@property (weak, nonatomic) IBOutlet UILabel *fullMilesAway;

@property (strong, nonatomic) PFUser *currentUser;
@property (strong, nonatomic) NSString *leadImage;
@property (strong, nonatomic) NSData *leadImageData;
@property (strong, nonatomic) NSMutableArray *imageArray;
@property (strong, nonatomic) NSString *nameAndAgeGlobal;

//location Properties
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (strong, nonatomic) CLGeocoder *geoCoded;
//Matching Engine Identifiers
@property (strong, nonatomic) NSString *userSexPref;
@property (strong, nonatomic) NSString *minAge;
@property (strong, nonatomic) NSString *maxAge;
@property int milesFromUserLocation;
@property (strong, nonatomic) PFGeoPoint *pfGeoCoded;
@property long count;

//passed Objects array to the stack of users
@property (strong, nonatomic) NSArray *objectsArray;
@property long matchedUsersCount;





@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.currentUser = [PFUser currentUser];
    NSString *fullName = [self.currentUser objectForKey:@"fullName"];
    NSLog(@"current user VDL: %@", fullName);

    self.fullDescView.hidden = YES;

    self.count = 1;
    self.matchedUsersCount = 0;
    self.imageArray = [NSMutableArray new];
    self.navigationItem.title = @"Fmf";
    self.navigationController.navigationBar.barTintColor = [UserData rubyRed];
    [self.navigationItem.rightBarButtonItem setTitle:@"Messages"];


    //location object
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    //request permission and update locaiton
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;


    //other view elements setup
    [self setUpButtons:self.image1Indicator];
    [self setUpButtons:self.image2Indicator];
    [self setUpButtons:self.image3Indicator];
    [self setUpButtons:self.image4Indicator];
    [self setUpButtons:self.image5Indicator];
    [self setUpButtons:self.image6Indicator];

    [self currentImage:self.count];

    self.greenButton.transform = CGAffineTransformMakeRotation(M_PI / 180 * 10);
    self.redButton.transform = CGAffineTransformMakeRotation(M_PI / 180 * -10);
    self.greenButton.layer.cornerRadius = 20;
    self.redButton.layer.cornerRadius = 20;
    //main image round edges
    self.userImage.layer.cornerRadius = 8;
    self.userImage.clipsToBounds = YES;

    [self.view insertSubview:self.userInfoView aboveSubview:self.userImage];
    self.userInfoView.layer.cornerRadius = 10;

    //swipe gestures-- up
    [self.userImage setUserInteractionEnabled:YES];
    UISwipeGestureRecognizer *swipeGestureUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self  action:@selector(swipeGestureUp:)];
    [swipeGestureUp setDelegate:self];
    swipeGestureUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.userImage addGestureRecognizer:swipeGestureUp];
    //down
    UISwipeGestureRecognizer *swipeGestureDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self  action:@selector(swipeGestureDown:)];
    [swipeGestureDown setDelegate:self];
    swipeGestureDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.userImage addGestureRecognizer:swipeGestureDown];
    //right
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self  action:@selector(onSwipeRight:)];
    [swipeRight setDelegate:self];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.userImage addGestureRecognizer:swipeRight];
    //left
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self  action:@selector(onSwipeLeft:)];
    [swipeLeft setDelegate:self];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.userImage addGestureRecognizer:swipeLeft];


}





-(void)viewDidAppear:(BOOL)animated{
    //NSLog(@"current user view did appear %@", self.currentUser);
    if (!self.currentUser) {
        NSLog(@"no user currently logged in");
        //[self performSegueWithIdentifier:@"NoUser" sender:nil];
    } else {
        //get the current users data
        self.currentUser = [PFUser currentUser];
        NSString *fullName = [self.currentUser objectForKey:@"fullName"];
        //NSString *age = [self.currentUser objectForKey:@"userAge"];
        NSString *sex = [self.currentUser objectForKey:@"gender"];
        PFGeoPoint *geo = [self.currentUser objectForKey:@"GeoCode"];
        NSString *sexPref = [self.currentUser objectForKey:@"sexPref"];


        //for matching: SexPref min and max age user is intersted in and Location of user/miles around user
        self.userSexPref = sexPref;

        self.minAge = [self.currentUser objectForKey:@"minAge"];
        self.maxAge = [self.currentUser objectForKey:@"maxAge"];
        NSString *milesFromUserLoc = [self.currentUser objectForKey:@"milesAway"];
        self.milesFromUserLocation = [milesFromUserLoc intValue];
        //update users age everytime they signin and re-save that age in Parse for matching purpposes
        NSString *userBirthday = [self.currentUser objectForKey:@"birthday"];
       // NSLog(@"user bDay: %@", userBirthday);
        NSString *age = [self ageString:userBirthday];
        [self.currentUser setObject:age forKey:@"userAge"];

        //relation
        PFRelation *rela = [self.currentUser objectForKey:@"matchNotConfirmed"];

        NSLog(@"current user View Controller: %@\nAge: %@\nSex: %@\nLocation: %@\nMilesRange:%zd\nInterest: %@\nMin Age Interst: %@\nMax: %@\nRelations:%@", fullName, age, sex, geo, self.milesFromUserLocation, sexPref, self.minAge, self.maxAge, rela);

        //location
        NSLog(@"current location VDA: %@", self.currentLocation);

        double latitude = self.locationManager.location.coordinate.latitude;
        double longitude = self.locationManager.location.coordinate.longitude;
        //NSLog(@"view did appear: %f & long: %f", latitude, longitude);

        //save lat and long in a PFGeoCode Object and save to User in Parse
        self.pfGeoCoded = [PFGeoPoint geoPointWithLatitude:latitude longitude:longitude];
        [self.currentUser setObject:self.pfGeoCoded forKey:@"GeoCode"];
            //NSLog(@"saved PFGeoPoint as: %@", self.pfGeoCoded);
            //save age and location objects
        [self.currentUser saveInBackground];





        //Matching Engine
    PFQuery *query = [PFUser query];
    //check to only add users that meet criterion of above current user


        //Both sexes
        if ([self.userSexPref containsString:@"male female"]) {
        //Preference for Both Sexes
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(!error){
            //NSLog(@"pfquery-- user objects: %zd", [objects count]);
            [self checkAndGetImages:objects user:0];
        } else{
            NSLog(@"error: %@", error);
        }
  }];


        //Preference for Males
        } else if ([self.userSexPref isEqualToString:@"male"]){
            //set up query constraints
            [query whereKey:@"gender" hasPrefix:@"m"];
            //[query whereKey:@"ageMin" greaterThanOrEqualTo:self.minAge];
            //[query whereKey:@"ageMax" lessThanOrEqualTo:self.maxAge];
            //NSLog(@"Male Pref Between: %@ and %@", self.minAge, self.maxAge);
            //[query whereKey:@"GeoCode" nearGeoPoint:self.pfGeoCoded withinMiles:self.milesFromUserLocation];

            //run query
            [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (!error) {
                    long objectCount = [objects count];
                   // NSLog(@"male pref query: %zd results", objectCount);
                    self.objectsArray = objects;

                    if (objectCount == 1) {

                        [self checkAndGetImages:objects user:0];
                        [self checkAndGetUserData:objects user:0];
                    } else if (objectCount == 2){

                        [self checkAndGetImages:objects user:0];
                        [self checkAndGetUserData:objects user:0];

                        PFUser *user1 =  [objects objectAtIndex:0];
                        PFUser *user2 =  [objects objectAtIndex:1];
                        NSLog(@"matches: %@\n%@\n", [user1  objectForKey:@"fullName"], [user2 objectForKey:@"fullName"]);

                    } else if (objectCount == 3){
                        [self checkAndGetImages:objects user:0];
                        [self checkAndGetUserData:objects user:0];

                        PFUser *user1 =  [objects objectAtIndex:0];
                        PFUser *user2 =  [objects objectAtIndex:1];
                        PFUser *user3 =  [objects objectAtIndex:2];
                        NSLog(@"matches: %@\n%@\n%@", [user1  objectForKey:@"fullName"], [user2 objectForKey:@"fullName"], [user3 objectForKey:@"fullName"]);
                    }
                } else{
                    NSLog(@"error: %@", error);
                }
            }];



            //Preference for Females
            } else{
                [query whereKey:@"gender" hasPrefix:@"f"];
                [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (!error) {
                        NSLog(@"female pref query: %zd results", [objects count]);
                        [self checkAndGetImages:objects user:0];
                        [self checkAndGetUserData:objects user:0];

                    }
                }];
            }
        }
    }

#pragma mark -- CLLocation delegate methods
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations   {
    CLLocation *currentLocation = [locations firstObject];
    NSLog(@"did update locations fist object: %@", currentLocation);

    [self.locationManager stopUpdatingLocation];

}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    //NSLog(@"location manager failed: %@", error);
}


#pragma mark -- Swipe Gestures
//SwipeUp
- (IBAction)swipeGestureUp:(UISwipeGestureRecognizer *)sender {

    UISwipeGestureRecognizerDirection direction = [(UISwipeGestureRecognizer *) sender direction];
    if (direction == UISwipeGestureRecognizerDirectionUp) {
        NSLog(@"swipe up");
        //add animation
        [UIView transitionWithView:self.userImage duration:0.2 options:UIViewAnimationOptionTransitionCurlUp animations:^{
            if (self.count == self.imageArray.count - 1 ) {

                self.userImage.image = [UIImage imageWithData:[self imageData:[self.imageArray objectAtIndex:self.count]]];
                NSLog(@"last image");
                [self currentImage:self.count];

                [self lastObjectCallDesciptionView];

            } else{

                self.count++;
                self.userImage.image = [UIImage imageWithData:[self imageData:[self.imageArray objectAtIndex:self.count]]];
                [self currentImage:self.count];
                self.fullDescView.hidden = YES;

            }
        } completion:^(BOOL finished) {
        }];
    }
}

//SwipeDown
- (IBAction)swipeGestureDown:(UISwipeGestureRecognizer *)sender {

    UISwipeGestureRecognizerDirection direction = [(UISwipeGestureRecognizer *) sender direction];
    if (direction == UISwipeGestureRecognizerDirectionDown) {
        NSLog(@"swipe down");

        [UIView transitionWithView:self.userImage duration:0.2 options:UIViewAnimationOptionTransitionCurlDown animations:^{
            if (self.count == self.imageArray.count - self.imageArray.count) {
                self.userImage.image = [UIImage imageWithData:[self imageData:[self.imageArray objectAtIndex:self.count]]];
                NSLog(@"first image");
                NSLog(@"count: %zd", self.count);
                [self currentImage:self.count];

                self.fullDescView.hidden = YES;

            } else{

                self.count--;
                self.userImage.image = [UIImage imageWithData:[self imageData:[self.imageArray objectAtIndex:self.count]]];
                [self currentImage:self.count];
                NSLog(@"count: %zd", self.count);

                self.fullDescView.hidden = YES;

            }
        } completion:^(BOOL finished) {
            NSLog(@"animated");
        }];
    }
}





//Swipe Right or Left
- (IBAction)onSwipeRight:(UISwipeGestureRecognizer *)sender {

    NSLog(@"swipe right");
    self.count = 1;
    [self.imageArray removeAllObjects];

    //Set relational data to accepted throw a notification to user skip to next user
    if (self.matchedUsersCount == self.objectsArray.count - 1) {

        NSLog(@"last match in queue");
        //bring up the new user Data
        [self checkAndGetImages:self.objectsArray user:self.matchedUsersCount];
        [self checkAndGetUserData:self.objectsArray user:self.matchedUsersCount];

        //match the user in Parse
        PFUser *currentMatchUser =  [self.objectsArray objectAtIndex:self.matchedUsersCount -1];
        PFRelation *matchWithoutConfirm = [self.currentUser relationForKey:@"matchNotConfirmed"];
        [matchWithoutConfirm addObject:currentMatchUser];
        NSString *fullName = [self.currentUser objectForKey:@"fullName"];
        NSString *fullNameOfCurrentMatch = [currentMatchUser objectForKey:@"fullName"];
        NSLog(@"It's Match Between: %@ and %@",fullName, fullNameOfCurrentMatch);

        [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (error) {
                NSLog(@"error: %@", error);
            }
        }];


    } else{
            //view elements, shows next user
            self.matchedUsersCount++;
            [self checkAndGetImages:self.objectsArray user:self.matchedUsersCount];
            [self checkAndGetUserData:self.objectsArray user:self.matchedUsersCount];

            //assign a relationship between current user and swiped right user
            PFUser *currentMatchUser =  [self.objectsArray objectAtIndex:self.matchedUsersCount -1];
            PFRelation *matchWithoutConfirm = [self.currentUser relationForKey:@"matchNotConfirmed"];
            [matchWithoutConfirm addObject:currentMatchUser];
            //for logging purposes
            NSString *fullName = [self.currentUser objectForKey:@"fullName"];
            NSString *fullNameOfCurrentMatch = [currentMatchUser objectForKey:@"fullName"];
            NSLog(@"It's Match Between: %@ and %@",fullName, fullNameOfCurrentMatch);

            //[self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {

            //email approval
            [self sendEmailForApproval];
            
            //if (error) {
              //  NSLog(@"error saving relation: %@", error);
           // }
        //}];
    }
}

- (IBAction)onSwipeLeft:(UISwipeGestureRecognizer *)sender {

    NSLog(@"swipe Left, no match");
    self.matchedUsersCount++;
    [self checkAndGetImages:self.objectsArray user:self.matchedUsersCount];
    [self checkAndGetUserData:self.objectsArray user:self.matchedUsersCount];

    //save rejected relationship on Parse
    PFUser *currentMatchUser =  [self.objectsArray objectAtIndex:self.matchedUsersCount -1];
    PFRelation *noMatch = [self.currentUser relationForKey:@"NoMatch"];
    [noMatch addObject:currentMatchUser];
    //for logging
    NSString *fullName = [self.currentUser objectForKey:@"fullName"];
    NSString *fullNameOfCurrentMatch = [currentMatchUser objectForKey:@"fullName"];
    NSLog(@"No Match between: %@ and %@",fullName, fullNameOfCurrentMatch);

    [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error: %@", error);
        }
    }];




}


- (IBAction)onYesButton:(UIButton *)sender {
}




- (IBAction)onXButton:(UIButton *)sender {
}



#pragma mark -- Segue Methods
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"Messages"]) {
        NSLog(@"messages iden");
        MessagingViewController *mvc = segue.destinationViewController;

        mvc.pfUser = self.currentUser;

    } else if ([segue.identifier isEqualToString:@"Settings"])  {

        ProfileViewController *pvc = segue.destinationViewController;
        pvc.userFromViewController = self.currentUser;
    }
}

#pragma mark -- helpers
-(void)checkAndGetImages:(NSArray *)pfObjects user:(NSUInteger) userNumber    {
    PFUser *userForImages =  [pfObjects objectAtIndex:userNumber];
    NSString *image1 = [userForImages objectForKey:@"image1"];
    NSString *image2 = [userForImages objectForKey:@"image2"];
    NSString *image3 = [userForImages objectForKey:@"image3"];
    NSString *image4 = [userForImages objectForKey:@"image4"];
    NSString *image5 = [userForImages objectForKey:@"image5"];
    NSString *image6 = [userForImages objectForKey:@"image6"];

    if (image1) {
        [self.imageArray addObject:image1];
        self.userImage.image = [UIImage imageWithData:[self imageData:image1]];
    }if (image2) {
        [self.imageArray addObject:image2];
    } if (image3) {
        [self.imageArray addObject:image3];
    } if (image4) {
        [self.imageArray addObject:image4];
    } if (image5) {
        [self.imageArray addObject:image5];
    } if (image6) {
        [self.imageArray addObject:image6];
    }
}

-(void)checkAndGetUserData:(NSArray *)pfObjects user:(NSUInteger)userNumber{
    PFUser *userForData = [pfObjects objectAtIndex:userNumber];
    NSString *firstName = [userForData objectForKey:@"firstName"];
    NSString *work = [userForData objectForKey:@"work"];
    NSString *school = [userForData objectForKey:@"scool"];
    NSString *bday = [userForData objectForKey:@"birthday"];
//    NSString *userDesc = [userForData objectForKey:@"desc"];

    self.nameAndAge.text = [NSString stringWithFormat:@"%@, %@", firstName, [self ageString:bday]];
    self.nameAndAgeGlobal = [NSString stringWithFormat:@"%@, %@", firstName, [self ageString:bday]];
    self.educationLabel.text = school;
    self.jobLabel.text = work;

    //NSLog(@"%@\n%@\n%@", firstName, school, work);

}

-(NSString *)ageString:(NSString *)bDayString   {

    NSString *bday = bDayString;
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"MM/DD/YYY"];

    NSDate *birthdayDate = [formatter dateFromString:bday];
    NSDate *nowDate = [NSDate date];
    [formatter stringFromDate:nowDate];
    //NSString *nowString = [NSString stringWithFormat:@"%@", nowDate];
    //NSLog(@"current date string: %@", nowString);
    NSDateComponents *ageCom = [[NSCalendar currentCalendar]components:NSCalendarUnitYear fromDate:birthdayDate toDate:nowDate options:0];
    NSInteger ageInt = [ageCom year];
    NSString *ageString = [NSString stringWithFormat:@"%zd", ageInt];
    return ageString;
}

-(NSData *)imageData:(NSString *)imageString{
    NSURL *url = [NSURL URLWithString:imageString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    return data;
}

-(void)currentImage:(long)matchedCount{
    switch (matchedCount) {
        case 1:
            self.image1Indicator.backgroundColor = [UserData rubyRed];
            self.image2Indicator.backgroundColor = nil;
            self.image3Indicator.backgroundColor = nil;
            self.image4Indicator.backgroundColor = nil;
            self.image5Indicator.backgroundColor = nil;
            self.image6Indicator.backgroundColor = nil;
            break;
        case 2:
            self.image1Indicator.backgroundColor = nil;
            self.image2Indicator.backgroundColor = [UserData rubyRed];
            self.image3Indicator.backgroundColor = nil;
            self.image4Indicator.backgroundColor = nil;
            self.image5Indicator.backgroundColor = nil;
            self.image6Indicator.backgroundColor = nil;
            break;
        case 3:
            self.image1Indicator.backgroundColor = nil;
            self.image2Indicator.backgroundColor = nil;
            self.image3Indicator.backgroundColor = [UserData rubyRed];
            self.image4Indicator.backgroundColor = nil;
            self.image5Indicator.backgroundColor = nil;
            self.image6Indicator.backgroundColor = nil;
            break;
        case 4:
            self.image1Indicator.backgroundColor = nil;
            self.image2Indicator.backgroundColor = nil;
            self.image3Indicator.backgroundColor = nil;
            self.image4Indicator.backgroundColor = [UserData rubyRed];
            self.image5Indicator.backgroundColor = nil;
            self.image6Indicator.backgroundColor = nil;
            break;
        case 5:
            self.image1Indicator.backgroundColor = nil;
            self.image2Indicator.backgroundColor = nil;
            self.image3Indicator.backgroundColor = nil;
            self.image4Indicator.backgroundColor = nil;
            self.image5Indicator.backgroundColor = [UserData rubyRed];
            self.image6Indicator.backgroundColor = nil;
            break;
        case 6:
            self.image1Indicator.backgroundColor = nil;
            self.image2Indicator.backgroundColor = nil;
            self.image3Indicator.backgroundColor = nil;
            self.image4Indicator.backgroundColor = nil;
            self.image5Indicator.backgroundColor = nil;
            self.image6Indicator.backgroundColor = [UserData rubyRed];
            break;
        default:
            NSLog(@"image beyond bounds");
            break;
    }
}

-(void)lastObjectCallDesciptionView{

    self.fullDescView.hidden = NO;
    self.fullDescView.layer.cornerRadius = 10;
    self.fullAboutMe.text = @"dude, I'm cool";
    self.fullDescNameAndAge.text = self.nameAndAgeGlobal;
    self.fullMilesAway.text = @"2.5 miles away";

}
//round corners, change button colors
-(void)setUpButtons:(UIButton *)button{

    button.layer.cornerRadius = 15;
    button.clipsToBounds = YES;
    [button.layer setBorderWidth:1.0];
    [button.layer setBorderColor:[UserData uclaBlue].CGColor];
}

-(void) sendEmailForApproval{

    NSString *emailTitle = @"Feedback";
    NSString *messageBody = @"<h1>Matched User's Name</h1>";
    NSArray *reciepents = [NSArray arrayWithObject:@"michealsevy@gmail.com"];
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc]init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:YES];
    [mc setToRecipients:reciepents];

    [self presentViewController:mc animated:YES completion:nil];


}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }

    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}
    //old code


//did update location delegate method
//    double latitude = self.locationManager.location.coordinate.latitude;
//    double longitude = self.locationManager.location.coordinate.longitude;
//    NSLog(@"view did load lat: %f & long: %f", latitude, longitude);
//
//    //save lat and long in a PFGeoCode Object and save to User in Parse
//    self.pfGeoCoded = [PFGeoPoint geoPointWithLatitude:latitude longitude:longitude];
//    [self.currentUser setObject:self.pfGeoCoded forKey:@"GeoCode"];
//    [self.currentUser saveInBackground];
//    NSLog(@"PFGeoCode: %@", self.pfGeoCoded);
//
//    //get city and state of local location object
//    CLGeocoder *geoCoder = [CLGeocoder new];
//    [geoCoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
//        if (error) {
//            NSLog(@"error: %@", error);
//        } else {
//            CLPlacemark *placemark = [placemarks firstObject];
//            NSLog(@"placemark city: %@", placemark.locality);
//        }
//    }];
//
//





@end








