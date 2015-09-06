#import "MusicDownloadController.h"

#import <AFNetworking/AFNetworking.h>
#import <XMLDictionary/XMLDictionary.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

static NSString *const kDGSYandexStorageDirTemplate		= @"http://storage.music.yandex.ru/get/%@/2.xml";
static NSString *const kDGSYandexDownloadInfoTemplate	= @"http://storage.music.yandex.ru/download-info/%@/%@";
static NSString *const kDGSYandexMP3Template			= @"http://%@/get-mp3/%@/%@%@?track-id=%@&region=225&from=service-search";

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
	[self.manager GET:xmlStorageDirURLString
		   parameters:nil
			  success:^(AFHTTPRequestOperation *operation, id responseObject) {
				@strongify(self);

				NSData *data = (NSData *)responseObject;
				NSDictionary *xmlDictionary = [NSDictionary dictionaryWithXMLData:data];
				NSLog(@"Response dictionary: %@", xmlDictionary);

				[self getDownloadInfoWithStorageDir:storageDir
										   filename:xmlDictionary[kDGSYandexStorageFilenameKey]
										    trackId:trackId];
			  }
			  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				NSLog(@"Error Getting Storage: %@", error);
			  }];
}

- (void)getDownloadInfoWithStorageDir:(NSString *)storageDir
							 filename:(NSString *)filename
							  trackId:(NSString *)trackId
{
	@weakify(self);

	NSString *xmlDownloadInfoURLString = [NSString stringWithFormat:kDGSYandexDownloadInfoTemplate,
											storageDir, filename];

	[self.manager GET:xmlDownloadInfoURLString
		   parameters:nil
			  success:^(AFHTTPRequestOperation *operation, id responseObject) {
				@strongify(self);

				NSData *data = (NSData *)responseObject;
				NSDictionary *xmlDictionary = [NSDictionary dictionaryWithXMLData:data];
				NSLog(@"Response dictionary: %@", xmlDictionary);

				NSString *trackKey = [self trackKeyFromPath:xmlDictionary[kDGSYandexDownloadInfoPathKey]
														  s:xmlDictionary[kDGSYandexDownloadInfoSKey]];
				[self getMP3WithHost:xmlDictionary[kDGSYandexDownloadInfoHostKey]
							trackKey:trackKey
								  ts:xmlDictionary[kDGSYandexDownloadInfoTsKey]
								path:xmlDictionary[kDGSYandexDownloadInfoPathKey]
							 trackId:trackId];
			  }
			  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				NSLog(@"Error Getting DownloadInfo: %@", error);
			  }];
}

- (void)getMP3WithHost:(NSString *)host
			  trackKey:(NSString *)trackKey
					ts:(NSString *)ts
				  path:(NSString *)path
			   trackId:(NSString *)trackId
{
	NSString *mp3DownloadInfoURLString = [NSString stringWithFormat:kDGSYandexMP3Template,
											host, trackKey, ts, path, trackId];

	[self.manager GET:mp3DownloadInfoURLString
		   parameters:nil
			  success:^(AFHTTPRequestOperation *operation, id responseObject) {
//				@strongify(self);

//				NSData *data = (NSData *)responseObject;

				NSLog(@"Response mp3: %@", responseObject);

			  }
			  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				NSLog(@"Error Getting MP3: %@", error);
			  }];
}

- (NSString *)trackKeyFromPath:(NSString *)path s:(NSString *)s
{
	return [[path substringFromIndex:1] stringByAppendingString:s];
}


//return 'http://%s/get-mp3/%s/%s%s?track-id=%d&region=225&from=service-search' % (
//            file_path_soup.find('host').text,
//            cursor.get_key(path[1:] + file_path_soup.find('s').text),
//            file_path_soup.find('ts').text,
//            path,
//            int(self.id),

@end
