/*
 * PushrNetUtil.h
 * --------------
 *
 * Author: Chris Lee <clee@mg8.org>
 * License: GPL v2 <http://www.opensource.org/licenses/gpl-license.php>
 */

#import <Foundation/Foundation.h>

@class MobilePushr;

@interface PushrNetUtil : NSObject
{
	MobilePushr *_pushr;
	NSMutableArray *_activeInterfaceNames;
}

- (id)initWithPushr: (MobilePushr *)pushr;
- (void)warnUserAboutSlowEDGE;
- (NSArray *)activeInterfaceNames;
- (BOOL)hasWiFi;

@end