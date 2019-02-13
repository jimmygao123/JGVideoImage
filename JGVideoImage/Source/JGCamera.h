//
//  JGCamera.h
//  JGVideoImage
//
//  Created by mtgao on 2019/1/11.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "JGCameraPreview.h"

NS_ASSUME_NONNULL_BEGIN


@interface JGCamera : NSObject

//current worked camera;
@property (nonatomic, strong) AVCaptureDeviceInput *camera;
@property (nonatomic, copy) NSString *sessionPreset;
@property (nonatomic, strong) JGCameraPreview *preview;


@property (nonatomic, assign, getter=isLivePhotoCaptureEnabled) BOOL livePhotoCaptureEnabled;

-(void)captureVideoData:(void (^)(CMSampleBufferRef samplebuffer, NSError *error))completion;
-(void)captureAudioData:(void (^)(CMSampleBufferRef samplebuffer, NSError *error))completion;
-(void)takePhoto:(void (^)(AVCapturePhoto *photo, NSError *error))completion API_AVAILABLE(ios(11.0));

-(void)switchCamera;

-(void)cameraDebugInfo;
@end

NS_ASSUME_NONNULL_END
