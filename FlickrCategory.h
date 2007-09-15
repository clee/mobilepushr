//
//  FlickrCategory
//
//  Created by Chris Lee on 2007-09-15.
//  Copyright (c) 2007. All rights reserved.
//

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
