#import <Foundation/Foundation.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	NSString *token = [settings stringForKey: @"token"];

	NSLog(@"Token is: %@", token);

	[pool release];
	return 0;
}
