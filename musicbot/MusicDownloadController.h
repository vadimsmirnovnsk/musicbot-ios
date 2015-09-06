#import <Foundation/Foundation.h>

@interface MusicDownloadController : NSObject

+ (instancetype)sharedController;

- (void)getInfoForStorageDir:(NSString *)storageDir
					 trackId:(NSString *)trackId;

@end
