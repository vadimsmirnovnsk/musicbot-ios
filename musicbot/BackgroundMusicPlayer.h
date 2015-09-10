#import <Foundation/Foundation.h>

@interface BackgroundMusicPlayer : NSObject

+ (instancetype)sharedPlayer;

- (void)playFile:(NSURL *)fileURL;
- (void)playFileWithName:(NSString *)name;
- (void)playNext;
- (void)play;
- (void)stop;

- (void)updateSongList;

@end
