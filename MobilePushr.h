/*
 * MobilePushr.h
 * -------------
 *
 * Author: Chris Lee <clee@mg8.org>
 * License: GPL v2 <http://www.opensource.org/licenses/gpl-license.php>
 */
#import <UIKit/UIApplication.h>

@class NSUserDefaults, Flickr, UIThreePartButton, UITextLabel, UIProgressBar;

@interface MobilePushr: UIApplication
{
	NSUserDefaults *_settings;
	Flickr *_flickr;
	UIThreePartButton *_button;
	UITextLabel *_label;
	UIProgressBar *_progress;
}

- (NSArray *)cameraRollPhotos;
- (void)popupFailureAlertSheet;
- (void)updateProgress: (NSNumber *)currentProgress;
- (void)allDone: (NSArray *)responses;

@end
