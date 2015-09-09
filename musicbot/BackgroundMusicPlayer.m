#import "BackgroundMusicPlayer.h"
#include "PlaylistController.h"

#import <AVFoundation/AVFoundation.h>

@interface BackgroundMusicPlayer()

@property (nonatomic, strong) AVAudioPlayer *avPlayer;
@property (nonatomic, strong) AVQueuePlayer *avQueuePlayer;
@property (nonatomic, copy) NSDictionary *playList;
@property (nonatomic, copy) NSArray *songList;
@property (nonatomic, copy) NSArray *itemsArray;

@end

@implementation BackgroundMusicPlayer

+ (instancetype)sharedPlayer
{
	static BackgroundMusicPlayer *player;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		player = [[BackgroundMusicPlayer alloc] init];
	});

	return player;
}

- (instancetype)init
{
	self = [super init];
	if (!self) return nil;

	 // Set audio category with options - for this demo we'll do playback only
    NSError *__autoreleasing categoryError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
										   error:&categoryError];
    
    if (categoryError) {
        NSLog(@"Error setting category! %@", [categoryError description]);
    }
    
    // Activation of audio session
    NSError *__autoreleasing activationError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setActive:YES
														error:&activationError];
    if (!success)
	{
        if (activationError)
		{
            NSLog(@"Could not activate audio session. %@", [activationError localizedDescription]);
        } else
		{
            NSLog(@"audio session could not be activated!");
        }
    }

	NSDictionary *playlist = [PlaylistController sharedController].playlist.copy;
	_songList = [playlist allValues].copy;

	NSMutableArray *itemsArray = [NSMutableArray arrayWithCapacity:_songList.count];

	for (NSString *urlString in _songList)
	{
		[itemsArray addObject:[[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:urlString]]];
	}

	_itemsArray = itemsArray.copy;

	_avQueuePlayer = [[AVQueuePlayer alloc] initWithItems:self.itemsArray];

	return self;
}

- (void)playFile:(NSURL *)fileURL
{
	NSError *__autoreleasing error;
	self.avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
	if (!error)
	{
		[self.avPlayer play];
	}
	else
	{
		NSLog(@"Player creating error: %@", error);
	}
}

- (void)play
{
//	if (self.avPlayer)
//	{
//		[self.avPlayer play];
//	}
	if (self.avQueuePlayer)
	{
		[self.avQueuePlayer play];
	}
}

- (void)stop
{
	if (self.avPlayer)
	{
		[self.avPlayer pause];
	}
}

@end
