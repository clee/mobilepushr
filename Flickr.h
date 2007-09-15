//
//  Flickr
//
//  Created by Chris Lee on 2007-09-14.
//  Copyright (c) 2007. All rights reserved.
//

#define FLICKR_AUTH_URL @"http://flickr.com/services/auth/"
#define FLICKR_REST_URL @"http://api.flickr.com/services/rest/"
#define FLICKR_UPLOAD_URL @"http://api.flickr.com/services/upload/"
#define FLICKR_FINISHED_URL @"http://www.flickr.com/tools/uploader_edit.gne"

#define FLICKR_GET_FROB @"flickr.auth.getFrob"
#define FLICKR_GET_TOKEN @"flickr.auth.getToken"
#define FLICKR_GET_TAGS @"flickr.tags.getListUser"
#define FLICKR_CHECK_TOKEN @"flickr.auth.checkToken"

#define FLICKR_WRITE_PERMS @"write"


#import <Foundation/Foundation.h>

#import "FlickrCategory.h"

@class MobilePushr;

@interface Flickr : NSObject
{
	MobilePushr *_pushr;
	NSUserDefaults *_settings;
}

- (id)initWithPushr: (MobilePushr *)pushr;

- (void)retrieveAuthToken;
- (void)checkToken;

- (NSURL *)signedURL: (NSDictionary *)parameters;
- (NSURL *)authURL;

- (NSString *)frob;
- (NSArray *)tags;

@end
