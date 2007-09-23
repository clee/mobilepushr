/*
 * Flickr.h
 * --------
 *
 * Author: Chris Lee <clee@mg8.org>
 * License: GPL v2 <http://www.opensource.org/licenses/gpl-license.php>
 */

#define FLICKR_AUTH_URL @"http://flickr.com/services/auth/"
#define FLICKR_REST_URL @"http://api.flickr.com/services/rest/"
#define FLICKR_UPLOAD_URL @"http://api.flickr.com/services/upload/"
#define FLICKR_FINISHED_URL @"http://www.flickr.com/tools/uploader_edit.gne"

#define FLICKR_GET_FROB @"flickr.auth.getFrob"
#define FLICKR_GET_TOKEN @"flickr.auth.getToken"
#define FLICKR_GET_TAGS @"flickr.tags.getListUser"
#define FLICKR_CHECK_TOKEN @"flickr.auth.checkToken"

#define FLICKR_WRITE_PERMS @"write"

#if !defined(API_KEY) || !defined(SHARED_SECRET)
#error "You need to define an API key and a shared secret. The MobilePushr API key is not contained in the source code."
#else
#define PUSHR_API_KEY @API_KEY
#define PUSHR_SHARED_SECRET @SHARED_SECRET
#endif

#define MIME_BOUNDARY "----16c17a9ea1d7b327e7489190e394d411----"
#define CONTENT_TYPE "multipart/form-data; boundary=" MIME_BOUNDARY

#import <Foundation/Foundation.h>

#import "FlickrCategory.h"

@class MobilePushr;

@interface Flickr : NSObject
{
	MobilePushr *_pushr;
	NSUserDefaults *_settings;
}

- (id)initWithPushr: (MobilePushr *)pushr;

#pragma mark XML helper functions
- (NSArray *)getXMLNodesNamed: (NSString *)nodeName fromResponse: (NSData *)responseData;
- (NSDictionary *)getXMLNodesAndAttributesFromResponse: (NSData *)responseData;

#pragma mark internal functions
- (NSURL *)signedURL: (NSDictionary *)parameters withBase: (NSString *)base;
- (NSURL *)signedURL: (NSDictionary *)parameters;
- (NSURL *)authURL;
- (NSString *)frob;

#pragma mark externally-visible interface
- (NSArray *)tags;
- (void)sendToGrantPermission;
- (void)tradeFrobForToken;
- (void)checkToken;
- (void)triggerUpload: (id)unused;

@end
