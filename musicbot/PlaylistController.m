#import "PlaylistController.h"

static NSString *const kDGSPlaylistDictionaryKey = @"Playlist";

@interface PlaylistController ()

@property (nonatomic, strong) NSMutableDictionary *privatePlaylist;

@end

@implementation PlaylistController

+ (instancetype)sharedController
{
	static PlaylistController *controller;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		controller = [[PlaylistController alloc] init];
	});

	return controller;
}

- (instancetype)init
{
	self = [super init];
	if (!self) return nil;

	_privatePlaylist = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kDGSPlaylistDictionaryKey].mutableCopy;

	if (!_privatePlaylist)
	{
		_privatePlaylist = [[NSMutableDictionary alloc] init];
	}

	return self;
}

- (NSURL *)savedFileURLByTemporaryURL:(NSURL *)temporaryURL withFileName:(NSString *)fileName
{
	NSError *err = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *destinationFilename = fileName;
 
	NSURL *docsDirURL = [NSURL fileURLWithPath:[docsDir stringByAppendingPathComponent:destinationFilename]];

	if ([fileManager fileExistsAtPath:docsDirURL.path])
	{
		[fileManager replaceItemAtURL:docsDirURL
						withItemAtURL:temporaryURL
					   backupItemName:nil
							  options:NSFileManagerItemReplacementUsingNewMetadataOnly
					 resultingItemURL:nil
								error:&err];
	}
	else
	{
		if (![fileManager moveItemAtURL:temporaryURL
							 toURL:docsDirURL
							 error: &err])
		{
			NSLog(@"ERROR: MP3 wasn't saved: %@", docsDirURL);
			return nil;
		}
	}

	NSLog(@"MP3 was saved: %@", docsDirURL);
	[self.privatePlaylist setValue:[docsDirURL absoluteString] forKey:fileName];
	[self savePlaylist];

	return docsDirURL;
}

- (void)savePlaylist
{
	[[NSUserDefaults standardUserDefaults] setObject:self.privatePlaylist forKey:kDGSPlaylistDictionaryKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDictionary *)playlist
{
	return self.privatePlaylist.copy;
}

@end
