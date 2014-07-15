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

#import "ThermostatView.h"
#import "UIColor+Custom.h"

@interface ThermostatView ()

@property (nonatomic, strong) UILabel *currentTempLabel;
@property (nonatomic, strong) UILabel *targetTempLabel;
@property (nonatomic, strong) UIButton *thermostatNameLabel;

@property (nonatomic, strong) UILabel *currentTempSuffix;
@property (nonatomic, strong) UILabel *targetTempSuffix;
@property (nonatomic, strong) UILabel *fanSuffix;

@property (nonatomic, strong) UISlider *tempSlider;
@property (nonatomic, strong) UISwitch *fanSwitch;

@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIActivityIndicatorView *activity;

@property (nonatomic, strong) Thermostat *currentThermostat;

@property (nonatomic) BOOL isSlidingSlider;

@end

#define CURRENT_Y_LEVEL 40
#define TARGET_Y_LEVEL 95
#define FAN_Y_LEVEL 150
#define TITLE_FONT_SIZE 22
#define TEMP_HEIGHT 45
#define SUFFIX_HEIGHT 20
#define SUFFIX_WIDTH 160
#define DEFAULT_PADDING 10
#define TEMP_FONT_SIZE 50
#define TEMP_MIN_VALUE 50
#define TEMP_MAX_VALUE 90

#define PLACEHOLDER_TEXT @"...°"
#define TITLE_PLACEHOLDER @"..."
#define BOLD_FONT @"HelveticaNeue-Bold"
#define REGULAR_FONT @"HelveticaNeue"
#define CURRENT_SUFFIX @"current"
#define TARGET_SUFFIX @"target"
#define FAN_TIMER_SUFFIX_ON @"fan timer (on)"
#define FAN_TIMER_SUFFIX_OFF @"fan timer (off)"
#define FAN_TIMER_SUFFIX_DISABLED @"fan timer (disabled)"

@implementation ThermostatView

@synthesize currentTemp = _currentTemp;
@synthesize targetTemp = _targetTemp;

#pragma mark Setter Methods

/**
 * Provide the setter for the current temp.
 * @param currentTemp The temperature to set currentTemp to.
 */
- (void)setCurrentTemp:(NSInteger)currentTemp
{
    _currentTemp = currentTemp;
    [self updateCurrentTempLabel:currentTemp];
}

/**
 * Provide the setter for the target temp.
 * @param targetTemp The temperature to set targetTemp to.
 */
- (void)setTargetTemp:(NSInteger)targetTemp
{
    _targetTemp = targetTemp;
    [self updateTargetTempLabel:targetTemp];
}

#pragma mark View Setup

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1]];
        
        // Add rounded corners
        [self.layer setCornerRadius:6.f];
        [self.layer setBorderColor:[UIColor lightGrayColor].CGColor];
        [self.layer setBorderWidth:1.f];
        [self.layer setMasksToBounds:YES];
        
        // Add all the elements
        self.thermostatNameLabel = [self setupThermostatNameLabel];
        
        // Setup the labels
        self.currentTempLabel = [self setupTempLabelWithY:CURRENT_Y_LEVEL];
        self.targetTempLabel = [self setupTempLabelWithY:TARGET_Y_LEVEL];
        self.currentTempSuffix = [self setupSuffixLabelWithText:CURRENT_SUFFIX andY:CURRENT_Y_LEVEL];
        self.targetTempSuffix = [self setupSuffixLabelWithText:TARGET_SUFFIX andY:TARGET_Y_LEVEL];
        self.fanSuffix = [self setupSuffixLabelWithText:FAN_TIMER_SUFFIX_OFF andY:FAN_Y_LEVEL - DEFAULT_PADDING - 3];
        
        // Add a slider
        [self setupTempSlider];
        
        // Add the fan switch
        self.fanSwitch = [self setupFanSwitch];
        
        // Setup the loading view
        self.loadingView = [self setupLoadingView];
        
        [self.loadingView setHidden:YES];
        [self.loadingView setAlpha:0.0f];
        
        [self.activity setHidden:YES];
        [self.activity setAlpha:0.0f];
        [self.activity stopAnimating];
    }
    return self;
}

/**
 * Sets up the loading view a top the thermostat view.
 */
- (UIView *)setupLoadingView
{
    UIView *view = [[UIView alloc] initWithFrame:self.bounds];
    [view setBackgroundColor:[UIColor blackColor]];
    [view setAlpha:.5f];
    
    [view.layer setCornerRadius:6.f];
    [view.layer setMasksToBounds:YES];
    
    self.activity = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(CGRectGetMidX(view.frame), CGRectGetMidY(view.frame), self.activity.frame.size.width, self.activity.frame.size.height)];
    [self.activity setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    [view addSubview:self.activity];
    [self addSubview:view];
    return view;
}

/**
 * Setup the thermostat name label.
 */
- (UIButton *)setupThermostatNameLabel
{
    UIButton *thermostatButton = [[UIButton alloc] initWithFrame:CGRectMake(DEFAULT_PADDING, DEFAULT_PADDING, 280, 25)];
    [thermostatButton setTitle:TITLE_PLACEHOLDER forState:UIControlStateNormal];
    [thermostatButton setTitleColor:[UIColor nestBlue] forState:UIControlStateNormal];
    [thermostatButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:TITLE_FONT_SIZE]];
    [thermostatButton addTarget:self action:@selector(thermostatNameButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:thermostatButton];
    return thermostatButton;
}

/**
 * Updates isSlidingSlider to YES
 */
- (void)sliderMoving:(UISlider *)sender
{
    self.isSlidingSlider = YES;
}

/**
 * Setup a temperature label with a given Y value.
 * @param yValue The yValue the label should be at.
 * @return The new UILabel.
 */
- (UILabel *)setupTempLabelWithY:(int)yValue
{
    // Find out how wide to make the string
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:BOLD_FONT size:TEMP_FONT_SIZE]};
    CGSize textSize = [PLACEHOLDER_TEXT sizeWithAttributes:attributes];
    
    UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(DEFAULT_PADDING, yValue, textSize.width, TEMP_HEIGHT)];
    [tempLabel setText:PLACEHOLDER_TEXT];
    [tempLabel setTextColor:[UIColor darkGrayColor]];
    [tempLabel setTextAlignment:NSTextAlignmentLeft];
    [tempLabel setFont:[UIFont fontWithName:BOLD_FONT size:TEMP_FONT_SIZE]];
    [self addSubview:tempLabel];
    return tempLabel;
}

/**
 * Setup a suffix label with a given Y value.
 * @param yValue The yValue the label should be at.
 * @return The new UILabel.
 */
- (UILabel *)setupSuffixLabelWithText:(NSString *)text andY:(int)yValue
{
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:BOLD_FONT size:TEMP_FONT_SIZE]};
    CGSize textSize = [PLACEHOLDER_TEXT sizeWithAttributes:attributes];
    
    UILabel *suffixLabel = [[UILabel alloc] initWithFrame:CGRectMake(DEFAULT_PADDING + 5 + textSize.width, yValue + SUFFIX_HEIGHT - 3, SUFFIX_WIDTH, SUFFIX_HEIGHT)];
    [suffixLabel setText:text];
    [suffixLabel setTextColor:[UIColor darkGrayColor]];
    [suffixLabel setTextAlignment:NSTextAlignmentLeft];
    [suffixLabel setFont:[UIFont fontWithName:REGULAR_FONT size:17.f]];
    [self addSubview:suffixLabel];
    return suffixLabel;
}

/**
 * Sets up the Fan Switch
 * @return The new fan switch.
 */
- (UISwitch *)setupFanSwitch
{
    UISwitch *fanSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(DEFAULT_PADDING, FAN_Y_LEVEL, 79, 50)];
    [fanSwitch addTarget:self action:@selector(fanDidSwitch:) forControlEvents:UIControlEventValueChanged];
    [fanSwitch setOnTintColor:[UIColor nestBlue]];
    [self addSubview:fanSwitch];
    return fanSwitch;
}

/**
 * Sets up the target temperature slider.
 * @return The new target temperature slider.
 */
- (void)setupTempSlider
{
    self.tempSlider = [[UISlider alloc] initWithFrame:CGRectMake(self.frame.size.width/2 + DEFAULT_PADDING, TARGET_Y_LEVEL, self.frame.size.width/2 - (DEFAULT_PADDING * 2), TEMP_HEIGHT)];
    [self.tempSlider setTintColor:[UIColor nestBlue]];
    [self.tempSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.tempSlider addTarget:self action:@selector(sliderMoving:) forControlEvents:UIControlEventTouchDown];
    [self.tempSlider addTarget:self action:@selector(sliderValueSettled:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.tempSlider];
}

#pragma mark Update Methods

/**
 * Update the target temperature label.
 * @param newTemp The temperature you wish to update to.
 */
- (void)updateTargetTempLabel:(NSInteger)newTemp
{
    NSString *newString = [NSString stringWithFormat:@"%d°", (int)newTemp];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:BOLD_FONT size:TEMP_FONT_SIZE]};
    CGSize textSize = [newString sizeWithAttributes:attributes];
    
    [self.targetTempLabel setFrame:CGRectMake(DEFAULT_PADDING, TARGET_Y_LEVEL, textSize.width, TEMP_HEIGHT)];
    [self.targetTempLabel setText:newString];
    [self.targetTempSuffix setFrame:CGRectMake(DEFAULT_PADDING + 5 + textSize.width, TARGET_Y_LEVEL + SUFFIX_HEIGHT - 3, SUFFIX_WIDTH, SUFFIX_HEIGHT)];
}

/**
 * Update the current temperature label.
 * @param newTemp The temperature you wish to update to.
 */
- (void)updateCurrentTempLabel:(NSInteger)newTemp
{
    NSString *newString = [NSString stringWithFormat:@"%d°", (int)newTemp];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:BOLD_FONT size:TEMP_FONT_SIZE]};
    CGSize textSize = [newString sizeWithAttributes:attributes];
    
    [self.currentTempLabel setFrame:CGRectMake(DEFAULT_PADDING, CURRENT_Y_LEVEL, textSize.width, TEMP_HEIGHT)];
    [self.currentTempLabel setText:newString];
    [self.currentTempSuffix setFrame:CGRectMake(DEFAULT_PADDING + 5 + textSize.width, CURRENT_Y_LEVEL + SUFFIX_HEIGHT - 3, SUFFIX_WIDTH, SUFFIX_HEIGHT)];
}

#pragma mark Thermostat Interaction Methods

/**
 * Show the loading view.
 */
- (void)showLoading
{
    [self.activity startAnimating];
    [self.loadingView setHidden:NO];
    [self.activity setHidden:NO];

    [UIView animateWithDuration:.3f animations:^{
        [self.activity setAlpha:0.6f];
        [self.loadingView setAlpha:0.6f];
    }];
}

/**
 * Hide the loading view.
 */
- (void)hideLoading
{
    [UIView animateWithDuration:.3f animations:^{
        [self.activity setAlpha:0.0f];
        [self.loadingView setAlpha:0.0f];
    } completion:^(BOOL finished){
        [self.loadingView setHidden:YES];
        [self.activity setHidden:YES];
        [self.activity stopAnimating];
    }];
}

/**
 * Disables the entire thermostat view.
 */
- (void)disableView
{
    [self.loadingView setHidden:NO];
    [self.activity setHidden:YES];
    [self.loadingView setAlpha:0.4f];
}

/**
 * Enables the entire thermostat.
 */
- (void)enableView
{
    [self.loadingView setHidden:YES];
    [self.loadingView setAlpha:0.0f];
}

/**
 * Called every time the slider's value changes.
 */
- (void)sliderValueChanged:(UISlider *)sender
{
    [self setTargetTemp:[self tempSliderActualValue]];
}

/**
 * Get the target temperature from slider percentage.
 * @return The estimated temperature given the slider's position.
 */
- (NSInteger)tempSliderActualValue
{
    float percent = self.tempSlider.value;
    int range = TEMP_MAX_VALUE - TEMP_MIN_VALUE;
    int relative = round(range * percent);
    return relative + TEMP_MIN_VALUE;
}


/**
 * Called when the user Touches Up Inside the slider.
 * @param sender The slider that sent the message.
 */
- (void)sliderValueSettled:(UISlider *)sender
{
    self.isSlidingSlider = NO;
    
    [self.currentThermostat setTargetTemperatureF:[self tempSliderActualValue]];
    [self saveThermostatChange];
}

/**
 * Sets the slider to the target temp.
 */
- (void)equalizeSlider
{
    int range = (TEMP_MAX_VALUE - TEMP_MIN_VALUE);
    int relative = (int)self.targetTemp - TEMP_MIN_VALUE;
    float percent = (float)relative/(float)range;
    
    if (!self.isSlidingSlider) {
        [self animateSliderToValue:percent];
    }
}

/**
 * Animates the UISlider change.
 * @param value The value you are trying to animate to.
 */
- (void)animateSliderToValue:(float)value
{
    [UIView animateWithDuration:.5 animations:^{
        [self.tempSlider setValue:value animated:YES];
    } completion:^(BOOL finished) {
        
    }];
}

/**
 * When the fan switch is toggled.
 * @param sender The fan that was switched.
 */
- (void)fanDidSwitch:(UISwitch *)sender
{
    [self.currentThermostat setFanTimerActive:sender.isOn];
    [self saveThermostatChange];
}

/**
 * Turn the fan on/off.
 * @param on YES if you wish to turn the fan on. NO if fan off.
 */
- (void)turnFan:(BOOL)on
{
    [self.fanSwitch setOn:on];
}

/**
 * Update the thermostat view to represent the thermostat object.
 * @param thermostat The thermostat you wish to have the view represent.
 */
- (void)updateWithThermostat:(Thermostat *)thermostat
{
    // Set the current thermostat
    self.currentThermostat = thermostat;
    
    // Update the name of the thermostat
    [self.thermostatNameLabel setTitle:thermostat.nameLong forState:UIControlStateNormal];
    
    // Update the current temp label
    self.currentTemp = thermostat.ambientTemperatureF;
    self.targetTemp = thermostat.targetTemperatureF;
    [self equalizeSlider];
        
    // If the thermostat isn't associated with a fan -- turn off the switch
    if (thermostat.hasFan) {
        [self.fanSwitch setEnabled:YES];
        [self turnFan:thermostat.fanTimerActive];

        if (thermostat.fanTimerActive) {
            [self.fanSuffix setText:FAN_TIMER_SUFFIX_ON];
        } else {
            [self.fanSuffix setText:FAN_TIMER_SUFFIX_OFF];
        }
    } else {
        [self.fanSwitch setEnabled:NO];
        [self.fanSuffix setText:FAN_TIMER_SUFFIX_DISABLED];
    }
}

/**
 * When the thermostat name button is hit.
 * @param sender The button that sent the message.
 */
- (void)thermostatNameButtonHit:(UIButton *)sender
{
    [self.delegate showNextThermostat];
}

/*
 * Thermostat was updated, save the change ONLINE!!!.
 */
- (void)saveThermostatChange
{
    [self.delegate thermostatInfoChange:self.currentThermostat];
}

@end
