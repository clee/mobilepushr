#import <Foundation/Foundation.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSString *jpgPath = @"/path/to/IMG_0025.JPG";
	NSString *ss = [[[jpgPath componentsSeparatedByString: @"/"] lastObject] substringWithRange: NSMakeRange(4, 4)];
	NSLog(@"Substring: %@ (int value: %d)", ss, [ss intValue]);

	[pool release];
	return 0;
}
