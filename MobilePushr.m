// MobilePushr.m
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITableCell.h>
#import <UIKit/UIPreferencesTableCell.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIView-Rendering.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UITextField.h>
#import <UIKit/UITextTraits.h>
#import <UIKit/UIAlertSheet.h>
#import <UIKit/UIValueButton.h>

#include <stdio.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

#import "MobilePushr.h"
#import "Flickr.h"


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

	if (shouldTerminate) {
		[self terminate];
	}
}

#pragma mark MobilePushr Methods
- (void)sendToGrantPermission
{
	UIAlertSheet *alertSheet = [[UIAlertSheet alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 240.0f)];
	NSLog(@"Alert sheet style: %d", [alertSheet alertSheetStyle]);
	[alertSheet setTitle: @"Can't upload to Flickr"];
	[alertSheet setBodyText: @"Pushr needs your permission to upload pictures to Flickr."];
	[alertSheet addButtonWithTitle: @"Proceed"];
	[alertSheet addButtonWithTitle: @"Cancel"];
	[alertSheet setDelegate: _flickr];
	[alertSheet popupAlertAnimated: YES];
	NSLog(@"Alert sheet style: %d", [alertSheet alertSheetStyle]);
	[_settings setBool: TRUE forKey: @"sentToGetToken"];
}

- (void)loadConfiguration
{
	_flickr = [[Flickr alloc] initWithPushr: self];
	_settings = [NSUserDefaults standardUserDefaults];
	NSDictionary *args = [_settings dictionaryRepresentation];
	NSArray *keys = [args allKeys];
	NSLog(@"Settings:\n %@", args);

	if (![keys containsObject: @"sentToGetToken"]) {
		NSLog(@"Have to send the user to Flickr to get permission to upload pics.");
		[self sendToGrantPermission];
	}

	if ([keys containsObject: @"frob"]) {
		NSLog(@"We had a frob - trade it in for a token, the user's NSID, and username.");
		[_flickr retrieveAuthToken];
	}
	
	if ([keys containsObject: @"token"]) {
		NSLog(@"We have a token - test it to make sure it works.");
		[_flickr checkToken];
	}
	
	NSLog(@"Our token is: %@", [_settings stringForKey: @"token"]);
}

- (NSArray *)cameraRollPhotos
{
	NSString *jpg;
	NSString *cameraRollDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Media/DCIM"];
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: cameraRollDir];
	NSMutableArray *photos = [NSMutableArray array];

	while ((jpg = [dirEnum nextObject])) {
		if ([[jpg pathExtension] isEqualToString: @"JPG"]) {
			[photos addObject: [cameraRollDir stringByAppendingPathComponent: jpg]];
		}
	}

	return [NSArray arrayWithArray: photos];
}

- (void) applicationDidFinishLaunching: (id) unused
{
	NSLog(@"Default image = %@", [self createApplicationDefaultPNG]);
	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];

	UIWindow *window = [[UIWindow alloc] initWithContentRect: rect];
	UIImageView *background = [[[UIImageView alloc] initWithFrame: CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height)] autorelease];
	[background setImage: [UIImage defaultDesktopImage]];

	UIView *mainView = [[UIView alloc] initWithFrame: rect];
	[mainView addSubview: background];

	[window setContentView: mainView];
	[window orderFront: self];
	[window makeKey: self];
	[window _setHidden: NO];

	[self loadConfiguration];

/*
	NSArray *photos = [self cameraRollPhotos];
	for (int i = 0; i < [photos count]; i++) {
		NSLog(@"Photo at %@", [photos objectAtIndex: i]);
	}
	
	NSArray *tags = [self flickrTags];
	for (int i = 0; i < [tags count]; i++) {
		NSLog(@"Tag found: %@", [tags objectAtIndex: i]);
	}
 */
}

@end
