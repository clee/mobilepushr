/*
 * FlickrCategory.h
 * ----------------
 * FlickrCategory - extending the built-in NSData, NSString, and NSDictionary classes with methods that make them more useful for interacting with the Flickr web services.
 *
 * Author: Chris Lee <clee@mg8.org>
 * License: GPL v2 <http://www.opensource.org/licenses/gpl-license.php>
 */
#import "FlickrCategory.h"

@implementation NSData (Flickr)
- (NSString *)md5HexHash
{
	unsigned char digest[16];
	char finalDigest[32];

	MD5([self bytes], [self length], digest);
	for (unsigned short int i = 0; i < 16; i++)
		sprintf(finalDigest + (i * 2), "%02x", digest[i]);

	return [NSString stringWithCString: finalDigest length: 32];
}
@end

@implementation NSString (Flickr)
- (NSString *)md5HexHash
{
	return [[self dataUsingEncoding: NSUTF8StringEncoding allowLossyConversion: NO] md5HexHash];
}
@end

@implementation NSDictionary (Flickr)
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

