//
//  PFLoginViewController.h
//  Pandemos
//
//  Created by Michael Sevy on 12/16/15.
//  Copyright © 2015 Michael Sevy. All rights reserved.
//

#import "ViewController.h"
#import <Parse/PFUser.h>


@interface PFLoginViewController : ViewController

@property (strong, nonatomic) PFUser *pfUser;

@end