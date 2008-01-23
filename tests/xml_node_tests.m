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

NSDictionary *getXMLNodesAndAttributesFromResponse(NSData *responseData)
{
	NSError *err = nil;
	id responseDoc = [[NSClassFromString(@"NSXMLDocument") alloc] initWithData: responseData options: 0 error: &err];

	NSMutableDictionary *nodesWithAttributes = [NSMutableDictionary dictionary];
	NSArray *nodes = [responseDoc children];
	NSEnumerator *chain = [nodes objectEnumerator];
	NSXMLNode *node = nil;

	while ((node = [chain nextObject])) {
		id element = [[NSClassFromString(@"NSXMLElement") alloc] initWithXMLString: [node XMLString] error: &err];
		if ([[element attributes] count] > 0) {
			NSEnumerator *attributeChain = [[element attributes] objectEnumerator];
			id attribute = nil;
			while ((attribute = [attributeChain nextObject]))
				[nodesWithAttributes setObject: [attribute stringValue] forKey: [NSString stringWithFormat: @"%@%@", [node name], [attribute name]]];
		}

		[nodesWithAttributes setObject: [node stringValue] forKey: [node name]];

		if ([[node children] count] > 0 && [[[[node children] objectAtIndex: 0] name] length] > 0) {
			nodes = [node children];
			chain = [nodes objectEnumerator];
		}

		[element release];
	}
	
	[responseDoc release];

	return [NSDictionary dictionaryWithDictionary: nodesWithAttributes];
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
	while ((currentTag = [tagChain nextObject]))
		NSLog(@"Tag found: %@", [currentTag stringValue]);

	NSData *tokenXML = [NSData dataWithContentsOfFile: @"full_auth_token_response.xml"];
	NSDictionary *token = getXMLNodesAndAttributesFromResponse(tokenXML);
	NSLog(@"Token is: \n---\n%@\n---\n", token);

	[pool release];
	return 0;
}