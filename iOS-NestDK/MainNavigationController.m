/**
 *  Copyright 2014 Nest Labs Inc. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#import "MainNavigationController.h"
#import "NestConnectViewController.h"
#import "NestAuthManager.h"
#import "NestControlsViewController.h"

@interface MainNavigationController ()

@end

@implementation MainNavigationController

/*
 * Set the main view controller of the navigation controller
 * depending on whether or not the Nest session is valid.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // If it isn't a valid session -- bring the user to the nest connect screen
    if (![[NestAuthManager sharedManager] isValidSession]) {
        NestConnectViewController *nestConnectViewController = [[NestConnectViewController alloc] init];
        self.viewControllers = [NSArray arrayWithObject:nestConnectViewController];
    } else {
        NestControlsViewController *nestControlsViewController = [[NestControlsViewController alloc] init];
        self.viewControllers = [NSArray arrayWithObject:nestControlsViewController];
    }
}


@end
