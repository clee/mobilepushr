#import <Foundation/Foundation.h>

NSArray *getXMLNodesNamed(NSString *nodeName, NSData *responseData)
{
	NSError *err = nil;
	id responseDoc = [[NSClassFromString(@"NSXMLDocument") alloc] initWithData: responseData options: 0 error: &err];

	NSMutableArray *matches = [NSMutableArray array];
	NSArray *nodes = [responseDoc children];
	NSEnumerator *chain = [nodes objectEnumerator];
	NSXMLNode *node = nil;

	while ((node = [chain nextObject])) {
		if (![[node name] isEqualToString: nodeName]) {
			NSLog(@"Node name: %@ is not %@, recursing into children", [node name], nodeName);
			nodes = [[nodes lastObject] children];
			chain = [nodes objectEnumerator];
			continue;
		}

		[matches addObject: node];
	}

	return [NSArray arrayWithArray: matches];
}

int main(int a, char **b)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSData *frobXML = [NSData dataWithContentsOfFile: @"get_frob_response.xml"];
	NSString *frob = [[getXMLNodesNamed(@"frob", frobXML) lastObject] stringValue];
	NSLog(@"Result of getXMLNodes (frob): %@", frob);
	
	NSData *tagsXML = [NSData dataWithContentsOfFile: @"get_tags_response.xml"];
	NSArray *tags = getXMLNodesNamed(@"tag", tagsXML);
	NSEnumerator *tagChain = [tags objectEnumerator];
	id currentTag = nil;
	while ((currentTag = [tagChain nextObject])) {
		NSLog(@"Tag found: %@", [currentTag stringValue]);
	}

	[pool release];
	return 0;
}