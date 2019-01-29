//
//  JGCameraSource.m
//  JGVideoImage
//
//  Created by mtgao on 2019/1/14.
//

#import "JGCameraSource.h"

typedef void (^MediaDataBlock)(CMSampleBufferRef samplebuffer, NSError *error);

@interface JGCameraSource()<AVCaptureVideoDataOutputSampleBufferDelegate>
{

    AVCaptureSession* _session;
    dispatch_queue_t _videoQueue;
    
    AVCaptureVideoDataOutput *_videoOutput;

    
    MediaDataBlock _videoDataBlock,_audioDataBlock;
}
@end

@implementation JGCameraSource
-(void)captureVideoData:(void (^)(CMSampleBufferRef samplebuffer, NSError *error))completion{
    
}

@end
