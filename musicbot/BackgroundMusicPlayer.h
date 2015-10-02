#import <Foundation/Foundation.h>

@import UIKit;

@interface BackgroundMusicPlayer : UIResponder

@property (nonatomic, copy, readonly) NSURL *currentTrackURL;

+ (instancetype)sharedPlayer;

- (void)playFile:(NSURL *)fileURL;
- (void)playFileWithName:(NSString *)name;
- (void)playNext;
- (void)play;
- (void)stop;

- (void)updateSongList;
- (void)killPlayer;

@end
