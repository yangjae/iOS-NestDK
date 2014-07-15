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

#import "NestConnectViewController.h"
#import "UIColor+Custom.h"
#import "NestAuthManager.h"
#import "NestWebViewAuthController.h"
#import "NestControlsViewController.h"

@interface NestConnectViewController () <NestWebViewAuthControllerDelegate>

@property (nonatomic, strong) UIButton *nestConnectButton;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NestWebViewAuthController *nestWebViewAuthController;
@property (nonatomic, strong) NSTimer *checkTokenTimer;

@end

@implementation NestConnectViewController

#pragma mark View Setup Methods

/**
 * Setup the view.
 */
- (void)loadView
{
    // Setup the view itself
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // Add a scrollview just to feel a little nicer
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.scrollView setFrame:CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
    [self.scrollView setBounces:YES];
    [self.scrollView setAlwaysBounceVertical:YES];
    [self.view addSubview:self.scrollView];
    
    // Add the button the scrollview
    self.nestConnectButton = [self createNestConnectButton];
    [self.nestConnectButton setFrame:CGRectMake(35, CGRectGetMidY(self.scrollView.bounds) - self.nestConnectButton.frame.size.height, self.nestConnectButton.frame.size.width, self.nestConnectButton.frame.size.height)];
    [self.scrollView addSubview:self.nestConnectButton];
}

/**
 * Create the nest connect button.
 * @return The new nest connect button.
 */
- (UIButton *)createNestConnectButton
{
    UIButton *nestConnectButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 250, 130)];
    [nestConnectButton setTitleColor:[UIColor nestBlue] forState:UIControlStateNormal];
    [nestConnectButton setTitleColor:[UIColor nestBlueSelected] forState:UIControlStateHighlighted];
    
    [nestConnectButton setTitle:@"Connect with your nest account!" forState:UIControlStateNormal];
    
    [nestConnectButton.titleLabel setNumberOfLines:4];
    [nestConnectButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [nestConnectButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0.0, 00.0)];
    
    [nestConnectButton.layer setBorderColor:[UIColor nestBlue].CGColor];
    [nestConnectButton.layer setCornerRadius:8.f];
    [nestConnectButton.layer setBorderWidth:3.f];
    [nestConnectButton.layer setMasksToBounds:YES];
    
    [nestConnectButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:33]];
    [nestConnectButton addTarget:self action:@selector(nestConnectButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    return nestConnectButton;
}

/**
 * Called when the nest connect button is hit.
 * Presents the web auth URL.
 * @param sender The button that sent the message.
 */
- (void)nestConnectButtonHit:(UIButton *)sender
{
    // First we need to create the authorization_code URL
    NSString *authorizationCodeURL = [[NestAuthManager sharedManager] authorizationURL];
    [self presentWebViewWithURL:authorizationCodeURL];
}


/**
 * Present the web view with the given url.
 * @param url The url you wish to have the web view load.
 */
- (void)presentWebViewWithURL:(NSString *)url
{
    // Present modally the web view controller
    self.nestWebViewAuthController = [[NestWebViewAuthController alloc] initWithURL:url delegate:self];
    [self presentViewController:self.nestWebViewAuthController animated:YES completion:^{}];
}

/**
 * Checks periodically every second after the authorization code is received to
 * see if it has been exchanged for the access token.
 * @param The timer that sent the message.
 */
- (void)checkForAccessToken:(NSTimer *)sender
{
    if ([[NestAuthManager sharedManager] isValidSession]) {
        NestControlsViewController *ncvc = [[NestControlsViewController alloc] init];
        [self.navigationController setViewControllers:[NSArray arrayWithObject:ncvc] animated:YES];
        [self invalidateTimer];
    }
}

#pragma mark ViewController Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set the nav bar title
    self.title = @"Welcome";
    
    [self.nestConnectButton setEnabled:YES];
}

#pragma mark NestWebViewControllerDelegate Methods

/**
 * Called from the NestWebViewControllerDelegate
 * if the user successfully finds the authorization code.
 * @param authorizationCode The authorization code NestAuthManager found.
 */
- (void)foundAuthorizationCode:(NSString *)authorizationCode
{
    [self.nestWebViewAuthController dismissViewControllerAnimated:YES completion:^{}];
    
    // Save the authorization code
    [[NestAuthManager sharedManager] setAuthorizationCode:authorizationCode];
    
    // Check for the access token every second and once we have it leave this page
    [self setupcheckTokenTimer];
    
    // Set the button to disabled
    [self.nestConnectButton setEnabled:NO];
    [self.nestConnectButton setTitle:@"Loading..." forState:UIControlStateNormal];
}

/**
 * Called from the NestWebViewControllerDelegate if the user hits cancel
 * @param sender The button that sent the message.
 */
- (void)cancelButtonHit:(UIButton *)sender
{
    [self.nestWebViewAuthController dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - Private Methods

/**
 * Invalidate the check token timer
 */
- (void)invalidateTimer
{
    if ([self.checkTokenTimer isValid]) {
        [self.checkTokenTimer invalidate];
        self.checkTokenTimer = nil;
    }
}

/**
 * Setup the checkTokenTimer
 */
- (void)setupcheckTokenTimer
{
    [self invalidateTimer];
    self.checkTokenTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(checkForAccessToken:) userInfo:nil repeats:YES];
}

@end
