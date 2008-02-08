/*
 * PushrSettings.h
 * --------------
 *
 * Author: Chris Lee <clee@mg8.org>
 * License: GPL v2 <http://www.opensource.org/licenses/gpl-license.php>
 */

#import <Foundation/Foundation.h>

@class MobilePushr, UINavigationBar, UIView, UIPreferencesTable, UIPreferencesTextTableCell;

@interface PushrGlobalTags : NSObject
{
	MobilePushr *_pushr;
	UIWindow *_mainWindow;
	UINavigationBar *_navBar;
	UIView *_prefView, *_tagsView;
	UIPreferencesTable *_tagsTable, *_prefTable;
	NSArray *_availableTags;
	
}

- (id)initFromWindow: (UIWindow *)window withPushr: (MobilePushr *)pushr withView: (UIView *)view withTable: (UIPreferencesTable *)table;

@end

@interface PushrGlobalPrivacy : NSObject

{
	MobilePushr *_pushr;
	UIWindow *_mainWindow;
	UINavigationBar *_navBar;
	UIView *_prefView, *_privacyView;
	UIPreferencesTable *_privacyTable, *_prefTable;
	NSArray *_availablePrivacy;
	
}

- (id)initFromWindow: (UIWindow *)window withPushr: (MobilePushr *)pushr withView: (UIView *)view withTable: (UIPreferencesTable *)table;

@end

@interface PushrSettings : NSObject
{
	MobilePushr *_pushr;
	UINavigationBar *_navBar;
	UIWindow *_mainWindow;

	UIView *_prefView, *_photoView;
	UIPreferencesTable *_prefTable;
}

- (id)initFromWindow: (UIWindow *)window withPushr: (MobilePushr *)pushr;

@end