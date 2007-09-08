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

- (void) applicationDidFinishLaunching: (id) unused
{
  // Terminal size based on the font size below

  UIWindow *window = [[UIWindow alloc] initWithContentRect: [UIHardware fullScreenApplicationContentRect]];
  [window orderFront: self];
  [window makeKey: self];

  NSBundle *bundle = [NSBundle mainBundle];
  NSString *background = [bundle pathForResource:@"background" ofType:@"png"];
  UIImage *bg = [[UIImage alloc] initWithContentsOfFile:background];

  struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
  UIImageView *bgView = [[UIImageView alloc] initWithFrame: rect];
  [bgView setImage:bg];
  [bgView setAlpha:1.0f];

  UIView *mainView = [[UIView alloc] initWithFrame: rect];

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

  [mainView addSubview: bgView];
  [mainView addSubview: table];

  [window setContentView: mainView];
}

@end
