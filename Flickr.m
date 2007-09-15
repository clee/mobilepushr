//
//  Flickr interaction class
//
//  Created by Chris Lee on 2007-09-14.
//  Copyright (c) 2007. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIAlertSheet.h>
#import "Flickr.h"
#import "MobilePushr.h"

@class NSXMLNode, NSXMLElement, NSXMLDocument;

@implementation Flickr

- (id)initWithPushr: (MobilePushr *)pushr
{
	if (![super init])
		return nil;

	[_pushr release];
	[_settings release];
	
	NSLog(@"Flickr: Released things that may not have even been initialized!");

	_pushr = [pushr retain];
	_settings = [NSUserDefaults standardUserDefaults];
	NSLog(@"Flickr: grabbed settings");

	return self;
}

#pragma mark UIAlertSheet delegation
- (void) alertSheet: (UIAlertSheet *)sheet buttonClicked: (int)button
{
	BOOL shouldTerminate = NO;

	switch (button) {
		case 1:
			[_pushr openURL: [self authURL] asPanel: YES];
			break;
		default:
			shouldTerminate = YES;
	}

	[sheet dismiss];

	if (shouldTerminate)
		[_pushr terminate];
}


- (BOOL)sanityCheck: (id)responseDocument error: (NSError *)err
{
	NSXMLNode *rsp = [[responseDocument children] objectAtIndex: 0];
	if (![[rsp name] isEqualToString: @"rsp"]) {
		NSLog(@"This is not an <rsp> tag! Bailing out.");
		return FALSE;
	}

	id e = [[NSClassFromString(@"NSXMLElement") alloc] initWithXMLString: [rsp XMLString] error: &err];
	if (![[[e attributeForName: @"stat"] stringValue] isEqualToString: @"ok"]) {
		NSLog(@"The status is not 'ok', and we have no error recovery.");
		return FALSE;
	}

	return TRUE;
}

- (void)popupFailureAlertSheet
{
	UIAlertSheet *alertSheet = [[UIAlertSheet alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 240.0f)];
	[alertSheet setTitle: @"Bad news, everyone"];
	[alertSheet setBodyText: @"Somewhere, there's a leak in the pipes, and this application's not Plumbr..."];
	[alertSheet addButtonWithTitle: @"Accept"];
	[alertSheet setDelegate: _pushr];
	[alertSheet popupAlertAnimated: YES];
}

/*
 * Get a frob from Flickr, to put in the URL that we send the user to to get their permission to upload pics.
 */
- (NSString *)frob
{
	NSArray *keys = [NSArray arrayWithObjects: @"api_key", @"method", nil];
	NSArray *vals = [NSArray arrayWithObjects: PUSHR_API_KEY, FLICKR_GET_FROB, nil];
	NSDictionary *params = [NSDictionary dictionaryWithObjects: vals forKeys: keys];

	NSURL *url = [self signedURL: params];
	NSData *responseData = [NSData dataWithContentsOfURL: url];
	NSError *err = nil;

	id responseDoc = [[NSClassFromString(@"NSXMLDocument") alloc] initWithData: responseData options: 0 error: &err];
	if (![self sanityCheck: responseDoc error: err]) {
		NSLog(@"Failed the sanity check getting the frob. Bailing!");
		[self popupFailureAlertSheet];
		return nil;
	}

	NSXMLNode *node = [[[[responseDoc children] lastObject] children] lastObject];
	
	if (![[node name] isEqualToString: @"frob"]) {
		NSLog(@"We got an 'ok' response but no frob...");
		[self popupFailureAlertSheet];
		return nil;
	}
	
	[_settings setObject: [node stringValue] forKey: @"frob"];

	return [NSString stringWithString: [node stringValue]];
}

/*
 * This method made possible by extending system classes (without having to 
 * inherit from them.) Hooray!
 */
- (NSURL *)signedURL: (NSDictionary *)parameters withBase: (NSString *)base
{
	NSMutableString *url = [NSMutableString stringWithFormat: @"%@?", base];
	NSMutableString *sig = [NSMutableString stringWithString: PUSHR_SHARED_SECRET];

	[sig appendString: [[parameters pairsJoinedByString: @""] componentsJoinedByString: @""]];
	[url appendString: [[parameters pairsJoinedByString: @"="] componentsJoinedByString: @"&"]];
	[url appendString: [NSString stringWithFormat: @"&api_sig=%@", [sig md5HexHash]]];

	NSLog(@"Created URL: %@", url);
	return [NSURL URLWithString: url];
}

- (NSURL *)signedURL: (NSDictionary *)parameters
{
	return [self signedURL: parameters withBase: FLICKR_REST_URL];
}

- (NSURL *)authURL
{
	NSArray *keys = [NSArray arrayWithObjects: @"api_key", @"perms", @"frob", nil];
	NSArray *vals = [NSArray arrayWithObjects: PUSHR_API_KEY, FLICKR_WRITE_PERMS, [self frob], nil];
	NSDictionary *params = [NSDictionary dictionaryWithObjects: vals forKeys: keys];

	return [self signedURL: params withBase: FLICKR_AUTH_URL];
}

/*
 */
- (void)retrieveAuthToken
{
	NSArray *keys = [NSArray arrayWithObjects: @"api_key", @"method", @"frob", nil];
	NSArray *vals = [NSArray arrayWithObjects: PUSHR_API_KEY, FLICKR_GET_TOKEN, [_settings stringForKey: @"frob"], nil];
	NSDictionary *params = [NSDictionary dictionaryWithObjects: vals forKeys: keys];

	NSData *responseData = [NSData dataWithContentsOfURL: [self signedURL: params]];
	NSError *err = nil;

	id responseDoc = [[NSClassFromString(@"NSXMLDocument") alloc] initWithData: responseData options: 0 error: &err];
	if (![self sanityCheck: responseDoc error: err]) {
		NSLog(@"Failed the sanity check getting the token. Bailing!");
		[self popupFailureAlertSheet];
		return;
	}

	NSArray *nodes = [[[[[responseDoc children] lastObject] children] lastObject] children];
	NSEnumerator *chain = [nodes objectEnumerator];
	NSXMLNode *node = nil;

	while ((node = [chain nextObject])) {
		if ([[node name] isEqualToString: @"token"]) {
			[_settings setObject: [node stringValue] forKey: @"token"];
		} else if ([[node name] isEqualToString: @"user"]) {
			id element = [[NSClassFromString(@"NSXMLElement") alloc] initWithXMLString: [node XMLString] error: &err];
			[_settings setObject: [[element attributeForName: @"username"] stringValue] forKey: @"username"];
			[_settings setObject: [[element attributeForName: @"nsid"] stringValue] forKey: @"nsid"];
		}
	}

	[_settings synchronize];
}

- (void)checkToken
{
	NSArray *keys = [NSArray arrayWithObjects: @"api_key", @"perms", @"method", nil];
	NSArray *vals = [NSArray arrayWithObjects: PUSHR_API_KEY, FLICKR_WRITE_PERMS, FLICKR_CHECK_TOKEN, nil];
	NSDictionary *params = [NSDictionary dictionaryWithObjects: vals forKeys: keys];
	NSData *responseData = [NSData dataWithContentsOfURL: [self signedURL: params]];
	NSError *err = nil;

	id responseDoc = [[NSClassFromString(@"NSXMLDocument") alloc] initWithData: responseData options: 0 error: &err];
	if (![self sanityCheck: responseDoc error: err]) {
		NSLog(@"Failed the sanity check when verifying our token. Bailing!");
		[self popupFailureAlertSheet];
		return;
	}
	
	NSLog(@"Well, our token seems good for now.");
	if ([[[_settings dictionaryRepresentation] allKeys] containsObject: @"frob"])
		[_settings setObject: nil forKey: @"frob"];
}

/*
 * Get the tags the user has already set on their photos. 
 * TODO: At some point, we should offer a UI to let them tag their future photos with the same tags.
 */
- (NSArray *)tags
{
	NSArray *keys = [NSArray arrayWithObjects: @"api_key", @"method", nil];
	NSArray *vals = [NSArray arrayWithObjects: PUSHR_API_KEY, FLICKR_GET_TAGS, nil];
	NSDictionary *params = [NSDictionary dictionaryWithObjects: vals forKeys: keys];

	NSURL *url = [self signedURL: params];
	NSData *responseData = [NSData dataWithContentsOfURL: url];
	NSError *err = nil;

	id responseDoc = [[NSClassFromString(@"NSXMLDocument") alloc] initWithData: responseData options: 0 error: &err];
	if (![self sanityCheck: responseDoc error: err]) {
		NSLog(@"Failed the sanity check when verifying our tags. Bailing!");
		[self popupFailureAlertSheet];
		return [NSArray array];
	}

	NSArray *tagNodes = [[[[[[[responseDoc children] lastObject] children] lastObject] children] lastObject] children];
	NSEnumerator *tagChain = [tagNodes objectEnumerator];
	NSXMLNode *tagNode = nil;
	NSMutableArray *tags = [NSMutableArray array];

	while ((tagNode = [tagChain nextObject])) {
		[tags addObject: [tagNode stringValue]];
	}

	return [NSArray arrayWithArray: tags];
}



@end
