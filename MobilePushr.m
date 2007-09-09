// MobilePushr.m
#import "MobilePushr.h"

#import <Foundation/Foundation.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITableCell.h>
#import <UIKit/UIPreferencesTableCell.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIView-Rendering.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIValueButton.h>

#include <stdio.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

@implementation MobilePushr

-(int)numberOfRowsInTable: (UITable *)table
{
	return 2;
}

-(UITableCell *)table: (UITable *)table cellForRow: (int)row column: (int)col
{
	return row ? (UITableCell *)buttonCell : (UITableCell *)prefCell;
}

-(UITableCell *)table: (UITable *)table cellForRow: (int)row column: (int)col reusing: (BOOL)reusing
{
	return (UITableCell *)prefCell;
}

- (NSArray *)arrayOfPhotos
{
	NSString *jpg;
	NSString *cameraRollDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Media/DCIM"];
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: cameraRollDir];
	NSMutableArray *photos = [NSMutableArray array];

	while ((jpg = [dirEnum nextObject])) {
		if ([[jpg pathExtension] isEqualToString: @"JPG"]) {
			[photos addObject: [cameraRollDir stringByAppendingPathComponent: jpg]];
		}
	}

	return [NSArray arrayWithArray:photos];
}

- (void) flickrTags
{
	id tags = [[NSClassFromString(@"NSXMLDocument") alloc] init];
	[tags description];
}

- (void) applicationDidFinishLaunching: (id) unused
{
	UIWindow *window = [[UIWindow alloc] initWithContentRect: [UIHardware fullScreenApplicationContentRect]];
	
	NSArray *photos = [self arrayOfPhotos];
	for(int i = 0; i < [photos count]; i++) {
		NSLog(@"Photo at %@", [photos objectAtIndex: i]);
		[self flickrTags];
	}

	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
	UIImageView *background = [[[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height)] autorelease];
//	[background setImage:[UIImage imageNamed:@"wallpaper.jpg"]];
	[background setImage:[UIImage defaultDesktopImage]];
//	[background setImage:[[[UIImage alloc] initWithImageRef:[self createApplicationDefaultPNG]] autorelease]];

	UIView *mainView = [[UIView alloc] initWithFrame: rect];
	[mainView addSubview:background];

	prefCell = [[UIPreferencesTableCell alloc] init];
	[prefCell setTitle: @"Here's a title"];

	UIPushButton* button = [[UIPushButton alloc] initWithTitle: @"Upload to Flickr now"];

	buttonCell = [[UITableCell alloc] init];
	[buttonCell addSubview: button];
	[button sizeToFit];

	UITable *table = [[UITable alloc] initWithFrame: CGRectMake(0.0f, 48.0f, 320.0f, 480.0f - 16.0f - 32.0f)];
	UITableColumn *col = [[UITableColumn alloc] initWithTitle: @"Pushr" identifier: @"hello" width: 320.0f];

	[window _setHidden: NO];

	[table addTableColumn: col];
	[table setDataSource: self];
	[table setDelegate: self];
	[table reloadData];

	[mainView addSubview: table];

	[window orderFront: self];
	[window makeKey: self];
	[window setContentView: mainView];
}

@end
