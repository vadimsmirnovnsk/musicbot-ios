#import "BGMusicPlayer.h"

#import <AVFoundation/AVFoundation.h>

@interface BGMusicPlayer()

@property (nonatomic, strong) AVAudioPlayer *avQueuePlayer;

@end

@implementation BGMusicPlayer

+ (instancetype)sharedPlayer
{
	static BGMusicPlayer *player;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		player = [[BGMusicPlayer alloc] init];
	});

	return player;
}

- (instancetype)init
{
	self = [super init];
	if (!self) return nil;

	 //set audio category with options - for this demo we'll do playback only
    NSError *__autoreleasing categoryError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
										   error:&categoryError];
    
    if (categoryError) {
        NSLog(@"Error setting category! %@", [categoryError description]);
    }
    
    //activation of audio session
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

	_avQueuePlayer = [[AVAudioPlayer alloc] init];

	return self;
}

- (void)playFile:(NSURL *)fileURL
{
	self.avQueuePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
	[self.avQueuePlayer play];
//	AVPlayerItem *songItem = [[AVPlayerItem alloc] initWithURL:fileURL];
//	if (songItem)
//	{
//		[[self avQueuePlayer] insertItem:songItem afterItem:nil];
//		[self play];
//	}
}

-(void) play
{
    [self.avQueuePlayer play];
}

@end
