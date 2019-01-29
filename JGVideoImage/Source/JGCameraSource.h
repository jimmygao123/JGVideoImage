//
//  JGCameraSource.h
//  JGVideoImage
//
//  Created by mtgao on 2019/1/14.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
NS_ASSUME_NONNULL_BEGIN

@interface JGCameraSource : NSObject
@property (nonatomic, strong) AVCaptureDeviceInput *camera;

-(void)captureVideoData:(void (^)(CMSampleBufferRef samplebuffer, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
