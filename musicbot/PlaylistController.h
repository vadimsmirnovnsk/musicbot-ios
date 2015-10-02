#import <Foundation/Foundation.h>

@interface PlaylistController : NSObject

// @{ trackId : trackLocalURL} - trackId is that we accept from bot
@property (nonatomic, copy, readonly) NSArray *playlist;

+ (instancetype)sharedController;

- (NSURL *)savedFileURLByTemporaryURL:(NSURL *)temporaryURL withFileName:(NSString *)fileName;
- (void)removeCurrentTrack;

@end
