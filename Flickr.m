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

#include <unistd.h>

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

	return self;
}

#pragma mark UIAlertSheet delegation
- (void) alertSheet: (UIAlertSheet *)sheet buttonClicked: (int)button
{
	BOOL shouldTerminate = NO;

	switch (button) {
		case 1:
			[_pushr openURL: [self authURL]];
			break;
		default:
			shouldTerminate = YES;
	}

	[sheet dismiss];

	if (shouldTerminate)
		[_pushr terminate];
}

- (void)sendToGrantPermission
{
	UIAlertSheet *alertSheet = [[UIAlertSheet alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 240.0f)];
	[alertSheet setTitle: @"Can't upload to Flickr"];
	[alertSheet setBodyText: @"Pushr needs your permission to upload pictures to Flickr."];
	[alertSheet addButtonWithTitle: @"Proceed"];
	[alertSheet addButtonWithTitle: @"Cancel"];
	[alertSheet setDelegate: self];
	[alertSheet popupAlertAnimated: YES];
	[_settings setBool: TRUE forKey: @"sentToGetToken"];
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
		[_pushr popupFailureAlertSheet];
		return nil;
	}

	NSXMLNode *node = [[[[responseDoc children] lastObject] children] lastObject];
	
	if (![[node name] isEqualToString: @"frob"]) {
		NSLog(@"We got an 'ok' response but no frob...");
		[_pushr popupFailureAlertSheet];
		return nil;
	}
	
	[_settings setObject: [node stringValue] forKey: @"frob"];
	[_settings synchronize];

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
 * We have a frob that Flickr generated, and we used it in the URL we sent the user to (so that they could give us permission to upload pictures to their account). Now, we assume the user clicked on the 'Okay!' button the page we sent them to go click, and our frob can now be traded for a token.
 */
- (void)tradeFrobForToken
{
	NSArray *keys = [NSArray arrayWithObjects: @"api_key", @"method", @"frob", nil];
	NSArray *vals = [NSArray arrayWithObjects: PUSHR_API_KEY, FLICKR_GET_TOKEN, [_settings stringForKey: @"frob"], nil];
	NSDictionary *params = [NSDictionary dictionaryWithObjects: vals forKeys: keys];

	NSData *responseData = [NSData dataWithContentsOfURL: [self signedURL: params]];
	NSError *err = nil;

	id responseDoc = [[NSClassFromString(@"NSXMLDocument") alloc] initWithData: responseData options: 0 error: &err];
	if (![self sanityCheck: responseDoc error: err]) {
		NSLog(@"Failed the sanity check getting the token. Bailing!");
		[_pushr popupFailureAlertSheet];
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

	[_settings removeObjectForKey: @"frob"];
	[_settings synchronize];
}

- (void)checkToken
{
	NSArray *keys = [NSArray arrayWithObjects: @"api_key", @"auth_token", @"method", nil];
	NSArray *vals = [NSArray arrayWithObjects: PUSHR_API_KEY, [_settings stringForKey: @"token"], FLICKR_CHECK_TOKEN, nil];
	NSDictionary *params = [NSDictionary dictionaryWithObjects: vals forKeys: keys];
	NSData *responseData = [NSData dataWithContentsOfURL: [self signedURL: params]];
	NSError *err = nil;

	id responseDoc = [[NSClassFromString(@"NSXMLDocument") alloc] initWithData: responseData options: 0 error: &err];
	if (![self sanityCheck: responseDoc error: err]) {
		NSLog(@"Failed the sanity check when verifying our token. Bailing!");
		[_settings setBool: FALSE forKey: @"sentToGetToken"];
		[self sendToGrantPermission];
		return;
	}

	NSLog(@"Well, our token seems good.");
}

- (NSString *)uploadPicture: (NSString *)pathToJPG
{
	NSString *token = [_settings stringForKey: @"token"];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys: PUSHR_API_KEY, @"api_key", token, @"auth_token", nil];
	NSArray *pairs = [params pairsJoinedByString: @""];
	NSString *api_sig = [NSString stringWithFormat: @"%@%@", PUSHR_SHARED_SECRET, [pairs componentsJoinedByString: @""]];
	[params setObject: [api_sig md5HexHash] forKey: @"api_sig"];
	[params setObject: [NSData dataWithContentsOfFile: pathToJPG] forKey: @"photo"];

	NSMutableData *body = [[NSMutableData alloc] initWithLength: 0];
	[body appendData: [[[[NSString alloc] initWithFormat: @"--%@\r\n", @MIME_BOUNDARY] autorelease] dataUsingEncoding: NSUTF8StringEncoding]];

	NSEnumerator *enumerator = [params keyEnumerator];
	id key = nil;
	while ((key = [enumerator nextObject])) {
		id val = [params objectForKey: key];
		id keyHeader = nil;
		if ([key isEqualToString: @"photo"]) {
			// If this is the photo...
			keyHeader = [[NSString stringWithFormat: @"Content-Disposition: form-data; name=\"photo\"; filename=\"%@\"\r\nContent-Type: image/jpeg\r\n\r\n", pathToJPG] dataUsingEncoding: NSUTF8StringEncoding];
			[body appendData: keyHeader];
			[body appendData: val];
		} else {
			// Treat all other values as strings.
			keyHeader = [NSString stringWithFormat: @"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key];
			[body appendData: [keyHeader dataUsingEncoding: NSUTF8StringEncoding]];
			[body appendData: [val dataUsingEncoding: NSUTF8StringEncoding]];			
		}
		[body appendData: [[NSString stringWithFormat: @"\r\n--%@\r\n", @MIME_BOUNDARY] dataUsingEncoding: NSUTF8StringEncoding]];
	}

	[body appendData: [[NSString stringWithString: @"--\r\n"] dataUsingEncoding: NSUTF8StringEncoding]];
	long bodyLength = [body length];

	CFURLRef uploadURL = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)FLICKR_UPLOAD_URL, NULL);
	CFHTTPMessageRef _request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("POST"), uploadURL, kCFHTTPVersion1_1);
	CFRelease(uploadURL);
	uploadURL = NULL;

	CFHTTPMessageSetHeaderFieldValue(_request, CFSTR("Content-Type"), CFSTR(CONTENT_TYPE));
	CFHTTPMessageSetHeaderFieldValue(_request, CFSTR("Host"), CFSTR("api.flickr.com"));
	CFHTTPMessageSetHeaderFieldValue(_request, CFSTR("Content-Length"), (CFStringRef)[NSString stringWithFormat: @"%d", bodyLength]);
	CFHTTPMessageSetBody(_request, (CFDataRef)body);
	[body release];

	CFReadStreamRef _readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, _request);
	CFReadStreamOpen(_readStream);

	NSMutableString *responseString = [NSMutableString string];
	CFIndex numBytesRead;
	long bytesWritten, previousBytesWritten = 0;
	UInt8 buf[1024];
	BOOL doneUploading = NO;

	while (!doneUploading) {
		CFNumberRef cfSize = CFReadStreamCopyProperty(_readStream, kCFStreamPropertyHTTPRequestBytesWrittenCount);
		CFNumberGetValue(cfSize, kCFNumberLongType, &bytesWritten);
		CFRelease(cfSize);
		cfSize = NULL;
		if (bytesWritten > previousBytesWritten) {
			previousBytesWritten = bytesWritten;
			NSNumber *progress = [NSNumber numberWithFloat: ((float)bytesWritten / (float)bodyLength)];
			[_pushr performSelectorOnMainThread: @selector(updateProgress:)  withObject: progress waitUntilDone: YES];
		}

		if (!CFReadStreamHasBytesAvailable(_readStream)) {
			usleep(3600);
			continue;
		}

		numBytesRead = CFReadStreamRead(_readStream, buf, 1024);
		[responseString appendFormat: @"%s", buf];

		if (CFReadStreamGetStatus(_readStream) == kCFStreamStatusAtEnd) doneUploading = YES;
	}
#if 0
	CFHTTPMessageRef _responseHeaderRef = (CFHTTPMessageRef)CFReadStreamCopyProperty(_readStream, kCFStreamPropertyHTTPResponseHeader);
	NSDictionary *_responseHeaders = (NSDictionary *)CFHTTPMessageCopyAllHeaderFields(_responseHeaderRef);
	NSLog(@"Header data was: \n---\n%@\n---\n", _responseHeaders);
	CFRelease(_responseHeaderRef);
	_responseHeaderRef = NULL;
#endif

	CFReadStreamClose(_readStream);
	CFRelease(_request);
	_request = NULL;
	CFRelease(_readStream);
	_readStream = NULL;

	return [NSString stringWithString: responseString];
}

-(void)triggerUpload: (id)unused
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *photos = [_pushr cameraRollPhotos];
	NSMutableArray *responses = [NSMutableArray array];

	NSEnumerator *enumerator = [photos objectEnumerator];
	id photo = nil;
	while ((photo = [enumerator nextObject])) {
		int currentPhotoIndex = [[[[photo componentsSeparatedByString: @"/"] lastObject] substringWithRange: NSMakeRange(4, 4)] intValue];
		if ([_settings integerForKey: @"lastPushedPhotoIndex"] < currentPhotoIndex) {
			[responses addObject: [self uploadPicture: photo]];
			[_settings setInteger: currentPhotoIndex forKey: @"lastPushedPhotoIndex"];
		}
	}

	[_pushr performSelectorOnMainThread: @selector(allDone:) withObject: responses waitUntilDone: YES];
	[pool release];
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
		[_pushr popupFailureAlertSheet];
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
