/*
 * MobilePushr.m
 * -------------
 * The main UIApplication subclass - everything starts and ends here.
 *
 * Author: Chris Lee <clee@mg8.org>
 * License: GPL v2 <http://www.opensource.org/licenses/gpl-license.php>
 */
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIPushButton.h>
#import <UIKit/UIPushButton-Original.h>
#import <UIKit/UIControl.h>
#import <UIKit/UITableCell.h>
#import <UIKit/UIPreferencesTableCell.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIView.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIProgressBar.h>
#import <UIKit/UITextField.h>
#import <UIKit/UITextTraits.h>
#import <UIKit/UIAlertSheet.h>
#import <UIKit/UIValueButton.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIView-Rendering.h>
#import <UIKit/UIThreePartButton.h>
#import <UIKit/UIThreePartImageView.h>

#import "MobilePushr.h"
#import "Flickr.h"
#import "PushablePhotos.h"

typedef enum {
    kUIControlEventMouseDown = 1 << 0,
    kUIControlEventMouseMovedInside = 1 << 2, // mouse moved inside control target
    kUIControlEventMouseMovedOutside = 1 << 3, // mouse moved outside control target
    kUIControlEventMouseUpInside = 1 << 6, // mouse up inside control target
    kUIControlEventMouseUpOutside = 1 << 7, // mouse up outside control target
    kUIControlAllEvents = (kUIControlEventMouseDown | kUIControlEventMouseMovedInside | kUIControlEventMouseMovedOutside | kUIControlEventMouseUpInside | kUIControlEventMouseUpOutside)
} UIControlEventMasks;

@implementation MobilePushr

- (void) alertSheet: (UIAlertSheet *)sheet buttonClicked: (int)button
{
	BOOL shouldTerminate;
	switch (button) {
		default: {
			shouldTerminate = TRUE;
		}
	}

	[sheet dismiss];
	[sheet release];

	if (shouldTerminate) {
		[self terminate];
	}
}

#pragma mark MobilePushr Methods

- (NSArray *)cameraRollPhotos
{
	NSString *jpg;
	NSString *cameraRollDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Media/DCIM"];
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: cameraRollDir];
	NSMutableArray *photos = [NSMutableArray array];

	int currentPhotoIndex = 0;
	while ((jpg = [dirEnum nextObject])) {
		if ([[jpg pathExtension] isEqualToString: @"JPG"]) {
			currentPhotoIndex = [[[[jpg pathComponents] lastObject] substringWithRange: NSMakeRange(4, 4)] intValue];
			if (currentPhotoIndex > [_settings integerForKey: @"lastPushedPhotoIndex"])
				[photos addObject: [cameraRollDir stringByAppendingPathComponent: jpg]];
		}
	}

	return [NSArray arrayWithArray: photos];
}

- (void)popupFailureAlertSheet
{
	UIAlertSheet *alertSheet = [[UIAlertSheet alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 240.0f)];
	[alertSheet setTitle: @"Bad news, everyone"];
	[alertSheet setBodyText: @"Somewhere, there's a leak in the pipes, and this application's not Plumbr..."];
	[alertSheet addButtonWithTitle: @"Accept"];
	[alertSheet setDelegate: self];
	[alertSheet popupAlertAnimated: YES];
}

- (void)loadUserInterface
{
	struct CGRect hwRect = [UIHardware fullScreenApplicationContentRect];
	_window = [[UIWindow alloc] initWithContentRect: hwRect];

	struct CGRect appRect = CGRectMake(0.0f, 0.0f, hwRect.size.width, hwRect.size.height);
	UIView *mainView = [[UIView alloc] initWithFrame: appRect];

	[_window orderFront: self];
	[_window makeKey: self];
	[_window setContentView: mainView];
	[_window _setHidden: NO];

	NSLog(@"Creating PushablePhotos view...");
	_pushablePhotos = [[PushablePhotos alloc] initWithFrame: CGRectMake(appRect.origin.x, appRect.origin.y + 44.0f, appRect.size.width, appRect.size.height - (44.0f + 96.0f))];
	[mainView addSubview: _pushablePhotos];
	NSLog(@"Added PushablePhotos subview");

	struct CGRect topBarRect = CGRectMake(0.0f, 0.0f, appRect.size.width, 44.0f);
	UINavigationBar *topBar = [[UINavigationBar alloc] initWithFrame: topBarRect];
	[topBar setBarStyle: 1];
	[mainView addSubview: topBar];

	UINavigationItem *topBarTitle = [[UINavigationItem alloc] initWithTitle: @"Pushr"];
	GSFontRef titleFont = GSFontCreateWithName("Helvetica", kGSFontTraitBold, 24.0f);
	[topBarTitle setFont: titleFont];
	CFRelease(titleFont);

	struct CGRect botBarRect = CGRectMake(0.0f, (appRect.size.height - 96.0f), appRect.size.width, 96.0f);
	UIThreePartImageView *bottomBar = [[UIThreePartImageView alloc] initWithFrame: botBarRect];
	[bottomBar setImage: [UIImage imageNamed: @"bottombar.png"]];
	CDAnonymousStruct4 barSlices = {
		.left   = { .origin = { .x =  0.0f, .y = 0.0f }, .size = { .width = 2.0f, .height = 96.0f } },
		.middle = { .origin = { .x =  2.0f, .y = 0.0f }, .size = { .width = 2.0f, .height = 96.0f } },
		.right  = { .origin = { .x =  4.0f, .y = 0.0f }, .size = { .width = 2.0f, .height = 96.0f } },
	};
	[bottomBar setSlices: barSlices];
	[bottomBar setAlpha: 0.75f];
	[mainView addSubview: bottomBar];

	_button = [[[UIThreePartButton alloc] initWithTitle: @"Push to Flickr" autosizesToFit: YES] autorelease];

	GSFontRef buttonFont = GSFontCreateWithName("Helvetica", kGSFontTraitBold, 22.0f);
	[_button setTitleFont: buttonFont];
	CFRelease(buttonFont);

	float blackColor[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
	struct CGRect buttonRect = CGRectMake(20.0f, (appRect.size.height - 74.0f), appRect.size.width - 40.0f, 52.0f);
	[_button setFrame: buttonRect];
	[_button setPressedBackgroundImage: [UIImage imageNamed: @"mainbutton_pressed.png"]];
	[_button setBackgroundImage: [UIImage imageNamed: @"mainbutton.png"]];
	// [_button setImage:[UIImage imageNamed:@"refresh.png"]];

	// Pieces as deduced from the ChooseAudioPhone PNG from MobilePhone.app
	CDAnonymousStruct4 buttonPieces = {
		.left   = { .origin = { .x =  0.0f, .y = 0.0f }, .size = { .width = 14.0f, .height = 52.0f } },
		.middle = { .origin = { .x = 15.0f, .y = 0.0f }, .size = { .width =  2.0f, .height = 52.0f } },
		.right  = { .origin = { .x = 17.0f, .y = 0.0f }, .size = { .width = 14.0f, .height = 52.0f } },
	};

	[_button setBackgroundSlices: buttonPieces];

	[_button setShadowColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), blackColor)];
	[_button setShadowOffset: -1.0f];
	[_button setDrawsShadow: YES];

	[_button addTarget: self action: @selector(buttonReleased) forEvents: kUIControlEventMouseUpInside];
	[_button setDrawContentsCentered: YES];
	[_button setEnabled: YES];

	[mainView addSubview: _button];

	[UIView beginAnimations: nil];
	[UIView setAnimationCurve: kUIAnimationCurveEaseIn];
	[UIView setAnimationDuration: 1.0];

	// [background setAlpha: 1.0f];

	[topBar pushNavigationItem: topBarTitle];
	// [topBar showLeftButton: @"Left" withStyle: 1 rightButton: @"Right" withStyle: 2];
	[UIView endAnimations];
	[topBar release];
	[topBarTitle release];
	[bottomBar release];
	[mainView release];
	_thumbnailView = nil;
}

- (void)loadConfiguration
{
	_settings = [NSUserDefaults standardUserDefaults];
	_flickr = [[Flickr alloc] initWithPushr: self];

	if ([_settings boolForKey: @"sentToGetToken"] != TRUE) {
		NSLog(@"Have to send the user to Flickr to get permission to upload pics.");
		[_flickr sendToGrantPermission];
		return;
	}

	if ([_settings stringForKey: @"frob"] != nil) {
		NSLog(@"We had a frob - trade it in for a token, the user's NSID, and username.");
		[_flickr tradeFrobForToken];
	}

	if ([_settings stringForKey: @"token"] != nil) {
		NSLog(@"We have a token - test it to make sure it works.");
		[_flickr checkToken];
	}

	NSLog(@"Our token is: %@", [_settings stringForKey: @"token"]);
}

- (void)buttonReleased
{
	[_button setEnabled: NO];
	[_button setBackgroundImage: [UIImage imageNamed: @"mainbutton_inactive.png"]];
	id mainView = [_button superview];
	float blackColor[4] = { 0.0f, 0.0f, 0.0f, 0.5f };
	float transparent[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
	float white[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
	[mainView setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), blackColor)];
	struct CGRect hwRect = [UIHardware fullScreenApplicationContentRect];
	_label = [[UITextLabel alloc] initWithFrame: CGRectMake(hwRect.origin.x + 20.0f, hwRect.origin.y + 60.0f, hwRect.size.width - 40.0f, 20.0f)];
	[_label setText: @"Please Wait"];
	[_label setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), transparent)];
	[_label setColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), white)];
	[_label setCentersHorizontally: YES];
	[mainView addSubview: _label];

	_progress = [[UIProgressBar alloc] initWithFrame: CGRectMake(hwRect.origin.x + 20.0f, hwRect.origin.y + 80.0f, hwRect.size.width - 40.0f, 60.0f)];
	[_progress setProgress: 0];
	[_progress setStyle: 0];
	[mainView addSubview: _progress];

	[NSThread detachNewThreadSelector: @selector(triggerUpload:) toTarget: _flickr withObject: nil];
}

- (void)startingToPush: (NSString *)photoPath
{
	struct CGRect hwRect = [UIHardware fullScreenApplicationContentRect];
	NSString *thumbnailPath = [[photoPath stringByDeletingPathExtension] stringByAppendingPathExtension: @"THM"];
	UIImage *thumbnailImage = [UIImage imageAtPath: thumbnailPath];

	struct CGRect thumbnailRect = CGRectMake(hwRect.origin.x + ((hwRect.size.width - [thumbnailImage size].width) / 2.0), hwRect.origin.y + ((hwRect.size.height - [thumbnailImage size].height) / 2.0), [thumbnailImage size].width, [thumbnailImage size].height);
	_thumbnailView = [[UIImageView alloc] initWithFrame: thumbnailRect];
	[_thumbnailView setImage: thumbnailImage];

	id mainview = [_label superview];
	[mainview addSubview: _thumbnailView];
}

- (void)donePushing: (NSString *)photoPath
{
	[_thumbnailView removeFromSuperview];
	[_thumbnailView release];
}

- (void)setLabelText: (NSString *)labelText
{
	[_label setText: labelText];
}

- (void)updateProgress: (NSNumber *)currentProgress
{
	[_progress setProgress: [currentProgress floatValue]];
}

- (void)allDone: (NSArray *)responses
{
	[_thumbnailView removeFromSuperview];
	[_progress removeFromSuperview];
	[_label removeFromSuperview];
	[_button setEnabled: YES];
	[_button setBackgroundImage: [UIImage imageNamed: @"mainbutton.png"]];
}

- (void)applicationDidFinishLaunching: (id) unused
{
	[self loadConfiguration];
	[self loadUserInterface];
}

- (void)dealloc
{
	[_thumbnailView release];
	[_progress release];
	[_label release];
	[_button release];
	[_window release];
	[_flickr release];
	[super dealloc];
	
}

@end
