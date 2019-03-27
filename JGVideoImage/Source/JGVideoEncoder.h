//
//  JGVideoEncoder.h
//  SlowMotionVideoRecorder
//
//  Created by mtgao on 2019/2/15.
//  Copyright © 2019 Shuichi Tsutsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN

typedef void (^ReturnDataBlock) (NSData *encodedData);

@interface JGVideoEncoder : NSObject

@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;

@property (nonatomic, copy) ReturnDataBlock returnDataBlock;

- (void)prepareEncoderWithWidth:(int)width andHeight:(int)height;
- (void)tearDownEncoder;

- (void)resetEncoderWithWidth:(int)width andHeight:(int) height;

- (void)pushFrame:(CMSampleBufferRef)buffer andReturnedEncodedData:(ReturnDataBlock)block;

@end

NS_ASSUME_NONNULL_END
