#import <Foundation/Foundation.h>

@interface BGMusicPlayer : NSObject

+ (instancetype)sharedPlayer;

- (void)playFile:(NSURL *)fileURL;

@end
