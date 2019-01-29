//
//  JGImageConverter.m
//  JGVideoImage
//
//  Created by mtgao on 2019/1/17.
//

#import "JGImageConverter.h"

@implementation JGImageConverter
+ (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    
    CIImage *ciimage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef imageRef = [context createCGImage:ciimage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer) ) ];
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}
@end
