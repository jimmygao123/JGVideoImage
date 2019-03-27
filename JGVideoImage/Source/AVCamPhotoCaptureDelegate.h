/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Provides the header for the photo capture delegate.
*/

@import AVFoundation;

API_AVAILABLE(ios(10.0))
@interface AVCamPhotoCaptureDelegate : NSObject<AVCapturePhotoCaptureDelegate>

- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)requestedPhotoSettings willCapturePhotoAnimation:(void (^)(void))willCapturePhotoAnimation livePhotoCaptureHandler:(void (^)( BOOL capturing ))livePhotoCaptureHandler completionHandler:(void (^)( AVCamPhotoCaptureDelegate *photoCaptureDelegate ))completionHandler API_AVAILABLE(ios(10.0));

@property (nonatomic, readonly) AVCapturePhotoSettings *requestedPhotoSettings;

@end
