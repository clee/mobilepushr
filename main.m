/* 
 * main.m
 * ------
 *
 * Author: Chris Lee <clee@mg8.org>
 * License: GPL v2 <http://www.opensource.org/licenses/gpl-license.php>
 */
#import <UIKit/UIKit.h>
#import "MobilePushr.h"

#include <stdio.h>

int main(int argc, char **argv)
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	int ret = UIApplicationMain(argc, argv, [MobilePushr class]);
	[pool release];
	return ret;
}
