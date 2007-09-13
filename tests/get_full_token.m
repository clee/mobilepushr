#import <Foundation/Foundation.h>

#include "common.h"

NSDictionary *getFullToken(NSString *miniToken)
{
	NSArray *keys = [NSArray arrayWithObjects: @"api_key", @"method", @"mini_token", nil];
	NSArray *vals = [NSArray arrayWithObjects: PUSHR_API_KEY, FLICKR_GET_TOKEN, miniToken, nil];
	NSDictionary *params = [NSDictionary dictionaryWithObjects: vals forKeys: keys];

	NSURL *url = signedURL(params);
	NSData *responseData = [NSData dataWithContentsOfURL: url];
	NSError *err = nil;

	id responseDoc = [[NSClassFromString(@"NSXMLDocument") alloc] initWithData: responseData options: 0 error: &err];

	NSXMLNode *rsp = [[responseDoc children] objectAtIndex: 0];
#ifdef DEBUG_PARANOID
	if (![[rsp name] isEqualToString: @"rsp"]) {
		NSLog(@"This is not an <rsp> tag! Bailing out.");
		return [NSArray array];
	}
#endif

	NSLog(@"So the response is valid...");

	id e = [[NSClassFromString(@"NSXMLElement") alloc] initWithXMLString: [rsp XMLString] error: &err];
	if (![[[e attributeForName:@"stat"] stringValue] isEqualToString: @"ok"]) {
		NSLog(@"The status is not 'ok', and we have no error handling!");
		return [NSArray array];
	} else {
		NSLog(@"Status is 'ok'");
	}

	NSMutableDictionary *flickrDict = [NSMutableDictionary dictionaryWithCapacity: 3];
	NSArray *nodes = [[[e children] lastObject] children];
	NSEnumerator *chain = [nodes objectEnumerator];
	NSXMLNode *node = nil;

	while ((node = [chain nextObject])) {
		if ([[node name] isEqualToString: @"token"]) {
			NSLog(@"Token: %@", [node stringValue]);
			[flickrDict setObject: [node stringValue] forKey: @"token"];
		} else if ([[node name] isEqualToString: @"user"]) {
			id element = [[NSClassFromString(@"NSXMLElement") alloc] initWithXMLString: [node XMLString] error: &err];
			NSLog(@"Username: %@", [element attributeForName: @"username"]);
			[flickrDict setObject: [[element attributeForName: @"username"] stringValue] forKey: @"username"];
			NSLog(@"NSID: %@", [element attributeForName: @"nsid"]);
			[flickrDict setObject: [[element attributeForName: @"nsid"] stringValue] forKey: @"nsid"];
		}
	}

	return [NSDictionary dictionaryWithDictionary: flickrDict];
}

int main(int a, char **b)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *args = [defaults dictionaryRepresentation];

	if (![[args allKeys] containsObject: @"minitoken"]) {
		fprintf(stderr, "You need to supply a '-minitoken' argument.\n");
		[pool release];
		return -1;
	}

	NSString *mt = [defaults stringForKey: @"minitoken"];

	NSLog(@"Result of getFullToken: %@", getFullToken(mt));

	[pool release];
	return 0;
}
