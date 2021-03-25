#import <Foundation/Foundation.h>

static const uint8_t ScreenShareConnectionIdentifier = 45;

typedef NS_ENUM(int8_t, ScreenShareError) {
    ScreenShareErrorNone = 0,
    ScreenShareErrorFatal = -1,
    ScreenShareErrorNoActiveCall = -2,
    ScreenShareErrorNoAuxiliaryDevice = -3,
    ScreenShareErrorOpenSocketFail = -4,
    ScreenShareErrorAuxiliaryDeviceBusy = -5,
    ScreenShareErrorShareReleased = -6,
    ScreenShareErrorDisabled = -7
};

typedef struct __FrameMessage {
    ScreenShareError error;
    uint32_t timestamp;
    int32_t width;
    int32_t height;
    uint32_t length;
} FrameMessage;

typedef struct {
    ScreenShareError error;
} FeedbackMessage;
