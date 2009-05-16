//
//  FakePhoneAppDelegate.m
//  FakePhone
//
//  Created by Loren Brichter on 2/11/09.
//  Copyright atebits 2009. All rights reserved.
//

#import "FakePhoneAppDelegate.h"

@implementation FakePhoneAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    [window makeKeyAndVisible];
	[picker selectRow:[UIApplication sharedApplication].applicationIconBadgeNumber inComponent:0 animated:NO];
}

- (void)dealloc
{
    [window release];
    [super dealloc];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return 21;
}

// these methods return either a plain UIString, or a view (e.g UILabel) to display the row for the component.
// for the view versions, we cache any hidden and thus unused views and pass them back for reuse. 
// If you return back a different object, the old one will be released. the view will be centered in the row rect  
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	return [NSString stringWithFormat:@"%d", row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	[UIApplication sharedApplication].applicationIconBadgeNumber = row;
}

@end
