// MobileTermina.h
#import <UIKit/UIApplication.h>
#import <openssl/md5.h>

#define FLICKR_REST_URL @"http://api.flickr.com/services/rest/"
#define FLICKR_UPLOAD_URL @"http://api.flickr.com/services/upload/"
#define FLICKR_FINISHED_URL @"http://www.flickr.com/tools/uploader_edit.gne"
#define FLICKR_GET_TAGS @"flickr.tags.getListUser"
#define FLICKR_GET_TOKEN @"flickr.auth.getFullToken"
#define FLICKR_USER_ID @"12031124@N00"



@interface NSString (Pushr)
- (NSString *)md5HexHash;
@end

@interface NSData (Pushr)
- (NSString *)md5HexHash;
@end

@interface NSDictionary (Pushr)
- (NSArray *)pairsJoinedByString: (NSString *)j;
@end;

@class UIPreferencesTableCell, UITableCell;

@interface MobilePushr: UIApplication {
	BOOL haveSent, haveMiniToken, haveToken, haveNSID;
	NSUserDefaults *settings;
	UIPreferencesTableCell *prefCell;
	UITableCell *buttonCell;
}

@end
