#import "BackgroundMusicPlayer.h"
#include "PlaylistController.h"

#import <AVFoundation/AVFoundation.h>

@interface BackgroundMusicPlayer() <AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioPlayer *avPlayer;
//@property (nonatomic, strong) AVQueuePlayer *avQueuePlayer;
@property (nonatomic, copy) NSArray *songURLs;
@property (nonatomic, assign) NSInteger currentPlayingSongNumber;

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

	_currentPlayingSongNumber = -1;

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
            NSLog(@"Audio session could not be activated!");
        }
    }

	[self updateSongList];

	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];

	return self;
}

- (NSURL *)currentTrackURL
{
	return self.avPlayer.url;
}

- (void)updateSongList
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:NULL];

	NSMutableArray *mutableSongList = [NSMutableArray arrayWithCapacity:directoryContent.count];
	for (NSString *fileName in directoryContent)
	{
		NSURL *songURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:fileName]];
		[mutableSongList addObject:songURL];
	}

	self.songURLs = mutableSongList.copy;
}

- (void)playFileWithName:(NSString *)name
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];

	NSURL *songURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:name]];
	self.avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:songURL error:nil];
	self.avPlayer.delegate = self;
	[self.avPlayer play];
}

- (void)playFile:(NSURL *)fileURL
{
	NSError *__autoreleasing error;
	self.avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
	if (!error)
	{
		[self.avPlayer play];
		self.avPlayer.delegate = self;
	}
	else
	{
		NSLog(@"Player creating error: %@", error);
	}
}

- (void)playNext
{
	if (self.songURLs.count)
	{
		self.currentPlayingSongNumber ++;

		if (self.songURLs.count <= (NSUInteger)self.currentPlayingSongNumber)
		{
			self.currentPlayingSongNumber = 0;
		}

		NSURL *nextSongURL = self.songURLs[self.currentPlayingSongNumber];
		self.avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:nextSongURL error:nil];
		self.avPlayer.delegate = self;
		[self.avPlayer play];
	}
}

- (void)play
{
	if (self.avPlayer)
	{
		[self.avPlayer play];
	}
}

- (void)stop
{
	if (self.avPlayer)
	{
		[self.avPlayer pause];
	}
}

- (NSString *)currentTrackFileName
{
	return self.avPlayer.url.absoluteString;
}

- (void)killPlayer
{
	self.avPlayer.delegate = nil;
	[self.avPlayer stop];
	self.avPlayer = nil;
}

// MARK: AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	[self playNext];
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

@end
