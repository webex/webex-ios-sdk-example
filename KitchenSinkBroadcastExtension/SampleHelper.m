#import "SampleHelper.h"
#import <Accelerate/Accelerate.h>
#import <ReplayKit/ReplayKit.h>
#import "LLBSDConnection.h"

@implementation SampleHelper

- (void)send:(CMSampleBufferRef)sampleBuffer using:(LLBSDConnectionClient *)connection completion:(void (^)(NSError *error))completion {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    uint8_t rotationConstant = 0;
    NSNumber *orientation = CMGetAttachment(sampleBuffer, (CFStringRef)RPVideoSampleOrientationKey, NULL);
    if (orientation) {
        switch ((CGImagePropertyOrientation)[orientation integerValue]) {
            case kCGImagePropertyOrientationUp:
            case kCGImagePropertyOrientationUpMirrored:
                rotationConstant = 0;
                break;
            case kCGImagePropertyOrientationDown:
            case kCGImagePropertyOrientationDownMirrored:
                rotationConstant = 2;
                break;
            case kCGImagePropertyOrientationRight:
            case kCGImagePropertyOrientationRightMirrored:
                rotationConstant = 1;
                break;
            case kCGImagePropertyOrientationLeft:
            case kCGImagePropertyOrientationLeftMirrored:
                rotationConstant = 3;
                break;
        }
    }
    
    FrameMessage message;
    // Timestamp calculated in milliseconds, and dimensions calculated based on rotation.
    message.error = ScreenShareErrorNone;
    message.timestamp = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) * 1000;
    // Rotation constant is a multiple of 90 degrees counterclockwise, so swap dimensions if necessary.
    if (rotationConstant % 2 == 0) {
        message.width = (int32_t)CVPixelBufferGetWidth(pixelBuffer);
        message.height = (int32_t)CVPixelBufferGetHeight(pixelBuffer);
    } else {
        message.width = (int32_t)CVPixelBufferGetHeight(pixelBuffer);
        message.height = (int32_t)CVPixelBufferGetWidth(pixelBuffer);
    }
    // 420f/v has two planes with one byte/pixel in plane 0 and two bytes/pixel in plane 1.
    // However, plane 1 is subsampled so its resolution is a quarter of the total image.
    message.length = message.width * message.height * 1.5;
    
    // Desintation planes are contiguous and have no stride (extra bytes per row) for input into WME.
    void *bytes = calloc(message.length, sizeof(uint32_t));
    if (bytes == NULL) {
//        LogError(@"Unable to create destination buffer");
        completion(nil);
        return;
    }
    
//    LogInfo(@"timestamp: %d, width: %d, height: %d, length: %d, bytes: %p, sizeof(FrameMessage): %lu", message.timestamp, message.width, message.height, message.length, bytes, sizeof(FrameMessage));
    
    vImage_Buffer dstPlane0 = { .width = message.width, .height = message.height };
    dstPlane0.rowBytes = dstPlane0.width;
    dstPlane0.data = bytes;
    vImage_Buffer dstPlane1 = { .width = message.width / 2, .height = message.height / 2 };
    dstPlane1.rowBytes = dstPlane1.width * 2;
    dstPlane1.data = (unsigned char *)bytes + (message.width * message.height);
    
    // Source planes are references to the original CVPixelBuffer data, so take a read-only lock.
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    vImage_Buffer srcPlane0 = { .data = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0),
        .height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0),
        .width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0),
        .rowBytes = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0) };
    vImage_Buffer srcPlane1 = { .data = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1),
        .height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1),
        .width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1),
        .rowBytes = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1) };
    
    vImage_Error error;
    // Rotate each plane individually from the source to the destination, using vImage Rotate90 rotationConstant.
    error = vImageRotate90_Planar8(&srcPlane0, &dstPlane0, rotationConstant, 0, kvImageNoFlags);
    if (error != kvImageNoError) {
//        LogError(@"Rotate plane 0 error %zd", error);
    }
    error = vImageRotate90_Planar16U(&srcPlane1, &dstPlane1, rotationConstant, 0, kvImageNoFlags);
    if (error != kvImageNoError) {
//        LogError(@"Rotate plane 1 error %zd", error);
    }
    
    // Release the read-only lock and concatenate the header with raw data.
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    dispatch_data_t header = dispatch_data_create(&message, sizeof(FrameMessage), NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    dispatch_data_t data = dispatch_data_create(bytes, message.length, NULL, DISPATCH_DATA_DESTRUCTOR_FREE);
    [connection sendMessage:dispatch_data_create_concat(header, data) completion:completion];
}

- (void)sendError:(ScreenShareError)error using:(LLBSDConnectionClient *)connection {
    FrameMessage message;
    message.error = ScreenShareErrorFatal;
    dispatch_data_t header = dispatch_data_create(&message, sizeof(FrameMessage), NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [connection sendMessage:header completion:^(NSError *sendError) {
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (ScreenShareError)errorFromDispatchMessage:(dispatch_data_t)message {
    const void *bytes;
    size_t length;
    __unused dispatch_data_t map = dispatch_data_create_map(message, &bytes, &length);
    if (length >= sizeof(FeedbackMessage)) {
        FeedbackMessage *feedbackMessage = (FeedbackMessage *)bytes;
        return feedbackMessage->error;
    }

    return ScreenShareErrorNone;
}

@end
