//
//  JGCameraPreview.m
//  JGVideoImage
//
//  Created by mtgao on 2019/1/18.
//

#import "JGCameraPreview.h"

@implementation JGCameraPreview

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer*) videoPreviewLayer
{
    return (AVCaptureVideoPreviewLayer *)self.layer;
}


- (AVCaptureSession *)session{
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session{
    self.videoPreviewLayer.session = session;
}

@end
