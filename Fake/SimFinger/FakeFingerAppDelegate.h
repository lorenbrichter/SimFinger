//
//  SimFingerAppDelegate.h
//  SimFinger
//
//  Created by Loren Brichter on 2/11/09.
//  Copyright 2009 atebits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FakeFingerAppDelegate : NSObject
{
	NSRect screenRect;
	
	NSWindow *pointerOverlay;
	NSWindow *hardwareOverlay;
	NSWindow *fadeOverlay;
	
	BOOL pointerOverlayIsHidden;
	BOOL hardwareOverlayIsHidden;
	
	int setTextMode;
	NSMutableDictionary *springboardPrefs;
	
	IBOutlet NSPanel *setTextPanel;
	IBOutlet NSTextField *setTextLabel;
	IBOutlet NSTextField *setTextField;
}

- (IBAction)configureHardwareOverlay:(NSMenuItem *)sender;
- (IBAction)configurePointerOverlay:(NSMenuItem *)sender;
- (IBAction)positionSimulatorWindow:(id)sender;

- (IBAction)promptCarrierText:(id)sender;
- (IBAction)promptTimeText:(id)sender;
- (IBAction)restoreSpringboardPrefs:(id)sender;

- (IBAction)cancelSetText:(id)sender;
- (IBAction)saveSetText:(id)sender;

- (IBAction)installFakeApps:(id)sender;

@end
