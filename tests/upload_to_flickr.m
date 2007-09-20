#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>

#include <unistd.h>
#include <openssl/md5.h>

#define FLICKR_UPLOAD_URL @"http://api.flickr.com/services/upload/"
#define FLICKR_FINISHED_URL @"http://www.flickr.com/tools/uploader_edit.gne"
#define MIME_BOUNDARY "----16c17a9ea1d7b327e7489190e394d411----"
#define CONTENT_TYPE "multipart/form-data; boundary=" MIME_BOUNDARY

NSString *api_sig(NSDictionary *params)
{
	NSMutableString *sig = [NSMutableString stringWithString: PUSHR_SHARED_SECRET];
	NSArray *sortedKeys = [[params allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];

	id key = nil;
	NSEnumerator *iterator = [sortedKeys objectEnumerator];
	while ((key = [iterator nextObject])) {
		[sig appendString: key];
		[sig appendString: [params objectForKey: key]];
	}

	unsigned char digest[16];
	char finalDigest[32];

	MD5((const unsigned char *)[sig UTF8String], (const unsigned long)[sig length], digest);
	for (unsigned short int index = 0; index < 16; ++index)
		sprintf(finalDigest + (index * 2), "%02x", digest[index]);

	return [NSString stringWithCString: finalDigest length: 32];
}

void uploadPictureToFlickr(NSString *pathToJPG)
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	NSString *token = [settings stringForKey: @"token"];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys: PUSHR_API_KEY, @"api_key", token, @"auth_token", @"0", @"is_public", nil];
	[params setObject: api_sig(params) forKey: @"api_sig"];
	[params setObject: [NSData dataWithContentsOfFile: pathToJPG] forKey: @"photo"];

	NSMutableData *body = [[NSMutableData alloc] initWithLength: 0];
	[body appendData: [[[[NSString alloc] initWithFormat: @"--%@\r\n", @MIME_BOUNDARY] autorelease] dataUsingEncoding: NSUTF8StringEncoding]];

	id key = nil;
	NSEnumerator *enumerator = [params keyEnumerator];
	while ((key = [enumerator nextObject])) {
		id val = [params objectForKey: key];
		id keyHeader = nil;
		if ([key isEqualToString: @"photo"]) {
			// If this is the photo...
			keyHeader = [[NSString stringWithFormat: @"Content-Disposition: form-data; name=\"photo\"; filename=\"%@\"\r\nContent-Type: image/jpeg\r\n\r\n", pathToJPG] dataUsingEncoding: NSUTF8StringEncoding];
			[body appendData: keyHeader];
			[body appendData: val];
		} else {
			// Treat all other values as strings.
			keyHeader = [NSString stringWithFormat: @"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key];
			[body appendData: [keyHeader dataUsingEncoding: NSUTF8StringEncoding]];
			[body appendData: [val dataUsingEncoding: NSUTF8StringEncoding]];			
		}
		[body appendData: [[NSString stringWithFormat: @"\r\n--%@\r\n", @MIME_BOUNDARY] dataUsingEncoding: NSUTF8StringEncoding]];
	}

	[body appendData: [[NSString stringWithString: @"--\r\n"] dataUsingEncoding: NSUTF8StringEncoding]];
	long bodyLength = [body length];

	CFURLRef uploadURL = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)FLICKR_UPLOAD_URL, NULL);
	CFHTTPMessageRef _request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("POST"), uploadURL, kCFHTTPVersion1_1);
	CFRelease(uploadURL);
	uploadURL = NULL;

	CFHTTPMessageSetHeaderFieldValue(_request, CFSTR("Content-Type"), CFSTR(CONTENT_TYPE));
	CFHTTPMessageSetHeaderFieldValue(_request, CFSTR("Host"), CFSTR("api.flickr.com"));
	CFHTTPMessageSetHeaderFieldValue(_request, CFSTR("Content-Length"), (CFStringRef)[NSString stringWithFormat: @"%d", bodyLength]);
	CFHTTPMessageSetBody(_request, (CFDataRef)body);
	[body release];

	CFReadStreamRef _readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, _request);
	CFReadStreamOpen(_readStream);

	CFIndex numBytesRead;
	long bytesWritten, previousBytesWritten = 0;
	UInt8 buf[1024];
	BOOL doneUploading = NO;

	while (!doneUploading) {
		CFNumberRef cfSize = CFReadStreamCopyProperty(_readStream, kCFStreamPropertyHTTPRequestBytesWrittenCount);
		CFNumberGetValue(cfSize, kCFNumberLongType, &bytesWritten);
		CFRelease(cfSize);
		cfSize = NULL;
		if (bytesWritten > previousBytesWritten) {
			previousBytesWritten = bytesWritten;
			fprintf(stderr, "(%lu bytes written / %lu total bytes) = %f %%\r", bytesWritten, bodyLength, (100.0f * ((float)bytesWritten/(float)bodyLength)));
			fflush(stderr);
		}

		if (!CFReadStreamHasBytesAvailable(_readStream)) {
			usleep(3200);
			continue;
		} else {
			fprintf(stderr, "\n");
		}

		numBytesRead = CFReadStreamRead(_readStream, buf, 1024);
		fprintf(stderr, "%s", buf);
		fflush(stderr);

		if (CFReadStreamGetStatus(_readStream) == kCFStreamStatusAtEnd) doneUploading = YES;
	}
	CFHTTPMessageRef _responseHeaderRef = (CFHTTPMessageRef)CFReadStreamCopyProperty(_readStream, kCFStreamPropertyHTTPResponseHeader);
	NSDictionary *_responseHeaders = (NSDictionary *)CFHTTPMessageCopyAllHeaderFields(_responseHeaderRef);
	NSLog(@"Header data was: \n---\n%@\n---\n", _responseHeaders);
	CFRelease(_responseHeaderRef);
	_responseHeaderRef = NULL;

	CFReadStreamClose(_readStream);
	CFRelease(_request);
	_request = NULL;
	CFRelease(_readStream);
	_readStream = NULL;
}

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	fprintf(stderr, "Pausing to give you time to catch me\n");
	sleep(8);

	for (unsigned int indexOfPicture = 1; indexOfPicture < argc; ++indexOfPicture) {
		uploadPictureToFlickr([NSString stringWithUTF8String: argv[indexOfPicture]]);
		fprintf(stderr, "Sleeping - check memory usage now!\n");
		sleep(8);
	}

	[pool release];
	return 0;
}
