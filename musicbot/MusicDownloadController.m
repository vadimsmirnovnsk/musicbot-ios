#import "MusicDownloadController.h"

#import "BGMusicPlayer.h"

#import <AFNetworking/AFNetworking.h>
#import <XMLDictionary/XMLDictionary.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <CommonCrypto/CommonDigest.h>

static NSString *const kDGSYandexStorageDirTemplate		= @"http://storage.music.yandex.ru/get/%@/2.xml";
static NSString *const kDGSYandexDownloadInfoTemplate	= @"http://storage.music.yandex.ru/download-info/%@/%@";
static NSString *const kDGSYandexMP3Template			= @"http://%@/get-mp3/%@/%@%@?track-id=%@&region=225&from=service-search";
static NSString *const kDGSYandexMP3MD5Template			= @"http://%@/get-mp3/%@/%@?track-id=%@&from=service-10-track&similarities-experiment=default";
static NSString *const kDGSYandexMD5Salt				= @"XGRlBW9FXlekgbPrRHuSiA";
// 'http://%s/get-mp3/%s/%s?track-id=%s&from=service-10-track&similarities-experiment=default'

static NSString *const kDGSYandexStorageFilenameKey		= @"_filename";
static NSString *const kDGSYandexDownloadInfoHostKey	= @"host";
static NSString *const kDGSYandexDownloadInfoPathKey	= @"path";
static NSString *const kDGSYandexDownloadInfoSKey		= @"s";
static NSString *const kDGSYandexDownloadInfoTsKey		= @"ts";

@interface MusicDownloadController ()

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;


@end

@implementation MusicDownloadController

+ (instancetype)sharedController
{
	static MusicDownloadController *controller;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		controller = [[MusicDownloadController alloc] init];
	});

	return controller;
}

- (instancetype)init
{
	self = [super init];
	if (!self) return nil;

	_manager = [AFHTTPRequestOperationManager manager];

	AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
	responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/xml", @"application/xml", nil];
	_manager.responseSerializer = responseSerializer;

	return self;
}

- (void)getInfoForStorageDir:(NSString *)storageDir
					 trackId:(NSString *)trackId
{
	@weakify(self);

	NSString *xmlStorageDirURLString = [NSString stringWithFormat:kDGSYandexStorageDirTemplate, storageDir];

	NSURL *URL = [NSURL URLWithString:xmlStorageDirURLString];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];

	NSURLSession *session = [NSURLSession sharedSession];
	NSURLSessionDataTask *task = [session dataTaskWithRequest:request
										 completionHandler:
	 ^(NSData *data, NSURLResponse *response, NSError *error) {
				@strongify(self);

				NSLog(@"Storage Response: %@", response);

				NSDictionary *xmlDictionary = [NSDictionary dictionaryWithXMLData:data];
				NSLog(@"Response dictionary: %@", xmlDictionary);

				[self getDownloadInfoWithStorageDir:storageDir
										   filename:xmlDictionary[kDGSYandexStorageFilenameKey]
										    trackId:trackId];
	 }];

	[task resume];

//	[self.manager GET:xmlStorageDirURLString
//		   parameters:nil
//			  success:^(AFHTTPRequestOperation *operation, id responseObject) {
//				@strongify(self);
//
//				NSData *data = (NSData *)responseObject;
//				NSDictionary *xmlDictionary = [NSDictionary dictionaryWithXMLData:data];
//				NSLog(@"Response dictionary: %@", xmlDictionary);
//
//				[self getDownloadInfoWithStorageDir:storageDir
//										   filename:xmlDictionary[kDGSYandexStorageFilenameKey]
//										    trackId:trackId];
//			  }
//			  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//				NSLog(@"Error Getting Storage: %@", error);
//			  }];
}

- (void)getDownloadInfoWithStorageDir:(NSString *)storageDir
							 filename:(NSString *)filename
							  trackId:(NSString *)trackId
{
	@weakify(self);

	NSString *xmlDownloadInfoURLString = [NSString stringWithFormat:kDGSYandexDownloadInfoTemplate,
											storageDir, filename];

	NSURL *URL = [NSURL URLWithString:xmlDownloadInfoURLString];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];

	NSURLSession *session = [NSURLSession sharedSession];
	NSURLSessionDataTask *task = [session dataTaskWithRequest:request
										 completionHandler:
	 ^(NSData *data, NSURLResponse *response, NSError *error) {
				@strongify(self);

				NSLog(@"Info Response: %@", response);
				NSDictionary *xmlDictionary = [NSDictionary dictionaryWithXMLData:data];
				NSLog(@"Response dictionary: %@", xmlDictionary);

				NSString *trackKey = [self trackKeyFromPath:xmlDictionary[kDGSYandexDownloadInfoPathKey]
														  s:xmlDictionary[kDGSYandexDownloadInfoSKey]];
				[self getMP3WithHost:xmlDictionary[kDGSYandexDownloadInfoHostKey]
							trackKey:trackKey
								  ts:xmlDictionary[kDGSYandexDownloadInfoTsKey]
								path:xmlDictionary[kDGSYandexDownloadInfoPathKey]
							 trackId:trackId];
	 }];

	[task resume];

//	[self.manager GET:xmlDownloadInfoURLString
//		   parameters:nil
//			  success:^(AFHTTPRequestOperation *operation, id responseObject) {
//				@strongify(self);
//
//				NSData *data = (NSData *)responseObject;
//				NSDictionary *xmlDictionary = [NSDictionary dictionaryWithXMLData:data];
//				NSLog(@"Response dictionary: %@", xmlDictionary);
//
//				NSString *trackKey = [self trackKeyFromPath:xmlDictionary[kDGSYandexDownloadInfoPathKey]
//														  s:xmlDictionary[kDGSYandexDownloadInfoSKey]];
//				[self getMP3WithHost:xmlDictionary[kDGSYandexDownloadInfoHostKey]
//							trackKey:trackKey
//								  ts:xmlDictionary[kDGSYandexDownloadInfoTsKey]
//								path:xmlDictionary[kDGSYandexDownloadInfoPathKey]
//							 trackId:trackId];
//			  }
//			  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//				NSLog(@"Error Getting DownloadInfo: %@", error);
//			  }];
}

- (void)getMP3WithHost:(NSString *)host
			  trackKey:(NSString *)trackKey
					ts:(NSString *)ts
				  path:(NSString *)path
			   trackId:(NSString *)trackId
{
	NSString *hash = [self md5String:[kDGSYandexMD5Salt stringByAppendingString:trackKey]];
	NSString *fullPath = [ts stringByAppendingString:path];
	NSString *mp3DownloadInfoURLString = [NSString stringWithFormat:kDGSYandexMP3MD5Template,
											host, hash, fullPath, trackId];

	NSURL *URL = [NSURL URLWithString:mp3DownloadInfoURLString];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];

	NSURLSession *session = [NSURLSession sharedSession];
//	NSURLSessionDataTask *task = [session dataTaskWithRequest:request
//											completionHandler:
//	 ^(NSData *data, NSURLResponse *response, NSError *error) {
//				NSLog(@"MP3 Response: %@", response);
//				NSLog(@"MP3 Data: %@", data);
//
//			NSLog(@"MP3 Error: %@", error);
//	 }];

	NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
		completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
			[[BGMusicPlayer sharedPlayer] playFile:location];
			NSLog(@"MP3 Location: %@", location);

			if (error)
			{
				NSLog(@"MP3 Error: %@", error);
			}
	}];

	[task resume];

//	[self.manager GET:mp3DownloadInfoURLString
//		   parameters:nil
//			  success:^(AFHTTPRequestOperation *operation, id responseObject) {
////				@strongify(self);
//
////				NSData *data = (NSData *)responseObject;
//
//				NSLog(@"Response mp3: %@", responseObject);
//
//			  }
//			  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//				NSLog(@"Error Getting MP3: %@", error);
//			  }];
}

- (NSString *)trackKeyFromPath:(NSString *)path s:(NSString *)s
{
	return [[path substringFromIndex:1] stringByAppendingString:s];
}

- (NSString *)md5String:(NSString*)concat
{
    const char *concat_str = [concat UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(concat_str, (CC_LONG)strlen(concat_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];

	NSLog(@"Hash: %@", hash);
    return [hash lowercaseString];
}

@end
