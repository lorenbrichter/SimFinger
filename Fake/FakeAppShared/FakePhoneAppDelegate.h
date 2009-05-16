//
//  FakePhoneAppDelegate.h
//  FakePhone
//
//  Created by Loren Brichter on 2/11/09.
//  Copyright atebits 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FakePhoneAppDelegate : NSObject <UIApplicationDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
{
	IBOutlet UIPickerView *picker;
    UIWindow *window;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

