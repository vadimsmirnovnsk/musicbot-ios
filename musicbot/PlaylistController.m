#import "PlaylistController.h"

#import "BackgroundMusicPlayer.h"

static NSString *const kDGSPlaylistArrayKey = @"Playlist";

@interface PlaylistController ()

@property (nonatomic, strong) NSMutableArray *privatePlaylist;

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

	_privatePlaylist = [[NSUserDefaults standardUserDefaults] arrayForKey:kDGSPlaylistArrayKey].mutableCopy;

	if (!_privatePlaylist)
	{
		_privatePlaylist = [[NSMutableArray alloc] init];
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
	[self.privatePlaylist addObject:fileName];
	[self savePlaylist];
	[[BackgroundMusicPlayer sharedPlayer] updateSongList];

	return docsDirURL;
}

- (void)removeCurrentTrack
{
//	NSError *err = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *trackName = [BackgroundMusicPlayer sharedPlayer].currentTrackURL.lastPathComponent;
	NSString *removeFilePath = [docsDir stringByAppendingPathComponent:trackName];

	[[BackgroundMusicPlayer sharedPlayer] killPlayer];
	[[BackgroundMusicPlayer sharedPlayer] playNext];

	NSError *error;
	if ([fileManager isDeletableFileAtPath:removeFilePath])
	{
		BOOL success = [[NSFileManager defaultManager] removeItemAtPath:removeFilePath error:&error];
		if (!success)
		{
			NSLog(@"Error removing file at path: %@", error.localizedDescription);
		}
	}

	[[BackgroundMusicPlayer sharedPlayer] updateSongList];
}

- (void)savePlaylist
{
	[[NSUserDefaults standardUserDefaults] setObject:self.privatePlaylist forKey:kDGSPlaylistArrayKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDictionary *)playlist
{
	return self.privatePlaylist.copy;
}

@end
