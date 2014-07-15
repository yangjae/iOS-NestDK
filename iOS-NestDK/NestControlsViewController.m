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

#import "NestControlsViewController.h"
#import "ThermostatView.h"
#import "NestThermostatManager.h"
#import "NestStructureManager.h"
#import "UIColor+Custom.h"

@interface NestControlsViewController () <NestThermostatManagerDelegate, NestStructureManagerDelegate, ThermostatViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) ThermostatView *thermostatView;
@property (nonatomic, strong) Thermostat *currentThermostat;

@property (nonatomic) NSInteger numberOfThermostats;
@property (nonatomic) NSInteger currentThermostatIndex;

@property (nonatomic, strong) NestThermostatManager *nestThermostatManager;
@property (nonatomic, strong) NestStructureManager *nestStructureManager;

@property (nonatomic, strong) NSDictionary *currentStructure;

@property (nonatomic, strong) UILabel *statusLabel;

@end

@implementation NestControlsViewController

#pragma mark - View Configuration Methods

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // Add the scroll view
    [self setupScrollView];

    // Add the ThermostatView
    [self setupThermostatView];
    
    // Add the tap to switch label
    [self addTapToSwitchLabel];
}

/**
 * Adds the tap to switch label.
 */
- (void)addTapToSwitchLabel
{
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake( 10, CGRectGetMidY(self.scrollView.frame), 300, 130)];
    [self.statusLabel setText:@""];
    [self.statusLabel setTextAlignment:NSTextAlignmentCenter];
    [self.statusLabel setTextColor:[UIColor nestBlue]];
    [self.statusLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:22.f]];
    [self.scrollView addSubview:self.statusLabel];
}

/**
 * Sets up the scroll view.
 */
- (void)setupScrollView
{
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.scrollView setBounces:YES];
    [self.scrollView setAlwaysBounceVertical:YES];
    [self.scrollView setFrame:CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
    [self.view addSubview:self.scrollView];
}


/**
 * Sets up the thermostat view.
 */
- (void)setupThermostatView
{
    self.thermostatView = [[ThermostatView alloc] initWithFrame:CGRectMake(10, 10, 300, 195)];
    [self.thermostatView setDelegate:self];
    [self.scrollView addSubview:self.thermostatView];
}

#pragma mark - View Controller Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Set the title of the nav bar
    self.title = @"Nest Controls";
    
    // Set the current thermostat index to 0
    self.currentThermostatIndex = 0;
    
    // Get the initial structure
    self.nestStructureManager = [[NestStructureManager alloc] init];
    [self.nestStructureManager setDelegate:self];
    [self.nestStructureManager initialize];
    
    self.nestThermostatManager = [[NestThermostatManager alloc] init];
    [self.nestThermostatManager setDelegate:self];
    
    [self.thermostatView showLoading];
}

#pragma mark - NestStructureManagerDelegate Methods

/**
 * Called from NestStructureManagerDelegate, lets the
 * controller know the structure has changed.
 * @param structure The updated structure.
 */
- (void)structureUpdated:(NSDictionary *)structure
{
    self.currentStructure = structure;
    
    if ([self.currentStructure objectForKey:@"thermostats"]) {
        
        self.numberOfThermostats = [[self.currentStructure objectForKey:@"thermostats"] count];
        self.currentThermostat = [[self.currentStructure objectForKey:@"thermostats"] objectAtIndex:self.currentThermostatIndex];
        [self subscribeToThermostat:self.currentThermostat];
        
        [self.thermostatView enableView];
        [self.statusLabel setText:@"Tap title to switch devices"];
        
    } else {
        [self.thermostatView disableView];
        [self.statusLabel setText:@"You don't have any devices"];
    }
    
    
}

#pragma mark - ThermostatViewDelegate Methods

/**
 * Called from the ThermostatViewDelegate, lets the controller know
 * thermostat info has changed.
 * @param thermostat The updated thermostat object from ThermostatView.
 */
- (void)thermostatInfoChange:(Thermostat *)thermostat
{
    [self.nestThermostatManager saveChangesForThermostat:thermostat];
}

/**
 * Scrolls through the thermostats.
 */
- (void)showNextThermostat
{
    if (self.currentThermostatIndex >= self.numberOfThermostats - 1) {
        self.currentThermostatIndex = 0;
    } else {
        self.currentThermostatIndex ++;
    }
    
    [self subscribeToThermostat:[[self.currentStructure objectForKey:@"thermostats"] objectAtIndex:self.currentThermostatIndex]];
}

#pragma mark - Private Methods

/**
 * Setup the communication between thermostatView and thermostatControl.
 * @param thermostat The thermostat you wish to subscribe to.
 */
- (void)subscribeToThermostat:(Thermostat *)thermostat
{
    // See if the structure has any thermostats --
    if (thermostat) {
        
        // Update the current thermostats
        self.currentThermostat = thermostat;

        [self.thermostatView showLoading];

        // Load information for just the first thermostat
        [self.nestThermostatManager beginSubscriptionForThermostat:thermostat];
        
    }
    
}

#pragma mark - NestThermostatManagerDelegate Methods

/**
 * Called from NestThermostatManagerDelegate, lets us know thermostat 
 * information has been updated online.
 * @param thermostat The updated thermostat object.
 */
- (void)thermostatValuesChanged:(Thermostat *)thermostat
{
    [self.thermostatView hideLoading];

    if ([thermostat.thermostatId isEqualToString:[self.currentThermostat thermostatId]]) {
        [self.thermostatView updateWithThermostat:thermostat];
    }

}



@end
