//
//  SimFingerAppDelegate.m
//  SimFinger
//
//  Created by Loren Brichter on 2/11/09.
//  Copyright 2009 atebits. All rights reserved.
//

#import "FakeFingerAppDelegate.h"
#import <Carbon/Carbon.h>

static NSString *kiOSSimBundleID = @"com.apple.iphonesimulator";
static NSTimeInterval kTimeoutToLaunchSimulatorSeconds = 10.0f;

void WindowFrameDidChangeCallback( AXObserverRef observer, AXUIElementRef element, CFStringRef notificationName, void * contextData)
{
    FakeFingerAppDelegate * delegate= (FakeFingerAppDelegate *) contextData;
	[delegate positionSimulatorWindow:nil];
}

@implementation FakeFingerAppDelegate

- (void)registerForSimulatorWindowResizedNotification
{
	// this methode is leaking ...
	
	AXUIElementRef simulatorApp = [self simulatorApplication];
	if (!simulatorApp) return;
	
	AXUIElementRef frontWindow = NULL;
	AXError err = AXUIElementCopyAttributeValue( simulatorApp, kAXFocusedWindowAttribute, (CFTypeRef *) &frontWindow );
	if ( err != kAXErrorSuccess ) return;
    
	AXObserverRef observer = NULL;
	pid_t pid;
	AXUIElementGetPid(simulatorApp, &pid);
	err = AXObserverCreate(pid, WindowFrameDidChangeCallback, &observer );
	if ( err != kAXErrorSuccess ) return;
	
	AXObserverAddNotification( observer, frontWindow, kAXResizedNotification, self );
	AXObserverAddNotification( observer, frontWindow, kAXMovedNotification, self );
    
	CFRunLoopAddSource( [[NSRunLoop currentRunLoop] getCFRunLoop],  AXObserverGetRunLoopSource(observer),  kCFRunLoopDefaultMode );
    
}

// Returns nil if there is no iOS Simulator running, otherwise the simulator based on the bundleid
// kiOSSimBundleID above.
- (NSRunningApplication *)runningSimulatorApplication
{
	NSArray *applications = [[NSWorkspace sharedWorkspace] runningApplications];
	
	for(NSRunningApplication *application in applications)
	{
		if([application.bundleIdentifier isEqualToString:kiOSSimBundleID])
		{
			return application;
		}
	}
	return nil;
}

- (AXUIElementRef)simulatorApplication
{
	NSDictionary *options = @{(id)kAXTrustedCheckOptionPrompt: @YES};
	BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((CFDictionaryRef)options);
	
	if(accessibilityEnabled == YES)
	{
		__block NSRunningApplication *simulatorApplication = [self runningSimulatorApplication];
		if (simulatorApplication == nil) {
			// This line is a really ugly, hacky way to get the simulator to resize upon first loading.
			// If you can fix this, do it soon please.
			[self performSelector:@selector(positionSimulatorWindow:) withObject:nil afterDelay:3.0f];
			
			// Launch the simulator if it isn't running
			[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:kiOSSimBundleID
																 options:NSWorkspaceLaunchDefault
										  additionalEventParamDescriptor:nil
														launchIdentifier:nil];
			__block BOOL isWaitingForSimulatorToLaunch = YES;
			// Wait in background for simulator to launch.
			NSDate *startTime = [NSDate date];
			dispatch_async(dispatch_get_current_queue(), ^{
				while (simulatorApplication == nil) {
					simulatorApplication = [self runningSimulatorApplication];
					sleep(1);
					// Just in case, let's timeout after a small interval so we don't stay here forever.
					if ([[NSDate date] timeIntervalSinceDate:startTime] > kTimeoutToLaunchSimulatorSeconds) {
						isWaitingForSimulatorToLaunch = NO;
					}
				}
			});
			while (isWaitingForSimulatorToLaunch) {
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
			}
		}
		if (simulatorApplication == nil) {
			NSRunAlertPanel(@"Couldn't find Simulator after launching", @"Couldn't find Simulator after launching.", @"OK", nil, nil, nil);
			return NULL;
		}
		pid_t pid = simulatorApplication.processIdentifier;
		AXUIElementRef element = AXUIElementCreateApplication(pid);
		return element;
	} else {
		NSRunAlertPanel(@"Universal Access Disabled", @"You must enable access for assistive devices in the System Preferences, under Universal Access.", @"OK", nil, nil, nil);
	}
	NSRunAlertPanel(@"Couldn't find Simulator", @"Couldn't find iOS Simulator.", @"OK", nil, nil, nil);
	return NULL;
}

- (void)positionSimulatorWindow:(id)sender
{
	AXUIElementRef element = [self simulatorApplication];
	
	CFArrayRef attributeNames;
	AXUIElementCopyAttributeNames(element, &attributeNames);
	
	CFArrayRef value;
	AXUIElementCopyAttributeValue(element, CFSTR("AXWindows"), (CFTypeRef *)&value);
	
	for(id object in (NSArray *)value)
	{
		if(CFGetTypeID(object) == AXUIElementGetTypeID())
		{
			AXUIElementRef subElement = (AXUIElementRef)object;
			
			AXUIElementPerformAction(subElement, kAXRaiseAction);
			
			CFArrayRef subAttributeNames;
			AXUIElementCopyAttributeNames(subElement, &subAttributeNames);
			
			CFTypeRef sizeValue;
			AXUIElementCopyAttributeValue(subElement, kAXSizeAttribute, (CFTypeRef *)&sizeValue);
			
			CGSize size;
			AXValueGetValue(sizeValue, kAXValueCGSizeType, (void *)&size);
			
			NSLog(@"Simulator current size: %d, %d", (int)size.width, (int)size.height);
			
			BOOL supportedSize = NO;
			BOOL iPadMode = NO;
            BOOL iPhone5Mode = NO;
			BOOL landscape = NO;
            BOOL landscape5 = NO;
			int iPhoneWidth = 320;
			int iPhoneHeight = 502;
			int iPadWidth = 790;
			int iPadHeight = 1024;
            int iPhone5Width = 320;
            int iPhone5Height = 590;
			
			if((int)size.width == iPhoneWidth && (int)size.height == iPhoneHeight) {
				[hardwareOverlay setContentSize:NSMakeSize(634, 985)];
				[hardwareOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPhoneFrame"]]];
				
				[fadeOverlay setContentSize:NSMakeSize(634,985)];
				[fadeOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"FadeFrame"]]];
				
				supportedSize = YES;
			} else if((int)size.width == iPhoneHeight - 22 && (int)size.height == iPhoneWidth + 22) {
				[hardwareOverlay setContentSize:NSMakeSize(985,634)];
				[hardwareOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPhoneFrameLandscape_right"]]];
				
				[fadeOverlay setContentSize:NSMakeSize(985,634)];
				[fadeOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"FadeFrameLandscape"]]];
				
				supportedSize = YES;
				landscape = YES;
			} else if((int)size.width == iPhone5Height - 22 && (int)size.height == iPhone5Width + 22) {
				[hardwareOverlay setContentSize:NSMakeSize(985,634)];
				[hardwareOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPhone5sFrameLandscape_right"]]];
				
				[fadeOverlay setContentSize:NSMakeSize(985,634)];
				[fadeOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"FadeFrameLandscape"]]];
				
				supportedSize = YES;
                iPhone5Mode = YES;
				landscape5 = YES;
			} else if ((int)size.width == iPadWidth - 22 && (int)size.height == iPadHeight + 22) {
				[hardwareOverlay setContentSize:NSMakeSize(1128, 1410)];
				[hardwareOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPadFrame"]]];
				
				[fadeOverlay setContentSize:NSMakeSize(1128, 1410)];
				[fadeOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPadFade"]]];
                
				supportedSize = YES;
				iPadMode = YES;
			} else if ((int)size.width == iPadHeight && (int)size.height == iPadWidth) {
				[hardwareOverlay setContentSize:NSMakeSize(1410, 1128)];
				[hardwareOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPadFrameLandscape_right"]]];
				
				[fadeOverlay setContentSize:NSMakeSize(1128, 1410)];
				[fadeOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPadFadeLandscape"]]];
				
				supportedSize = YES;
				iPadMode = YES;
				landscape = YES;
			} else if ((int)size.width == iPhone5Width && (int)size.height == iPhone5Height) {
                [hardwareOverlay setContentSize:NSMakeSize(634, 985)];
				[hardwareOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPhone5sFrame"]]];
				
				[fadeOverlay setContentSize:NSMakeSize(634,985)];
				[fadeOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"FadeFrame"]]];
                
                supportedSize = YES;
				iPhone5Mode = YES;
            }
			
			if(supportedSize) {
				Boolean settable;
				AXUIElementIsAttributeSettable(subElement, kAXPositionAttribute, &settable);
				
				CGPoint point;
				if(!iPadMode) {
                    if(iPhone5Mode && !landscape5) {
                        point.x = 159;
                        point.y = screenRect.size.height - size.height - 209;
                    } else if(landscape5 && !landscape) {
						point.x = 209;
						point.y = screenRect.size.height - size.height - 155;
					} else if(!landscape) {
						point.x = 154;
						point.y = screenRect.size.height - size.height - 267;
					} else {
						point.x = 252;
						point.y = screenRect.size.height - size.height - 168;
					}
				} else {
					if (!landscape) {
						point.x = 180;
                        point.y = screenRect.size.height - size.height - 199;
					} else {
						point.x = 199;
                        point.y = screenRect.size.height - size.height - 180;
					}
				}
				AXValueRef pointValue = AXValueCreate(kAXValueCGPointType, &point);
				
				AXUIElementSetAttributeValue(subElement, kAXPositionAttribute, (CFTypeRef)pointValue);
			}
			
		}
	}
}

- (NSString *)iosVersion
{
	return @"7.1"; // Latest iOS version, for applying preferences.
}

- (NSString *)springboardPrefsPath
{
	return [[NSString stringWithFormat: @"~/Library/Application Support/iPhone Simulator/%@/Library/Preferences/com.apple.springboard.plist", [self iosVersion]] stringByExpandingTildeInPath];
}

- (NSMutableDictionary *)springboardPrefs
{
	if(!springboardPrefs)
	{
		springboardPrefs = [[NSDictionary dictionaryWithContentsOfFile:[self springboardPrefsPath]] mutableCopy];
		if(!springboardPrefs)
			springboardPrefs = [[NSMutableDictionary alloc] init];
	}
	return springboardPrefs;
}

- (void)saveSpringboardPrefs
{
	NSString *error;
	NSData *plist = [NSPropertyListSerialization dataFromPropertyList:(id)springboardPrefs
															   format:kCFPropertyListBinaryFormat_v1_0
													 errorDescription:&error];
	NSLog(@"%@", [self springboardPrefsPath]);
	[plist writeToFile:[self springboardPrefsPath] atomically:YES];
}

- (void)restoreSpringboardPrefs
{
	[[self springboardPrefs] removeObjectForKey:@"SBFakeTime"];
	[[self springboardPrefs] removeObjectForKey:@"SBFakeTimeString"];
	[[self springboardPrefs] removeObjectForKey:@"SBFakeCarrier"];
	[self saveSpringboardPrefs];
	NSRunAlertPanel(@"iPhone Simulator Springboard Changed", @"Springboard settings have been restored.  Please restart iPhone Simulator for changes to take effect.", @"OK", nil, nil);
}

- (void)setSpringboardFakeTime:(NSString *)s
{
	[[self springboardPrefs] setObject:[NSNumber numberWithBool:YES] forKey:@"SBFakeTime"];
	[[self springboardPrefs] setObject:s forKey:@"SBFakeTimeString"];
	[self saveSpringboardPrefs];
	NSRunAlertPanel(@"iPhone Simulator Springboard Changed", @"Fake time text has been changed.  Please restart iPhone Simulator for changes to take effect.", @"OK", nil, nil);
}

- (void)setSpringboardFakeCarrier:(NSString *)s
{
	[[self springboardPrefs] setObject:s forKey:@"SBFakeCarrier"];
	[self saveSpringboardPrefs];
	NSRunAlertPanel(@"iPhone Simulator Springboard Changed", @"Fake Carrier text has been changed.  Please restart iPhone Simulator for changes to take effect.", @"OK", nil, nil);
}

enum {
	SetCarrierMode,
	SetTimeMode,
};

- (IBAction)cancelSetText:(id)sender
{
	[NSApp stopModal];
	[setTextPanel orderOut:nil];
}

- (IBAction)saveSetText:(id)sender
{
	switch(setTextMode)
	{
		case SetCarrierMode:
			[self setSpringboardFakeCarrier:[setTextField stringValue]];
			break;
		case SetTimeMode:
			[self setSpringboardFakeTime:[setTextField stringValue]];
			break;
	}
	
	[NSApp stopModal];
	[setTextPanel orderOut:nil];
}

- (IBAction)promptCarrierText:(id)sender
{
	setTextMode = SetCarrierMode;
	[setTextLabel setStringValue:@"Set Fake Carrier Text"];
	NSString *s = [[self springboardPrefs] objectForKey:@"SBFakeCarrier"];
	if(s)
		[setTextField setStringValue:s];
	[NSApp runModalForWindow:setTextPanel];
}

- (IBAction)promptTimeText:(id)sender
{
	setTextMode = SetTimeMode;
	[setTextLabel setStringValue:@"Set Fake Time Text"];
	NSString *s = [[self springboardPrefs] objectForKey:@"SBFakeTimeString"];
	if(s)
		[setTextField setStringValue:s];
	[NSApp runModalForWindow:setTextPanel];
}

- (IBAction)restoreSpringboardPrefs:(id)sender
{
	[self restoreSpringboardPrefs];
}

- (IBAction)installFakeApps:(id)sender
{
	NSError *error;
	NSArray *items = [NSArray arrayWithObjects:
					  @"FakeAppStore",
					  @"FakeCalculator",
					  @"FakeCamera",
					  @"FakeClock",
                      @"FakeCompass",
					  @"FakeiPod",
					  @"FakeiTunes",
					  @"FakeMail",
					  @"FakeNotes",
					  @"FakePhone",
					  @"FakeStocks",
					  @"FakeText",
                      @"FakeVoiceMemos",
					  @"FakeWeather",
					  nil];
	
	NSString *srcDir = [[NSBundle mainBundle] resourcePath];
	NSString *dstDir = [[NSString stringWithFormat: @"~/Library/Application Support/iPhone Simulator/%@/Applications", [self iosVersion]] stringByExpandingTildeInPath];
	[[NSFileManager defaultManager] createDirectoryAtPath:dstDir withIntermediateDirectories:YES attributes:nil error:nil];
	
	for(NSString *item in items)
	{
		NSString *src = [srcDir stringByAppendingPathComponent:item];
		NSString *dst = [dstDir stringByAppendingPathComponent:item];
		
		[[NSFileManager defaultManager] removeItemAtPath:dst error:nil];
		if(![[NSFileManager defaultManager] copyItemAtPath:src toPath:dst error:&error])
		{
			NSLog(@"copyItemAtPath error %@", error);
			NSLog(@"src: %@", src);
			NSLog(@"dst: %@", dst);
		}
	}
	
	NSRunAlertPanel(@"Fake Apps Installed", @"Fake Apps have been installed in iPhone Simulator.  Please restart iPhone Simulator for changes to take effect.", @"OK", nil, nil);
}

- (void)_updateWindowPosition
{
	NSPoint p = [NSEvent mouseLocation];
	[pointerOverlay setFrameOrigin:NSMakePoint(p.x - 25, p.y - 25)];
}

- (void)mouseDown
{
	[pointerOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"Active"]]];
}

- (void)mouseUp
{
	[pointerOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"Hover"]]];
}

- (void)mouseMoved
{
	[self _updateWindowPosition];
}

- (void)mouseDragged
{
	[self _updateWindowPosition];
}




- (void)configureHardwareOverlay:(NSMenuItem *)sender
{
	if(hardwareOverlayIsHidden) {
		[hardwareOverlay orderFront:nil];
		[fadeOverlay orderFront:nil];
		[sender setState:NSOffState];
	} else {
		[hardwareOverlay orderOut:nil];
		[fadeOverlay orderOut:nil];
		[sender setState:NSOnState];
	}
	hardwareOverlayIsHidden = !hardwareOverlayIsHidden;
}

- (void)configurePointerOverlay:(NSMenuItem *)sender
{
	if(pointerOverlayIsHidden) {
		[pointerOverlay orderFront:nil];
		[sender setState:NSOffState];
	} else {
		[pointerOverlay orderOut:nil];
		[sender setState:NSOnState];
	}
	pointerOverlayIsHidden = !pointerOverlayIsHidden;
}

- (IBAction)showCursorPressed:(NSMenuItem *)sender {
    if(cursorIsShown) {
        [sender setState: NSOffState];
        hideTheCursor();
    } else {
        [sender setState: NSOnState];
        showTheCursor();
    }
    cursorIsShown = !cursorIsShown;
}

CGEventRef tapCallBack(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *info)
{
	FakeFingerAppDelegate *delegate = (FakeFingerAppDelegate *)info;
	switch(type)
	{
		case kCGEventLeftMouseDown:
			[delegate mouseDown];
			break;
		case kCGEventLeftMouseUp:
			[delegate mouseUp];
			break;
		case kCGEventLeftMouseDragged:
			[delegate mouseDragged];
			break;
		case kCGEventMouseMoved:
			[delegate mouseMoved];
			break;
	}
    
    if(!delegate->cursorIsShown)
        hideTheCursor();
	return event;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	hardwareOverlay = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 634, 985) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	[hardwareOverlay setAlphaValue:1.0];
	[hardwareOverlay setOpaque:NO];
	[hardwareOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPhoneFrame"]]];
	[hardwareOverlay setIgnoresMouseEvents:YES];
	[hardwareOverlay setLevel:NSFloatingWindowLevel - 1];
	[hardwareOverlay orderFront:nil];
	
	screenRect = [[hardwareOverlay screen] frame];
	
	pointerOverlay = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 50, 50) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	[pointerOverlay setAlphaValue:0.8];
	[pointerOverlay setOpaque:NO];
	[pointerOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"Hover"]]];
	[pointerOverlay setLevel:NSFloatingWindowLevel];
	[pointerOverlay setIgnoresMouseEvents:YES];
	[self _updateWindowPosition];
	[pointerOverlay orderFront:nil];
	
	fadeOverlay = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 634, 985) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	[fadeOverlay setAlphaValue:1.0];
	[fadeOverlay setOpaque:NO];
	[fadeOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"FadeFrame"]]];
	[fadeOverlay setIgnoresMouseEvents:YES];
	[fadeOverlay setLevel:NSFloatingWindowLevel + 1];
	[fadeOverlay orderFront:nil];
	
	CGEventMask mask =	CGEventMaskBit(kCGEventLeftMouseDown) |
    CGEventMaskBit(kCGEventLeftMouseUp) |
    CGEventMaskBit(kCGEventLeftMouseDragged) |
    CGEventMaskBit(kCGEventMouseMoved);
    
	CFMachPortRef tap = CGEventTapCreate(kCGAnnotatedSessionEventTap,
                                         kCGTailAppendEventTap,
                                         kCGEventTapOptionListenOnly,
                                         mask,
                                         tapCallBack,
                                         self);
	
	CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(NULL, tap, 0);
	CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopCommonModes);
	
	CFRelease(runLoopSource);
	CFRelease(tap);
	
	[self registerForSimulatorWindowResizedNotification];
	[self positionSimulatorWindow:nil];
	hideTheCursor();
    
	NSLog(@"Repositioned simulator window.");
}

void hideTheCursor()
{
    // The not so hacky way:
    //    CGDirectDisplayID myId = CGMainDisplayID();
    //    CGDisplayHideCursor(kCGDirectMainDisplay);
    //    BOOL isCursorVisible = CGCursorIsVisible();
    
    // The hacky way:
    void CGSSetConnectionProperty(int, int, CFStringRef, CFBooleanRef);
    int _CGSDefaultConnection();
    CFStringRef propertyString;
    
    // Hack to make background cursor setting work
    propertyString = CFStringCreateWithCString(NULL, "SetsCursorInBackground", kCFStringEncodingUTF8);
    CGSSetConnectionProperty(_CGSDefaultConnection(), _CGSDefaultConnection(), propertyString, kCFBooleanTrue);
    CFRelease(propertyString);
    // Hide the cursor and wait
    CGDisplayHideCursor(kCGDirectMainDisplay);
}

void showTheCursor()
{
    CGDisplayShowCursor(kCGDirectMainDisplay);
}

@end