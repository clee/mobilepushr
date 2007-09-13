#import <Foundation/Foundation.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
	[d setValue: @"72157601973587381-cf36330fe0ed6249" forKey: @"token"];
	[d setValue: @"12031124@N00" forKey: @"nsid"];
	[d setValue: @"slashclee" forKey: @"username"];
	[d synchronize];
	[pool release];
	return 0;
}
