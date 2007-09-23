/*
 * FlickrCategory.h
 * ----------------
 *
 * Author: Chris Lee <clee@mg8.org>
 * License: GPL v2 <http://www.opensource.org/licenses/gpl-license.php>
*/  

#import <Foundation/Foundation.h>
#import <openssl/md5.h>

@interface NSString (Flickr)
- (NSString *)md5HexHash;
@end

@interface NSData (Flickr)
- (NSString *)md5HexHash;
@end

@interface NSDictionary (Flickr)
- (NSArray *)pairsJoinedByString: (NSString *)j;
@end;
