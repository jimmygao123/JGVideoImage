//
//  JGCameraPreview.h
//  JGVideoImage
//
//  Created by mtgao on 2019/1/18.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JGCameraPreview : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic) AVCaptureSession *session;

@end

NS_ASSUME_NONNULL_END
