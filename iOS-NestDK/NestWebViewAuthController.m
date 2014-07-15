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

#import "NestWebViewAuthController.h"
#import "UIColor+Custom.h"
#import "Constants.h"

@interface NestWebViewAuthController () <UIWebViewDelegate>

@property (nonatomic, strong) NSString *authURL;
@property (nonatomic, strong) UIWebView *webView;

@end

#define QUESTION_MARK @"?"
#define SLASH @"/"
#define HASHTAG @"#"
#define EQUALS @"="
#define AMPERSAND @"&"
#define EMPTY_STRING @""

@implementation NestWebViewAuthController

/**
 * Load up the view controller with the given url.
 * @param URL the url you want to set the web view to (should be [[NestAuthManager sharedManager] authorizationURL]).
 * @param delegate An object that supports the NestWebViewAuthControllerDelegate
 */
- (id)initWithURL:(NSString *)URL delegate:(id <NestWebViewAuthControllerDelegate>)delegate
{
    if (self = [super init]) {
        self.authURL = URL;
        self.delegate = delegate;
    }
    return self;
}

/**
 * Setup the UI Elements.
 */
- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // Add a navbar to the top
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
    [self.view addSubview:navBar];
    
    // Add some items to the navigation bar
    UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"Connect with Nest"];
    navItem.leftBarButtonItem = bbi;
    [navBar pushNavigationItem:navItem animated:YES];
    
    // Add a uiwebview to take up the entire view (beneath the nav bar)
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 64, 320, self.view.frame.size.height - 64)];
    [self.webView setBackgroundColor:[UIColor nestBlue]];
    [self.webView setDelegate:self];
    [self.view addSubview:self.webView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set the title
    self.title = @"Connect With Nest";
    
    // Load the URL in the web view
    [self loadAuthURL];
    
}

/**
 * Load's the auth url in the web view.
 */
- (void)loadAuthURL
{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.authURL]];
    [self.webView loadRequest:request];
}

/**
 * Cancel button is hit.
 * @param sender The button that was hit.
 */
- (void)cancel:(UIButton *)sender
{
    [self.delegate cancelButtonHit:sender];
}

#pragma mark UIWebView Delegate Methods

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

/**
 * Intercept the requests to get the authorization code.
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];
    NSURL *redirectURL = [[NSURL alloc] initWithString:RedirectURL];
        
	if ([[url host] isEqualToString:[redirectURL host]]) {
		
        // Clean the string
		NSString *urlResources = [url resourceSpecifier];
		urlResources = [urlResources stringByReplacingOccurrencesOfString:QUESTION_MARK withString:EMPTY_STRING];
		urlResources = [urlResources stringByReplacingOccurrencesOfString:HASHTAG withString:EMPTY_STRING];
		
		// Seperate the /
		NSArray *urlResourcesArray = [urlResources componentsSeparatedByString:SLASH];
		
		// Get all the parameters after /
		NSString *urlParamaters = [urlResourcesArray objectAtIndex:([urlResourcesArray count]-1)];
		
		// Separate the &
		NSArray *urlParamatersArray = [urlParamaters componentsSeparatedByString:AMPERSAND];
        NSString *keyValue = [urlParamatersArray lastObject];
        NSArray *keyValueArray = [keyValue componentsSeparatedByString:EQUALS];
        
        // We found the code
        if([[keyValueArray objectAtIndex:(0)] isEqualToString:@"code"]) {
            
            // Send it to the delegate
            [self.delegate foundAuthorizationCode:[keyValueArray objectAtIndex:1]];
            
		} else {
			NSLog(@"Error retrieving the authorization code.");
		}

		return NO;
	}
	
	return YES;
}




@end
