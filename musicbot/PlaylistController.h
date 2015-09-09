#import <Foundation/Foundation.h>

@interface PlaylistController : NSObject

// @{ trackId : trackLocalURL} - trackId is that we accept from bot
@property (nonatomic, copy, readonly) NSDictionary *localPlaylist;

+ (instancetype)sharedController;

- (NSURL)savedFileURLByTemporaryURL:(NSURL *)temporaryURL withFileName:(NSString *)fileName;

@end
