//
//  JGCamera.m
//  JGVideoImage
//
//  Created by mtgao on 2019/1/11.
//

#import "JGCamera.h"
#import "JGImageConverter.h"

typedef void (^MediaDataBlock)(CMSampleBufferRef samplebuffer, NSError *error);
API_AVAILABLE(ios(11.0))
typedef void (^PhotoBlock) (AVCapturePhoto *photo, NSError *error);


API_AVAILABLE(ios(11.0))
@interface JGCamera()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCapturePhotoCaptureDelegate>
{
    AVCaptureDeviceDiscoverySession* _videoDeviceDiscoverySession;
    
    AVCaptureSession* _session;
//    dispatch_queue_t _sessionQueue;
    dispatch_queue_t _videoQueue, _audioQueue;
    
    AVCaptureVideoDataOutput *_videoOutput;
    AVCapturePhotoOutput* _photoOutput;
    
    MediaDataBlock _videoDataBlock,_audioDataBlock;
    PhotoBlock _photoBlock;
    
    UIImage *testImage;
}

@end


@implementation JGCamera
#pragma mark --Public---
-(void)captureVideoData:(void (^)(CMSampleBufferRef samplebuffer, NSError *error))completion{
//    dispatch_async(_sessionQueue, ^{
        if(!self->_session.isRunning){
            [self->_session startRunning];
        }
        self->_videoDataBlock = completion;
//    });
    
}
-(void)captureAudioData:(void (^)(CMSampleBufferRef samplebuffer, NSError *error))completion{
    
}
-(void)takePhoto:(void (^)(AVCapturePhoto *photo, NSError *error))completion API_AVAILABLE(ios(11.0)){
    if(_photoOutput){
//        AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)}];
        AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];
        photoSettings.highResolutionPhotoEnabled = YES;
        [_photoOutput capturePhotoWithSettings:photoSettings delegate:self];
    }
    self->_photoBlock = completion;
}

-(void)switchCamera{
    
    AVCaptureDevice *currentDevice = self.camera.device;
    AVCaptureDevicePosition currentPosition = currentDevice.position;
    
    AVCaptureDevicePosition preferredPosition;
    AVCaptureDeviceType preferredDeviceType;
    
    switch (currentPosition)
    {
        case AVCaptureDevicePositionUnspecified:
        case AVCaptureDevicePositionFront:
            preferredPosition = AVCaptureDevicePositionBack;
            preferredDeviceType = AVCaptureDeviceTypeBuiltInWideAngleCamera;
            break;
        case AVCaptureDevicePositionBack:
            preferredPosition = AVCaptureDevicePositionFront;
            preferredDeviceType = AVCaptureDeviceTypeBuiltInWideAngleCamera;
            break;
    }
    
    NSArray <AVCaptureDevice *> *devices = _videoDeviceDiscoverySession.devices;
    AVCaptureDevice* newVideoDevice = nil;
    
    
//    // First, look for a device with both the preferred position and device type.
    for (AVCaptureDevice* device in devices) {
        if (device.position == preferredPosition && [device.deviceType isEqualToString:preferredDeviceType]) {
            newVideoDevice = device;
            break;
        }
    }

    // Otherwise, look for a device with only the preferred position.
    if (!newVideoDevice) {
        for (AVCaptureDevice* device in devices) {
            if (device.position == preferredPosition) {
                newVideoDevice = device;
                break;
            }
        }
    }
    
    if(newVideoDevice){
        AVCaptureDeviceInput* newCamera = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:NULL];
        
        [_session beginConfiguration];

        [_session removeInput:_camera];
        if([_session canAddInput:newCamera]){
            [_session addInput:newCamera];
            self.camera = newCamera;
        }else{
            [_session addInput:self.camera];
        }
        
        _photoOutput.livePhotoCaptureEnabled = _photoOutput.isLivePhotoCaptureSupported;
        [_session commitConfiguration];
    }
}

#pragma mark --LifeCycle--
-(instancetype)init{
    if(self = [super init]){
        // Create the AVCaptureSession.
        _session = [[AVCaptureSession alloc] init];
        _sessionPreset = AVCaptureSessionPresetPhoto;
        
        // Create a device discovery session.
        if (@available(iOS 10.0, *)) {
            if (@available(iOS 10.2, *)) {
                if (@available(iOS 11.1, *)) {
                    NSArray<AVCaptureDeviceType>* deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInTrueDepthCamera];
                    _videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
                } else {
                    // Fallback on earlier versions
                }
            } else {
                // Fallback on earlier versions
            }
        } else {
            // Fallback on earlier versions
        }
        
//        _sessionQueue = dispatch_queue_create("com.jgvideoimage.camerasession", DISPATCH_QUEUE_SERIAL);
        
//        [self requestPerssions];
//        dispatch_async(_sessionQueue, ^{
            [self configureSession];
        
        
//        });
    }
    return self;
}

#pragma mark ---System Delegate---
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    if(output == _videoOutput){
        if(_videoDataBlock){
            CVPixelBufferRef pb = CMSampleBufferGetImageBuffer(sampleBuffer);
            CVPixelBufferLockBaseAddress(pb, 0);
//            CVPixelBufferRetain(pb);
            _videoDataBlock(sampleBuffer,nil);
            testImage = [JGImageConverter imageFromPixelBuffer:pb];

            CVPixelBufferUnlockBaseAddress(pb, 0);
//            CVPixelBufferRelease(pb);
        }else{
            _videoDataBlock(nil, nil);
        }
    }
    
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings API_AVAILABLE(ios(10.0)){
    if(output == _photoOutput){
        NSLog(@"jimmy_%@",resolvedSettings);
    }
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error NS_AVAILABLE_IOS(11_0) {
    
    NSLog(@"jimmy_%@",photo);
    if(output == _photoOutput){
        if(photo.isRawPhoto){
            
        }else{
            if(_photoBlock){
                CVPixelBufferLockBaseAddress(photo.pixelBuffer, 0);
                _photoBlock(photo, error);
                CVPixelBufferUnlockBaseAddress(photo.pixelBuffer, 0);
            }
        }
        
    }
}

#pragma mark ---Setter, Getter---
- (void)setPreview:(JGCameraPreview *)preview{
    preview.session = _session;
}

- (void)setSessionPreset:(NSString *)sessionPreset{
    if(_sessionPreset != sessionPreset){
        
        _sessionPreset = sessionPreset;

        [_session beginConfiguration];

        if([_session canSetSessionPreset:sessionPreset]){
            _session.sessionPreset = sessionPreset;
            _sessionPreset = sessionPreset;

        }else{
            NSLog(@"不支持改Preset:%@",sessionPreset);
        }

        if([_photoOutput isLivePhotoCaptureSupported]){
            _photoOutput.livePhotoCaptureEnabled = [_photoOutput isLivePhotoCaptureSupported];
        }

        [_session commitConfiguration];
    }
}

- (void)setLivePhotoCaptureEnabled:(BOOL)livePhotoCaptureEnabled{
    [_session beginConfiguration];
    if([_photoOutput isLivePhotoCaptureSupported]){
        _photoOutput.livePhotoCaptureEnabled = livePhotoCaptureEnabled;
    }
    [_session commitConfiguration];
}

-(BOOL)isLivePhotoCaptureEnabled{
    return (_photoOutput.isLivePhotoCaptureSupported && _photoOutput.livePhotoCaptureEnabled);
}


#pragma mark ---Private----

- (void)removePhotoOutput{
    [_session beginConfiguration];
    if(_photoOutput){
        [_session removeOutput:_photoOutput];
    }
    [_session commitConfiguration];
}

- (void)removeInputsAndOutput{
    [_session beginConfiguration];
    if(_photoOutput){
        [_session removeOutput:_photoOutput];
        _photoOutput = nil;
    }
    if(_videoOutput){
        [_session removeOutput:_videoOutput];
        _videoOutput = nil;
    }
    if(_camera){
        [_session removeInput:_camera];
        _camera = nil;
    }
    
    if(_videoQueue){
        
    }
    if(_audioQueue){
        
    }
    [_session commitConfiguration];
}

- (void)requestPerssions{
    
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo])
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            break;
        }
        default:
        {
//            dispatch_suspend(_sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
//                dispatch_resume(self->_sessionQueue);
            }];
            break;
        }
    }
    
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio])
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            break;
        }
        default:
        {
//            dispatch_suspend(_sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
//                dispatch_resume(self->_sessionQueue);
            }];
            break;
        }
    }
}

- (void) configureSession
{
    
//    if (self.setupResult != AVCamSetupResultSuccess) {
//        return;
//    }
    [_session beginConfiguration];
    
    /*
     We do not create an AVCaptureMovieFileOutput when setting up the session because
     Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
     */
//    _sessionPreset = AVCaptureSessionPresetPhoto;
    _session.sessionPreset = _sessionPreset;
    
    [self configureVideoInput];
//    // Add audio input.
//    AVCaptureDevice* audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
//    AVCaptureDeviceInput* audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
//    if (!audioDeviceInput) {
//        NSLog(@"Could not create audio device input: %@", error);
//    }
//    if ([_session canAddInput:audioDeviceInput]) {
//        [_session addInput:audioDeviceInput];
//    }
//    else {
//        NSLog(@"Could not add audio device input to the session");
//    }
//

    [self configurePhotoOutput];
//    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    
    [self configureVideoOutput];
  
    if ([_session canAddOutput:_videoOutput])
    {
        [_session addOutput:_videoOutput];
//        _videoOutput = videoOutput;
    }else
    {
        NSLog(@"Couldn't add video output");
    }
    
    [_session commitConfiguration];
}

- (void)configurePhotoOutput{
    // Add photo output.
    if (@available(iOS 10.0, *)) {
        AVCapturePhotoOutput* photoOutput = [[AVCapturePhotoOutput alloc] init];
        if ([_session canAddOutput:photoOutput]) {
            [_session addOutput:photoOutput];
            
            
            photoOutput.highResolutionCaptureEnabled = YES;

            if([photoOutput isLivePhotoCaptureSupported]){
                photoOutput.livePhotoCaptureEnabled = YES;
            }
            _photoOutput = photoOutput;
            
            //            _photoOutput.livePhotoCaptureEnabled = _photoOutput.livePhotoCaptureSupported;
            //            if (@available(iOS 11.0, *)) {
            //                _photoOutput.depthDataDeliveryEnabled = _photoOutput.depthDataDeliverySupported;
            //            } else {
            //                // Fallback on earlier versions
            //            }
            //            if (@available(iOS 12.0, *)) {
            //                _photoOutput.portraitEffectsMatteDeliveryEnabled = _photoOutput.portraitEffectsMatteDeliverySupported;
            //            } else {
            //                // Fallback on earlier versions
            //            }
            //        self.livePhotoMode = self.photoOutput.livePhotoCaptureSupported ? AVCamLivePhotoModeOn : AVCamLivePhotoModeOff;
            //        self.depthDataDeliveryMode = self.photoOutput.depthDataDeliverySupported ? AVCamDepthDataDeliveryModeOn : AVCamDepthDataDeliveryModeOff;
            //        self.portraitEffectsMatteDeliveryMode = self.photoOutput.portraitEffectsMatteDeliverySupported ? AVCamPortraitEffectsMatteDeliveryModeOn : AVCamPortraitEffectsMatteDeliveryModeOff;
            //
            //        self.inProgressPhotoCaptureDelegates = [NSMutableDictionary dictionary];
            //        self.inProgressLivePhotoCapturesCount = 0;
        }
        else {
            NSLog(@"Could not add photo output to the session");
            //        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
            [_session commitConfiguration];
            return;
        }
    } else {
        // Fallback on earlier versions
    }
    
}

- (void)configureVideoOutput{
    
    _videoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
    _audioQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,0);
    
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoOutput setAlwaysDiscardsLateVideoFrames:NO];
    //    [_videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [_videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
}

- (void)configureVideoInput{
    
    // Add video input.
    NSError *error;
    
    // Choose the back dual camera if available, otherwise default to a wide angle camera.
    if (@available(iOS 10.2, *)) {
        AVCaptureDevice* videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        if (!videoDevice) {
            //             If a rear dual camera is not available, default to the rear wide angle camera.
            videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
            
            //             In the event that the rear wide angle camera isn't available, default to the front wide angle camera.
            if (!videoDevice) {
                videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
            }
        }
        AVCaptureDeviceInput* videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        if (!videoDeviceInput) {
            NSLog(@"Could not create video device input: %@", error);
            //        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
            [_session commitConfiguration];
            return;
        }
        if ([_session canAddInput:videoDeviceInput]) {
            [_session addInput:videoDeviceInput];
            _camera = videoDeviceInput;
            
        } else {
            // Fallback on earlier versions
        }
        
        //        dispatch_async(dispatch_get_main_queue(), ^{
        //            /*
        //             Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
        //             You can manipulate UIView only on the main thread.
        //             Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
        //             on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
        //
        //             Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
        //             handled by CameraViewController.viewWillTransition(to:with:).
        //             */
        //            UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        //            AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
        //            if (statusBarOrientation != UIInterfaceOrientationUnknown) {
        //                initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
        //            }
        //
        //            self.previewView.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
        //        });
    }else {
        NSLog(@"Could not add video device input to the session");
        //        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [_session commitConfiguration];
        return;
    }
}

-(void)cameraDebugInfo{
    NSArray *formats = self.camera.device.formats;
    AVCaptureDeviceFormat *activeformat = self.camera.device.activeFormat;
    NSLog(@"jimmy_ formats = %@,activeformat = %@",formats,activeformat);
    NSLog(@"jimmy_ camera = %@, camera = %@", self.camera,self.camera.device);
//    NSLog(@"jimmy_ HighRes = %@",self.camera.device.activeFormat.highResolutionStillImageDimensions);
    
    NSLog(@"jimmy_ sessionformat = %@", _session);
    
    NSLog(@"jimmy_ photoOutput.HiRes:%d",_photoOutput.isHighResolutionCaptureEnabled);
    NSLog(@"jimmy_ photoOutput.livePhoto:%d",_photoOutput.isLivePhotoCaptureEnabled);
}
@end
