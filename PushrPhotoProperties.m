/*
 * PushrPhotoProperties.m
 * ----------------------
 *
 * Author: Chris Lee <clee@mg8.org>
 * License: GPL v2 <http://www.opensource.org/licenses/gpl-license.php>
 */

#import <Foundation/Foundation.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Geometry.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITransitionView.h>
#import <UIKit/UIPreferencesTable.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <UIKit/UIPreferencesControlTableCell.h>
#import <UIKit/UIPreferencesTableCell.h>
#import <UIKit/UISegmentedControl.h>
#import <UIKit/UISwitchControl.h>
#import <UIKit/UITextLabel.h>
#import <UIKit/UIAlertSheet.h>
#import <UIKit/UIWindow.h>

#import "PushrPhotoProperties.h"
#import "ExtendedAttributes.h"
#import "Flickr.h"
#import "MobilePushr.h"

@implementation PushrPhotoTags

- (void)show
{
	struct CGRect settingsRect = [UIHardware fullScreenApplicationContentRect];
	settingsRect.origin.x = 0.0f; // */ settingsRect.size.width;
	settingsRect.origin.y = 0.0f;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	Flickr *flickr = [[Flickr alloc] initWithPushr: _pushr];

	_availableTags = [[flickr tags] retain];
	_tagsView = [[UIView alloc] initWithFrame: settingsRect];
	_navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0.0f, 0.0f, settingsRect.size.width, 44.0f)];
	[_navBar setBarStyle: 1];
	[_navBar setDelegate: self];
	[_navBar showLeftButton: nil withStyle: 0 rightButton: @"Done" withStyle: 0];

	UINavigationItem *title = [[UINavigationItem alloc] initWithTitle: @"Tags"];
	[_navBar pushNavigationItem: title];
	[title release];

	[_tagsView addSubview: _navBar];

	_tagsTable = [[UIPreferencesTable alloc] initWithFrame: CGRectMake(0.0f, 44.0f, settingsRect.size.width, settingsRect.size.height - 44.0f)];
	[_tagsTable setDataSource: self];
	[_tagsTable setDelegate: self];
	[_tagsTable reloadData];
	[_tagsView addSubview: _tagsTable];

	UITransitionView *transitionView = [[UITransitionView alloc] initWithFrame: settingsRect];
	[_mainWindow setContentView: transitionView];
	[transitionView transition: 0 toView: _prefView];
	[transitionView transition: 1 fromView: _prefView toView: _tagsView];
	[transitionView release];
}

- (id)initFromWindow: (UIWindow *)window withPushr: (MobilePushr *)pushr withView: (UIView *)view withTable: (UIPreferencesTable *)table atPath: (NSString *)path
{
	if (![super init])
		return nil;

	_photoPath = [path retain];
	_pushr = [pushr retain];
	_mainWindow = window;
	_prefView = view;
	_prefTable = table;

	[self show];

	return self;
}

- (void)dealloc
{
	[_photoPath release];
	[_availableTags release];
	[_navBar release];
	[_prefView release];
	[_prefTable release];
	[_tagsView release];
	[_tagsTable release];
	[_mainWindow release];
	[_pushr release];
	[super dealloc];
}

#pragma mark PushrGlobalTags delegates

- (int)numberOfGroupsInPreferencesTable: (id)preferencesTable
{
	return 1;
}

- (int)preferencesTable: (UIPreferencesTable *)preferencesTable numberOfRowsInGroup: (int)group
{
	return [_availableTags count];
}

- (id)preferencesTable: (UIPreferencesTable *)preferencesTable titleForGroup: (int)group
{
	return @"Default tags for photos";
}

- (float)preferencesTable: (id)preferencesTable heightForRow:(int)row inGroup: (int)group withProposedHeight: (float)proposedHeight
{
	return 48.0f;
}

- (id)preferencesTable: (id)preferencesTable cellForRow: (int)row inGroup: (int)group
{
	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	UIPreferencesTableCell *thisCell = [[UIPreferencesTableCell alloc] initWithFrame: CGRectMake(0.0f, 0.0f, rect.size.width, 48.0f)];
	[thisCell setTitle: [_availableTags objectAtIndex: row]];
	if ([[ExtendedAttributes allKeysAtPath: _photoPath] containsObject: TAGS_ATTRIBUTE])
		[thisCell setChecked: [[ExtendedAttributes objectForKey: TAGS_ATTRIBUTE atPath: _photoPath] containsObject: [_availableTags objectAtIndex: row]]];
	else
		[thisCell setChecked: [[defaults arrayForKey: @"defaultTags"] containsObject: [_availableTags objectAtIndex: row]]];

	return [thisCell autorelease];
}

- (void)tableRowSelected: (NSNotification *)notification 
{
	id row = [_tagsTable cellAtRow: [_tagsTable selectedRow] column: 0];
	[row setChecked: ![row isChecked]];
}

- (void)navigationBar: (UINavigationBar *)navBar buttonClicked: (int)button
{
	struct CGRect settingsRect = [UIHardware fullScreenApplicationContentRect];
	UITransitionView *transitionView = [[UITransitionView alloc] initWithFrame: CGRectMake(0.0f, 0.0f, settingsRect.size.width, settingsRect.size.height)];
	[_mainWindow setContentView: transitionView];
	[transitionView transition: 0 toView: _tagsView];

	NSMutableArray *checkedTags = [NSMutableArray array];
	for (int tagIndex = 0; tagIndex < [_availableTags count]; tagIndex++)
		if ([[_tagsTable cellAtRow: tagIndex + 1 column: 0] isChecked])
			[checkedTags addObject: [_availableTags objectAtIndex: tagIndex]];

	[ExtendedAttributes setObject: checkedTags forKey: TAGS_ATTRIBUTE atPath: _photoPath];
	[transitionView transition: 2 fromView: _tagsView toView: _prefView];
	[_prefTable reloadData];
	[_prefTable selectRow: -1 byExtendingSelection: NO];

	[transitionView release];
}

@end

@implementation PushrPhotoPrivacy

- (void)show
{
	struct CGRect settingsRect = [UIHardware fullScreenApplicationContentRect];
	settingsRect.origin.x = 0.0f; // */ settingsRect.size.width;
	settingsRect.origin.y = 0.0f;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	_privacyView = [[UIView alloc] initWithFrame: settingsRect];
	_navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0.0f, 0.0f, settingsRect.size.width, 44.0f)];
	[_navBar setBarStyle: 1];
	[_navBar setDelegate: self];
	[_navBar showLeftButton: nil withStyle: 0 rightButton: @"Done" withStyle: 0];

	UINavigationItem *title = [[UINavigationItem alloc] initWithTitle: @"Privacy"];
	[_navBar pushNavigationItem: title];
	[title release];

	[_privacyView addSubview: _navBar];

	_privacyTable = [[UIPreferencesTable alloc] initWithFrame: CGRectMake(0.0f, 44.0f, settingsRect.size.width, settingsRect.size.height - 44.0f)];
	[_privacyTable setDataSource: self];
	[_privacyTable setDelegate: self];
	[_privacyTable reloadData];
	[_privacyView addSubview: _privacyTable];

	UITransitionView *transitionView = [[UITransitionView alloc] initWithFrame: settingsRect];
	[_mainWindow setContentView: transitionView];
	[transitionView transition: 0 toView: _prefView];
	[transitionView transition: 1 fromView: _prefView toView: _privacyView];
	[transitionView release];
}

- (id)initFromWindow: (UIWindow *)window withPushr: (MobilePushr *)pushr withView: (UIView *)view withTable: (UIPreferencesTable *)table atPath: (NSString *)path
{
	if (![super init])
		return nil;

	_photoPath = [path retain];
	_pushr = [pushr retain];
	_mainWindow = window;
	_prefView = view;
	_prefTable = table;
	_availablePrivacy = [[NSArray arrayWithObjects: @"Private", @"Friends", @"Family", @"Public", nil] retain];

	[self show];

	return self;
}

- (void)dealloc
{
	[_photoPath release];
	[_availablePrivacy release];
	[_navBar release];
	[_prefView release];
	[_prefTable release];
	[_privacyTable release];
	[_privacyView release];
	[_mainWindow release];
	[_pushr release];
	[super dealloc];
}

#pragma mark PushrGlobalPrivacy delegates

- (int)numberOfGroupsInPreferencesTable: (id)preferencesTable
{
	return 1;
}

- (int)preferencesTable: (UIPreferencesTable *)preferencesTable numberOfRowsInGroup: (int)group
{
	return [_availablePrivacy count];
}

- (id)preferencesTable: (UIPreferencesTable *)preferencesTable titleForGroup: (int)group
{
	return @"Default privacy for photos";
}

- (float)preferencesTable: (id)preferencesTable heightForRow:(int)row inGroup: (int)group withProposedHeight: (float)proposedHeight
{
	return 48.0f;
}

- (BOOL)table: (id)table shouldIndentRow: (int)row
{
	if (row == 1 || row == 2)
		return YES;
	return NO;
}

- (id)preferencesTable: (id)preferencesTable cellForRow: (int)row inGroup: (int)group
{
	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	UIPreferencesTableCell *thisCell = [[UIPreferencesTableCell alloc] initWithFrame: CGRectMake(0.0f, 0.0f, rect.size.width, 48.0f)];
	// Ugly, ugly hack. If shouldIndentRow just worked properly this would be unnecessary.
	if (row == 1 || row == 2)
		[thisCell setTitle: [NSString stringWithFormat: @"     %@", [_availablePrivacy objectAtIndex: row]]];
	else
		[thisCell setTitle: [_availablePrivacy objectAtIndex: row]];
		
	if ([[ExtendedAttributes allKeysAtPath: _photoPath] containsObject: PRIVACY_ATTRIBUTE])
		[thisCell setChecked: [[ExtendedAttributes objectForKey: PRIVACY_ATTRIBUTE atPath: _photoPath] containsObject: [_availablePrivacy objectAtIndex: row]]];
	else
		[thisCell setChecked: [[defaults arrayForKey: PRIVACY_ATTRIBUTE] containsObject: [_availablePrivacy objectAtIndex: row]]];

	return [thisCell autorelease];
}

/*
 * This is a little tricky, it turns out! There are invalid combinations of privacy settings - 
 * for example, 'Friends' + 'Public' simply wouldn't make sense. 
 * This code allows the user to toggle friends/family rows, but prevents invalid combinations.
 */
- (void)tableRowSelected: (NSNotification *)notification 
{
	id row = [_privacyTable cellAtRow: [_privacyTable selectedRow] column: 0];
	switch ([_privacyTable selectedRow]) {
		case 1:
		case 2:
		case 3: {
			[row setChecked: ![row isChecked]];
			[[_privacyTable cellAtRow: 1 column: 0] setChecked: YES];
			[[_privacyTable cellAtRow: 4 column: 0] setChecked: NO];
			break;
		}
		case 4: {
			for (int currentRow = 1; currentRow < 4; currentRow++) {
				[[_privacyTable cellAtRow: currentRow column: 0] setChecked: NO];
			}
			[row setChecked: YES];
		}
	}
}

- (void)navigationBar: (UINavigationBar *)navBar buttonClicked: (int)button
{
	struct CGRect settingsRect = [UIHardware fullScreenApplicationContentRect];
	UITransitionView *transitionView = [[UITransitionView alloc] initWithFrame: CGRectMake(0.0f, 0.0f, settingsRect.size.width, settingsRect.size.height)];
	[_mainWindow setContentView: transitionView];
	[transitionView transition: 0 toView: _privacyView];

	NSMutableArray *checkedPrivacySettings = [NSMutableArray array];
	for (int settingIndex = 0; settingIndex < [_availablePrivacy count]; settingIndex++)
		if ([[_privacyTable cellAtRow: settingIndex + 1 column: 0] isChecked])
			[checkedPrivacySettings addObject: [_availablePrivacy objectAtIndex: settingIndex]];

	[ExtendedAttributes setObject: checkedPrivacySettings forKey: PRIVACY_ATTRIBUTE atPath: _photoPath];
	[transitionView transition: 2 fromView: _privacyView toView: _prefView];
	[_prefTable reloadData];
	[_prefTable selectRow: -1 byExtendingSelection: NO];

	[transitionView release];
}

@end

@implementation PushrPhotoProperties

- (id)initFromWindow: (UIWindow *)window withPushr: (MobilePushr *)pushr forPhoto: (NSString *)photo
{
	if (![super init])
		return nil;

	_photoPath = [photo retain];
	_pushr = [pushr retain];
	_mainWindow = window;

	[self show];

	return self;
}

- (void)dealloc
{
	[_photoPath release];
	[_navBar release];
	[_prefView release];
	[_prefTable release];
	[_photoView release];
	[_mainWindow release];
	[_pushr release];
	[super dealloc];
}

- (void)show
{
	struct CGRect settingsRect = [UIHardware fullScreenApplicationContentRect];
	settingsRect.origin.x = 0.0f; // */ settingsRect.size.width;
	settingsRect.origin.y = 0.0f;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	_prefView = [[UIView alloc] initWithFrame: settingsRect];
	UITransitionView *transitionView = [[UITransitionView alloc] initWithFrame: settingsRect];

	_navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0.0f, 0.0f, settingsRect.size.width, 44.0f)];
	[_navBar setBarStyle: 1];
	[_navBar setDelegate: self];
	[_navBar showLeftButton: nil withStyle: 0 rightButton: @"Done" withStyle: 1];

	UINavigationItem *title = [[UINavigationItem alloc] initWithTitle: @"Properties"];
	[_navBar pushNavigationItem: title];
	[title release];

	[_prefView addSubview: _navBar];

	_prefTable = [[UIPreferencesTable alloc] initWithFrame: CGRectMake(0.0f, 44.0f, settingsRect.size.width, settingsRect.size.height - 44.0f)];
	[_prefTable setDataSource: self];
	[_prefTable setDelegate: self];
	[_prefTable reloadData];
	[_prefView addSubview: _prefTable];

	_photoView = [[_mainWindow contentView] retain];

	// This doesn't seem like the right way to do this but it seems to work...
	[_mainWindow setContentView: transitionView];
	[transitionView transition: 0 toView: _photoView];
	[transitionView transition: 1 fromView: _photoView toView: _prefView];
	[transitionView release];
}

#pragma mark PushrSettings delegates
- (void)navigationBar: (UINavigationBar *)navBar buttonClicked: (int)button
{
	struct CGRect settingsRect = [UIHardware fullScreenApplicationContentRect];
	UITransitionView *transitionView = [[UITransitionView alloc] initWithFrame: CGRectMake(0.0f, 0.0f, settingsRect.size.width, settingsRect.size.height)];
	[_mainWindow setContentView: transitionView];
	[transitionView transition: 0 toView: _prefView];

	id cell = [_prefTable cellAtRow: 1 column: 0];
	if ([[cell value] length] > 0)
		[ExtendedAttributes setString: [cell value] forKey: NAME_ATTRIBUTE atPath: _photoPath];
	cell = [_prefTable cellAtRow: 2 column: 0];
	if ([[cell value] length] > 0)
		[ExtendedAttributes setString: [cell value] forKey: DESCRIPTION_ATTRIBUTE atPath: _photoPath];

	switch (button) {
		default: {
			[transitionView transition: 2 fromView: _prefView toView: _photoView];
		}
	}

	[transitionView release];
}

- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable { return 1; }

- (int)preferencesTable: (UIPreferencesTable *)preferencesTable numberOfRowsInGroup: (int)group
{
	switch (group) {
		default: {
			return 4;
		}
	}
}

- (id)preferencesTable: (UIPreferencesTable *)preferencesTable cellForRow: (int)row inGroup: (int)group
{
	if (group > 0)
		return nil;

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];

	switch (row) {
		case 0: {
			id nameCell = [[UIPreferencesTextTableCell alloc] initWithFrame: CGRectMake(0.0f, 0.0f, rect.size.width, 48.0f)];
			[nameCell setTitle: @"Name"];
			if ([[ExtendedAttributes allKeysAtPath: _photoPath] containsObject: NAME_ATTRIBUTE])
				[nameCell setValue: [ExtendedAttributes stringForKey: NAME_ATTRIBUTE atPath: _photoPath]];
			else
				[nameCell setPlaceHolderValue: [_photoPath lastPathComponent]];
			return [nameCell autorelease];
		}
		case 1: {
			id descCell = [[UIPreferencesTextTableCell alloc] initWithFrame: CGRectMake(0.0f, 0.0f, rect.size.width, 48.0f)];
			[descCell setTitle: @"Description"];
			if ([[ExtendedAttributes allKeysAtPath: _photoPath] containsObject: DESCRIPTION_ATTRIBUTE])
				[descCell setValue: [ExtendedAttributes stringForKey: DESCRIPTION_ATTRIBUTE atPath: _photoPath]];
			else
				[descCell setPlaceHolderValue: @"Optional description"];
			return [descCell autorelease];
		}
		case 2: {
			id tagsCell = [[UIPreferencesTableCell alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 48.0f)];
			[tagsCell setTitle: @"Tags"];
			if ([[ExtendedAttributes allKeysAtPath: _photoPath] containsObject: TAGS_ATTRIBUTE])
				[tagsCell setValue: [[ExtendedAttributes objectForKey: TAGS_ATTRIBUTE atPath: _photoPath] componentsJoinedByString: @", "]];
			else
				[tagsCell setValue: [[defaults arrayForKey: @"defaultTags"] componentsJoinedByString: @", "]];
			[tagsCell setShowDisclosure: YES];
			return [tagsCell autorelease];
		}
		case 3: {
			id privacyCell = [[UIPreferencesTableCell alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 48.0f)];
			[privacyCell setTitle: @"Privacy"];
			if ([[ExtendedAttributes allKeysAtPath: _photoPath] containsObject: PRIVACY_ATTRIBUTE])
				[privacyCell setValue: [[ExtendedAttributes objectForKey: PRIVACY_ATTRIBUTE atPath: _photoPath] componentsJoinedByString: @" + "]];
			else
				[privacyCell setValue: [[defaults arrayForKey: @"defaultPrivacy"] componentsJoinedByString: @" + "]];
			[privacyCell setShowDisclosure: YES];
			return [privacyCell autorelease];
		}
		default:
			return nil;
	}
}

- (id)preferencesTable: (UIPreferencesTable *)preferencesTable titleForGroup: (int)group
{
	return [NSString stringWithFormat: @"Properties for photo %@", [_photoPath lastPathComponent]];
}

- (float)preferencesTable: (id)preferencesTable heightForRow:(int)row inGroup: (int)group withProposedHeight: (float)proposedHeight
{
	return 48.0f;
}

- (void)tableRowSelected:(NSNotification *)notification 
{
	int i = [_prefTable selectedRow];
	NSLog(@"Selected row %d", i);

	id cell = [_prefTable cellAtRow: 1 column: 0];
	if ([[cell value] length] > 0)
		[ExtendedAttributes setString: [cell value] forKey: NAME_ATTRIBUTE atPath: _photoPath];
	cell = [_prefTable cellAtRow: 2 column: 0];
	if ([[cell value] length] > 0)
		[ExtendedAttributes setString: [cell value] forKey: DESCRIPTION_ATTRIBUTE atPath: _photoPath];

	switch (i) {
		case 3: {
			[[PushrPhotoTags alloc] initFromWindow: _mainWindow withPushr: _pushr withView: _prefView withTable: _prefTable atPath: _photoPath];
			break;
		}
		case 4: {
			[[PushrPhotoPrivacy alloc] initFromWindow: _mainWindow withPushr: _pushr withView: _prefView withTable: _prefTable atPath: _photoPath];
			break;
		}
	}
}

@end