//
//  SimFingerAppDelegate.m
//  SimFinger
//
//  Created by Loren Brichter on 2/11/09.
//  Copyright 2009 atebits. All rights reserved.
//

#import "FakeFingerAppDelegate.h"
#import <Carbon/Carbon.h>


void WindowFrameDidChangeCallback( AXObserverRef observer, AXUIElementRef element, CFStringRef notificationName, void * contextData ) {
    FakeFingerAppDelegate * delegate= (FakeFingerAppDelegate *) contextData;
	[delegate positionSimulatorWindow:nil];
}

@implementation FakeFingerAppDelegate


- (void)registerForSimulatorWindowResizedNotification {
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



- (AXUIElementRef)simulatorApplication {
	if(AXAPIEnabled())
	{
		NSArray *applications = [[NSWorkspace sharedWorkspace] launchedApplications];
		
		for(NSDictionary *application in applications)
		{
			if([[application objectForKey:@"NSApplicationName"] isEqualToString:@"iPhone Simulator"])
			{
				pid_t pid = (pid_t)[[application objectForKey:@"NSApplicationProcessIdentifier"] integerValue];
				
				[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:[application objectForKey:@"NSApplicationBundleIdentifier"] 
																	 options:NSWorkspaceLaunchDefault 
											  additionalEventParamDescriptor:nil 
															launchIdentifier:nil];
				
				AXUIElementRef element = AXUIElementCreateApplication(pid);
				return element;
			}
		}
	} else {
		NSRunAlertPanel(@"Universal Access Disabled", @"You must enable access for assistive devices in the System Preferences, under Universal Access.", @"OK", nil, nil, nil);
	}
	NSRunAlertPanel(@"Couldn't find Simulator", @"Couldn't find iPhone Simulator.", @"OK", nil, nil, nil);
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
			BOOL landscape = NO;
			if((int)size.width == 386 && (int)size.height == 742)
			{
				[hardwareOverlay setContentSize:NSMakeSize(634, 985)];
				[hardwareOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPhoneFrame"]]];
				
				[fadeOverlay setContentSize:NSMakeSize(634,985)];
				[fadeOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"FadeFrame"]]];
				
				supportedSize = YES;
				
			} else if((int)size.width == 742 && (int)size.height == 386) {
				[hardwareOverlay setContentSize:NSMakeSize(985,634)];
				[hardwareOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPhoneFrameLandscape_right"]]];
				
				[fadeOverlay setContentSize:NSMakeSize(985,634)];
				[fadeOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"FadeFrameLandscape"]]];
				
				supportedSize = YES;
				landscape = YES;
			} else if ((int)size.width == 852 && (int)size.height == 1108) {
				[hardwareOverlay setContentSize:NSMakeSize(1128, 1410)];
				[hardwareOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPadFrame"]]];
				
				[fadeOverlay setContentSize:NSMakeSize(1128, 1410)];
				[fadeOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPadFade"]]];
				
				supportedSize = YES;
				iPadMode = YES;
			} else if ((int)size.width == 1108 && (int)size.height == 852) {
				[hardwareOverlay setContentSize:NSMakeSize(1410, 1128)];
				[hardwareOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPadFrameLandscape_right"]]];
				
				[fadeOverlay setContentSize:NSMakeSize(1128, 1410)];
				[fadeOverlay setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"iPadFadeLandscape"]]];
				
				supportedSize = YES;
				iPadMode = YES;
				landscape = YES;
			}
			
			if (supportedSize) {
				Boolean settable;
				AXUIElementIsAttributeSettable(subElement, kAXPositionAttribute, &settable);
				
				CGPoint point;
				if (!iPadMode) {
					point.x = 121;
					point.y = screenRect.size.height - size.height - 135;					
				} else {
					if (!landscape) {
						point.x = 138;
					} else {
						point.x = 157;
					}
					
					point.y = screenRect.size.height - size.height - 156;
				}
				AXValueRef pointValue = AXValueCreate(kAXValueCGPointType, &point);
				
				AXUIElementSetAttributeValue(subElement, kAXPositionAttribute, (CFTypeRef)pointValue);
			}							
			
		}
	}
}



- (NSString *)springboardPrefsPath
{
	return [@"~/Library/Application Support/iPhone Simulator/User/Library/Preferences/com.apple.springboard.plist" stringByExpandingTildeInPath];
}

- (NSMutableDictionary *)springboardPrefs
{
	if(!springboardPrefs)
	{
		springboardPrefs = [[NSDictionary dictionaryWithContentsOfFile:[self springboardPrefsPath]] mutableCopy];
	}
	return springboardPrefs;
}

- (void)saveSpringboardPrefs
{
	NSString *error;
	NSData *plist = [NSPropertyListSerialization dataFromPropertyList:(id)springboardPrefs
															   format:kCFPropertyListBinaryFormat_v1_0 
													 errorDescription:&error];
	
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
					  @"FakeCalendar",
					  @"FakeCamera",
					  @"FakeClock",
                      @"FakeCompass",
					  @"FakeiPod",
					  @"FakeiTunes",
					  @"FakeMail",
					  @"FakeMaps",
					  @"FakeNotes",
					  @"FakePhone",
					  @"FakeStocks",
					  @"FakeText",
                      @"FakeVoiceMemos",
					  @"FakeWeather",
					  @"FakeYouTube",
					  nil];
	for(NSString *item in items)
	{
		NSString *srcDir = [[NSBundle mainBundle] resourcePath];
		NSString *src = [srcDir stringByAppendingPathComponent:item];
		NSString *dst = [[@"~/Library/Application Support/iPhone Simulator/User/Applications" stringByExpandingTildeInPath] stringByAppendingPathComponent:item];
		NSString *src_sb = [src stringByAppendingPathExtension:@"sb"];
		NSString *dst_sb = [dst stringByAppendingPathExtension:@"sb"];

		if(![[NSFileManager defaultManager] copyItemAtPath:src toPath:dst error:&error])
		{
			NSLog(@"copyItemAtPath error %@", error);
		}
		if(![[NSFileManager defaultManager] copyItemAtPath:src_sb toPath:dst_sb error:&error])
		{
			NSLog(@"copyItemAtPath error %@", error);
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
	NSLog(@"Repositioned simulator window.");
}

@end
