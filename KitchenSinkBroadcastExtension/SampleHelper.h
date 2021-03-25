#import <CoreMedia/CoreMedia.h>
#import "ScreenShare.h"

@class LLBSDConnectionClient;

@interface SampleHelper: NSObject
- (void)send:(CMSampleBufferRef)sampleBuffer using:(LLBSDConnectionClient *)connection completion:(void (^)(NSError *error))completion;
- (void)sendError:(ScreenShareError)error using:(LLBSDConnectionClient *)connection;
- (ScreenShareError)errorFromDispatchMessage:(dispatch_data_t)message;
@end
