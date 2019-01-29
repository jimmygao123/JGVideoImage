//
//  JGImageConverter.h
//  JGVideoImage
//
//  Created by mtgao on 2019/1/17.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface JGImageConverter : NSObject
+ (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

NS_ASSUME_NONNULL_END
