#import <Foundation/Foundation.h>
#include <openssl/md5.h>

#define FLICKR_REST_URL @"http://api.flickr.com/services/rest/"
#define FLICKR_UPLOAD_URL @"http://api.flickr.com/services/upload/"
#define FLICKR_FINISHED_URL @"http://www.flickr.com/tools/uploader_edit.gne"
#define FLICKR_GET_TAGS @"flickr.tags.getListUser"
#define FLICKR_GET_TOKEN @"flickr.auth.getFullToken"
#define FLICKR_USER_ID @"12031124@N00"


@interface NSData (Common)
- (NSString *)md5HexHash;
@end

@interface NSString (Common)
- (NSString *)md5HexHash;
@end

@implementation NSData (Common)
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

@implementation NSString (Common)
- (NSString *)md5HexHash
{
	return [[self dataUsingEncoding: NSUTF8StringEncoding allowLossyConversion: NO] md5HexHash];
}
@end

NSURL *signedURL(NSDictionary *parameters)
{
	NSMutableString *sig = [NSMutableString stringWithString: PUSHR_SHARED_SECRET];
	NSMutableString *url = [NSMutableString stringWithFormat: @"%@?", FLICKR_REST_URL];
	NSMutableArray *pairs = [NSMutableArray array];
	NSArray *sortedKeys = [[parameters allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];

	for (unsigned int i = 0; i < [sortedKeys count]; i++) {
		NSString *k = [sortedKeys objectAtIndex: i];
		NSString *v = [parameters objectForKey: k];
		[sig appendString: [NSString stringWithFormat: @"%@%@", k, v]];
		[pairs addObject: [NSString stringWithFormat: @"%@=%@", k, v]];
	}

	[pairs addObject: [NSString stringWithFormat: @"api_sig=%@", [sig md5HexHash]]];
	[url appendString: [pairs componentsJoinedByString: @"&"]];

	NSLog(@"Created URL: %@", url);

	return [NSURL URLWithString: url];
}
