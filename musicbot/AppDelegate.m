#import "AppDelegate.h"

#import "MusicDownloadController.h"
#import "BackgroundMusicPlayer.h"
#import "PlaylistController.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] registerUserNotificationSettings:
		[UIUserNotificationSettings settingsForTypes:( UIUserNotificationTypeSound |
													   UIUserNotificationTypeAlert |
													   UIUserNotificationTypeBadge) categories:nil]];

    [[UIApplication sharedApplication] registerForRemoteNotifications];

	// Autoplay
	[BackgroundMusicPlayer sharedPlayer];

	return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken>%@", deviceToken);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
   NSLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	NSLog(@"Did Receive: %@", userInfo);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
	NSLog(@"Did receive push-notification: %@", userInfo);
//	NSString *storageDir = @"20538_cad1105b.21458623";
//	NSString *trackId = @"21458623";

	NSString *action = userInfo[@"action"];

	if ([action isEqualToString:@"add"])
	{
		NSString *rawStorageDir = userInfo[@"storageDir"];
		NSString *storageDir = [rawStorageDir stringByReplacingOccurrencesOfString:@"`" withString:@""];
		NSArray *storageDirComponents = [storageDir componentsSeparatedByString:@"."];
		NSString *trackId = storageDirComponents.lastObject;

		if (storageDir.length && trackId.length)
		{
			NSArray *existingTrackNames = [PlaylistController sharedController].playlist;

			if ([existingTrackNames containsObject:storageDir])
			{
				[[BackgroundMusicPlayer sharedPlayer] playFileWithName:storageDir];
			}
			else
			{
				[[MusicDownloadController sharedController] downloadTrackWithStorageDir:storageDir
																				trackId:trackId
																			  forcePlay:NO];
			}
		}
	}
	else if ([action isEqualToString:@"force"])
	{
		NSString *rawStorageDir = userInfo[@"storageDir"];
		NSString *storageDir = [rawStorageDir stringByReplacingOccurrencesOfString:@"`" withString:@""];
		NSArray *storageDirComponents = [storageDir componentsSeparatedByString:@"."];
		NSString *trackId = storageDirComponents.lastObject;

		if (storageDir.length && trackId.length)
		{
			NSArray *existingTrackNames = [PlaylistController sharedController].playlist;

			if ([existingTrackNames containsObject:storageDir])
			{
				[[BackgroundMusicPlayer sharedPlayer] playFileWithName:storageDir];
			}
			else
			{
				[[MusicDownloadController sharedController] downloadTrackWithStorageDir:storageDir
																				trackId:trackId
																			  forcePlay:YES];
			}
		}
	}
	else if ([action isEqualToString:@"stop"])
	{
		[[BackgroundMusicPlayer sharedPlayer] stop];
	}
	else if ([action isEqualToString:@"play"])
	{
		[[BackgroundMusicPlayer sharedPlayer] play];
	}
	else if ([action isEqualToString:@"next"])
	{
		[[BackgroundMusicPlayer sharedPlayer] playNext];
	}

	completionHandler(UIBackgroundFetchResultNewData);
}

@end
