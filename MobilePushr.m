// MobilePushr.m
#import "MobilePushr.h"

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

@class NSXMLNode, NSXMLElement, NSXMLDocument;

@implementation NSData (Pushr)
- (NSString *)md5HexHash
{
	unsigned char digest[16];
	char finalDigest[32];
	int i;

	MD5([self bytes], [self length], digest);
	for (unsigned short int i = 0; i < 16; i++) {
		sprintf(finalDigest + (i * 2), "%02x", digest[i]);
	}

	return [NSString stringWithCString: finalDigest length: 32];
}
@end

@implementation NSString (Pushr)
- (NSString *)md5HexHash
{
	return [[self dataUsingEncoding: NSUTF8StringEncoding allowLossyConversion: NO] md5HexHash];
}
@end

@implementation NSDictionary (Pushr)
- (NSArray *)pairsJoinedByString: (NSString *)j
{
	NSArray *sortedKeys = [[self allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
	NSMutableArray *allKeysAndObjects = [NSMutableArray array];

	for (unsigned int i = 0; i < [sortedKeys count]; i++) {
		NSString *key = [sortedKeys objectAtIndex: i];
		NSString *val = [self objectForKey: key];
		[allKeysAndObjects addObject: [NSString stringWithFormat: @"%@%@%@", key, j, val]];
	}

	return [NSArray arrayWithArray: allKeysAndObjects];
}
@end


@implementation MobilePushr

- (void) alertSheet: (UIAlertSheet *)sheet buttonClicked: (int)button
{
	BOOL shouldTerminate = FALSE;

	switch (button) {
		case 1: {
			[self openURL: [NSURL URLWithString: PUSHR_AUTH_URL]];
			break;
		}
		default: {
			shouldTerminate = TRUE;
		}
	}

	[sheet dismiss];

	if (shouldTerminate) {
		[self terminate];
	}
}

#pragma mark Flickr API
- (NSString *)getMiniToken
{
	// TODO: Make this actually prompt the user for the mini-token.
	[settings setObject: PUSHR_TEMP_AUTH_CODE forKey: @"mini_token"];
	return [NSString stringWithString: [settings stringForKey: @"mini_token"]];
}

/*
 * This method made possible by extending system classes (without having to 
 * inherit from them.) Hooray!
 */
- (NSURL *)signedURL: (NSDictionary *)parameters
{
	NSMutableString *url = [NSMutableString stringWithFormat: @"%@?", FLICKR_REST_URL];
	NSMutableString *sig = [NSMutableString stringWithString: PUSHR_SHARED_SECRET];

	[sig appendString: [[parameters pairsJoinedByString: @""] componentsJoinedByString: @""]];
	[url appendString: [[parameters pairsJoinedByString: @"="] componentsJoinedByString: @"&"]];
	[url appendString: [NSString stringWithFormat: @"&api_sig=%@", [sig md5HexHash]]];

	return [NSURL URLWithString: url];
}

/*
 * retrieveFullAuthToken makes the assumption that the user has
 * gotten a mini-token from the Flickr page after granting us
 * the access we need.
 * 
 * We have to make a signed call to FLICKR_REST_URL, with the method
 * FLICKR_GET_TOKEN, and the mini-token provided by the user. This should
 * respond with a full authorization token, which we can store and re-use.
 */
- (void)retrieveFullAuthToken
{
	NSArray *keys = [NSArray arrayWithObjects: @"api_key", @"method", @"mini_token", nil];
	NSArray *vals = [NSArray arrayWithObjects: PUSHR_API_KEY, FLICKR_GET_TOKEN, [settings stringForKey: @"mini_token"], nil];
	NSDictionary *params = [NSDictionary dictionaryWithObjects: vals forKeys: keys];

	NSURL *url = [self signedURL: params];
	NSData *responseData = [NSData dataWithContentsOfURL: url];
	NSError *err = nil;

	id responseDoc = [[NSClassFromString(@"NSXMLDocument") alloc] initWithData: responseData options: 0 error: &err];

	NSXMLNode *rsp = [[responseDoc children] objectAtIndex: 0];
#ifdef DEBUG_PARANOID
	if (![[rsp name] isEqualToString: @"rsp"]) {
		NSLog(@"This is not an <rsp> tag! Bailing out.");
		return;
	}
#endif

	id e = [[NSClassFromString(@"NSXMLElement") alloc] initWithXMLString: [rsp XMLString] error: &err];
	if (![[[e attributeForName:@"stat"] stringValue] isEqualToString: @"ok"]) {
		NSLog(@"The status is not 'ok', and we have no error handling!");
		return;
	}

	NSMutableDictionary *flickrDict = [NSMutableDictionary dictionaryWithCapacity: 3];
	NSArray *nodes = [[[e children] lastObject] children];
	NSEnumerator *chain = [nodes objectEnumerator];
	NSXMLNode *node = nil;

	while ((node = [chain nextObject])) {
		if ([[node name] isEqualToString: @"token"]) {
			[settings setObject: [node stringValue] forKey: @"token"];
		} else if ([[node name] isEqualToString: @"user"]) {
			id element = [[NSClassFromString(@"NSXMLElement") alloc] initWithXMLString: [node XMLString] error: &err];
			[settings setObject: [[element attributeForName: @"username"] stringValue] forKey: @"username"];
			[settings setObject: [[element attributeForName: @"nsid"] stringValue] forKey: @"nsid"];
		}
	}

	[settings synchronize];
}

#pragma mark MobilePushr Methods
- (void)sendToGrantPermission
{
	UIAlertSheet *alertSheet = [[UIAlertSheet alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 240.0f)];
	[alertSheet setTitle: @"Can't upload to Flickr"];
	[alertSheet setBodyText: @"This application needs your permission to upload pictures to Flickr."];
	[alertSheet addButtonWithTitle: @"Proceed"];
	[alertSheet addButtonWithTitle: @"Cancel"];
	[alertSheet setDelegate: self];
	[alertSheet popupAlertAnimated: YES];
	[settings setBool: TRUE forKey: @"sentToGetToken"];
}

- (void)showCustomAlertSheet
{
	UIAlertSheet *alertSheet = [[UIAlertSheet alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 240.0f)];
	[alertSheet setTitle: @"Flickr authentication"];
	[alertSheet addTextFieldWithValue: @"" label: @"Enter mini-token"];
	[[alertSheet textField] setPreferredKeyboardType: 7];
	[alertSheet addButtonWithTitle: @"Proceed"];
	[alertSheet addButtonWithTitle: @"Cancel"];
	[alertSheet setDelegate: self];
	[alertSheet popupAlertAnimated: YES];
}

- (void)loadConfiguration
{
	settings = [NSUserDefaults standardUserDefaults];
	NSDictionary *args = [settings dictionaryRepresentation];
	NSArray *keys = [args allKeys];
	NSLog(@"Settings:\n %@", args);

	if (![keys containsObject: @"sentToGetToken"]) {
		NSLog(@"Have to send the user to Flickr to get permission to upload pics.");
		[self sendToGrantPermission];
	}

	if (![keys containsObject: @"mini_token"]) {
		NSLog(@"We sent the user to Flickr, and they should have a mini_token. Make them input it.");
		[settings setObject: [self getMiniToken] forKey: @"mini_token"];
	}

	if (![keys containsObject: @"token"]) {
		NSLog(@"We have a mini_token - trade it in for a full token and the user's NSID and name");
		[self retrieveFullAuthToken];
	}
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

- (NSArray *)flickrTags
{
	NSArray *keys = [NSArray arrayWithObjects: @"api_key", @"method", @"user_id", nil];
	NSArray *vals = [NSArray arrayWithObjects: PUSHR_API_KEY, FLICKR_GET_TAGS, FLICKR_USER_ID, nil];
	NSDictionary *params = [NSDictionary dictionaryWithObjects: vals forKeys: keys];

	NSURL *url = [self signedURL: params];
	NSData *responseData = [NSData dataWithContentsOfURL: url];
	NSLog(@"Created NSData with contents of URL");
	NSError *err = nil;

	id responseDoc = [[NSClassFromString(@"NSXMLDocument") alloc] initWithData: responseData options: 0 error: &err];

	NSXMLNode *rsp = [[responseDoc children] objectAtIndex: 0];
#ifdef DEBUG_PARANOID
	if (![[rsp name] isEqualToString: @"rsp"]) {
		NSLog(@"This is not an <rsp> tag! Bailing out.");
		return [NSArray array];
	}
#endif

	id e = [[NSClassFromString(@"NSXMLElement") alloc] initWithXMLString: [rsp XMLString] error: &err];
	if (![[[e attributeForName:@"stat"] stringValue] isEqualToString: @"ok"]) {
		NSLog(@"The status is not 'ok', and we have no error handling!");
		return [NSArray array];
	}

	NSArray *tagNodes = [[[[[rsp children] lastObject] children] lastObject] children];
	NSEnumerator *tagChain = [tagNodes objectEnumerator];
	NSXMLNode *tagNode = nil;
	NSMutableArray *tags = [NSMutableArray array];

	while ((tagNode = [tagChain nextObject])) {
		[tags addObject: [tagNode stringValue]];
	}

	return [NSArray arrayWithArray: tags];
}

- (void) applicationDidFinishLaunching: (id) unused
{
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
	
	[self showCustomAlertSheet];

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
