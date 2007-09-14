// main.m
#import <UIKit/UIKit.h>
#import "MobilePushr.h"

int main(int argc, char **argv)
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	int ret = UIApplicationMain(argc, argv, [MobilePushr class]);
	[pool release];
	return ret;
}
