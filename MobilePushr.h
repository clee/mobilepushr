// MobileTermina.h
#import <UIKit/UIApplication.h>

@class Flickr, UIPreferencesTableCell, UITableCell;

@interface MobilePushr: UIApplication
{
	NSUserDefaults *_settings;
	Flickr *_flickr;
	UIThreePartButton *_button;
}

- (void)popupFailureAlertSheet;

@end
