/*
 * MobilePushr.h
 * -------------
 *
 * Author: Chris Lee <clee@mg8.org>
 * License: GPL v2 <http://www.opensource.org/licenses/gpl-license.php>
 */
#import <UIKit/UIApplication.h>

@class NSUserDefaults, Flickr, PushablePhotos, UIThreePartButton, UITextLabel, UIProgressBar, UIWindow, UIImageView;

@interface MobilePushr: UIApplication
{
	NSUserDefaults *_settings;
	Flickr *_flickr;
	PushablePhotos *_pushablePhotos;
	UIThreePartButton *_button;
	UITextLabel *_label;
	UIProgressBar *_progress;
	UIImageView *_thumbnailView;
	UIWindow *_window;
}

- (NSArray *)cameraRollPhotos;
- (void)popupFailureAlertSheet;
- (void)setLabelText: (NSString *)labelText;
- (void)updateProgress: (NSNumber *)currentProgress;
- (void)allDone: (NSArray *)responses;

@end
