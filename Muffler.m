#import <Foundation/Foundation.h>

int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSData *example = [NSData dataWithContentsOfFile:@"./test.xml"];

	id foo = [[NSClassFromString(@"NSXMLDocument") alloc] init];
	NSLog(@"This is stuff: %d", [foo respondsToSelector: @selector(DTD)]);

	[pool release];
	return 0;
}
