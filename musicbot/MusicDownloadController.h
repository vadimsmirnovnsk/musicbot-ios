#import <Foundation/Foundation.h>

@interface MusicDownloadController : NSObject

+ (instancetype)sharedController;

- (void)downloadTrackWithStorageDir:(NSString *)storageDir
							trackId:(NSString *)trackId
						  forcePlay:(BOOL)forcePlay;

@end
