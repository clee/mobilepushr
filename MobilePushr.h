/*
 * MobilePushr.h
 * -------------
 *
 * Author: Chris Lee <clee@mg8.org>
 * License: GPL v2 <http://www.opensource.org/licenses/gpl-license.php>
 */
#import <UIKit/UIApplication.h>

#define MIGRATED_ATTRIBUTE @"org.mg8.MobilePushr.migrated"
#define IGNORED_ATTRIBUTE @"org.mg8.MobilePushr.ignored"
#define PUSHED_ATTRIBUTE @"org.mg8.MobilePushr.pushed"
#define NAME_ATTRIBUTE @"org.mg8.MobilePushr.name"
#define DESCRIPTION_ATTRIBUTE @"org.mg8.MobilePushr.description"
#define TAGS_ATTRIBUTE @"org.mg8.MobilePushr.tags"
#define PRIVACY_ATTRIBUTE @"org.mg8.MobilePushr.privacy"

@class NSUserDefaults, Flickr, PushrNetUtil, PushablePhotos, UIThreePartButton, UITextLabel, UIProgressBar, UIWindow, UIImageView;

@interface MobilePushr: UIApplication
{
	PushrNetUtil *_netUtil;
	NSUserDefaults *_settings;
	Flickr *_flickr;
	PushablePhotos *_pushablePhotos;
	UIThreePartButton *_button;
	UITextLabel *_label;
	UIProgressBar *_progress;
	UIImageView *_thumbnailView;
	UIView *_shade;
	UIWindow *_window;
}

- (NSArray *)cameraRollPhotos;
- (void)popupFailureAlertSheet;
- (void)setLabelText: (NSString *)labelText;
- (void)updateProgress: (NSNumber *)currentProgress;
- (void)allDone: (NSArray *)responses;

@end
