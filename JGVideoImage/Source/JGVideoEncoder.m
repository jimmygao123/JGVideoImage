//
//  JGVideoEncoder.m
//  SlowMotionVideoRecorder
//
//  Created by mtgao on 2019/2/15.
//  Copyright © 2019 Shuichi Tsutsumi. All rights reserved.
//

#import "JGVideoEncoder.h"
@import VideoToolbox;

@interface JGVideoEncoder()
@property (assign, nonatomic) int fps;  //todo
@property (assign, nonatomic) int bitrate; //todo
@end

@implementation JGVideoEncoder
{
    VTCompressionSessionRef _session;
    dispatch_queue_t _queue;
    
    BOOL isReadyForEncoding;
}



- (instancetype)init{
    if (self = [super init]) {
        _width = 1280;
        _height = 720;
        _fps = 120;
        _bitrate = 5*1000*1000; //610kB
        
        _queue = dispatch_queue_create("com.jimmygao.h265encoderqueue", DISPATCH_QUEUE_SERIAL);
        _session = nil;
        
        isReadyForEncoding = NO;
    }
    return self;
}


- (void)prepareEncoderWithWidth:(int)width andHeight:(int)height{
    
    dispatch_sync(_queue, ^{
        
        self->_width = width;
        self->_height = height;
        
        OSStatus status = noErr;
        //查询机器支持的编码器
        CFArrayRef ref;
        VTCopyVideoEncoderList(NULL, &ref);
        NSLog(@"encoder list = %@",(__bridge NSArray*)ref);
        CFRelease(ref);
    
        //指定原始图像格式
        SInt32 cvPixelFormatTypeValue = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;;
        CFDictionaryRef emptyDict = CFDictionaryCreate(kCFAllocatorDefault, nil, nil, 0, nil, nil);
        CFNumberRef cvPixelFormatType = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void*)(&(cvPixelFormatTypeValue)));
        CFNumberRef frameW = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void*)(&(width)));
        CFNumberRef frameH = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void*)(&(height)));
        
        const void *pixelBufferOptionsDictKeys[] = { kCVPixelBufferPixelFormatTypeKey,
            kCVPixelBufferWidthKey,  kCVPixelBufferHeightKey, kCVPixelBufferIOSurfacePropertiesKey};
        const void *pixelBufferOptionsDictValues[] = { cvPixelFormatType,  frameW, frameH, emptyDict};
        CFDictionaryRef pixelBufferOptions = CFDictionaryCreate(kCFAllocatorDefault, pixelBufferOptionsDictKeys, pixelBufferOptionsDictValues, 4, nil, nil);
        
        //创建编码器
        status = VTCompressionSessionCreate(NULL, self.width, self.height, kCMVideoCodecType_HEVC, nil, nil, nil, didCompressFinished, (__bridge void * _Nullable)(self), &(self->_session));
        
        CFRelease(pixelBufferOptions);
        
        if(status != noErr){
            NSLog( @"create session: resolution:(%d,%d)  fps:(%d)",self.width,self.height,self.fps);
        }
        
        if(self->_session){
            
            //设置编码器属性
            status = VTSessionSetProperty(self->_session, kVTCompressionPropertyKey_RealTime,kCFBooleanTrue);
            if (@available(iOS 11.0, *)) {
                status = VTSessionSetProperty(self->_session, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_HEVC_Main_AutoLevel);
            } else {
                // Fallback on earlier versions
            }
//            status = VTSessionSetProperty(self->_session, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CAVLC);
            status = VTSessionSetProperty(self->_session, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
            
            
            //设置帧率
            int temp = self.fps;
            CFNumberRef refFPS = CFNumberCreate(NULL, kCFNumberSInt32Type, &temp);
            status = VTSessionSetProperty(self->_session, kVTCompressionPropertyKey_ExpectedFrameRate, refFPS);
            CFRelease(refFPS);
            
            //设置平均码率
            temp = self.bitrate;
            CFNumberRef refBitrate = CFNumberCreate(NULL, kCFNumberSInt32Type, &temp);
            VTSessionSetProperty(self->_session, kVTCompressionPropertyKey_AverageBitRate, refBitrate);
            CFRelease(refBitrate);
            
            //设置关键帧时间间隔
            temp = 1;
            CFNumberRef ref = CFNumberCreate(NULL, kCFNumberSInt32Type, &temp);
            VTSessionSetProperty(self->_session, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, ref);
            CFRelease(ref);
            
            //最大缓冲帧数
            temp = 3;
            CFNumberRef refFrameDelay = CFNumberCreate(NULL, kCFNumberSInt32Type, &temp);
            status = VTSessionSetProperty(self->_session, kVTCompressionPropertyKey_MaxFrameDelayCount, refFrameDelay);
            CFRelease(refFrameDelay);
            
            status = VTCompressionSessionPrepareToEncodeFrames(self->_session);
            
            self->isReadyForEncoding = YES;
        }
    });
}


- (void)tearDownEncoder{
    
    dispatch_sync(_queue, ^{
        
        if(self->_session){
            VTCompressionSessionCompleteFrames(self->_session, kCMTimeInvalid);
            VTCompressionSessionInvalidate(self->_session);
            CFRelease(self->_session);
            self->_session = NULL;
            NSLog(@"%s",__FUNCTION__);
        }
    });
}

- (void)resetEncoderWithWidth:(int)width andHeight:(int) height{
    _width = width;
    _height = height;
    
    [self tearDownEncoder];
    [self prepareEncoderWithWidth:width andHeight:height];
}

- (void)pushFrame:(CMSampleBufferRef)buffer andReturnedEncodedData:(ReturnDataBlock)block{
    
    self.returnDataBlock = block;
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(buffer);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    if((width == _width) && (height == _height)){
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(buffer);
        OSStatus status = VTCompressionSessionEncodeFrame(_session, imageBuffer, pts, kCMTimeInvalid, NULL, NULL, NULL);
        if(status != noErr){
            NSLog(@"encode frame error");
        }
    }else{
        [self resetEncoderWithWidth:(int)width andHeight:(int)height];
    }
}

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps
{
    //    NSLog(@"-------- 编码后SpsPps长度: gotSpsPps %d %d", (int)[sps length] + 4, (int)[pps length]+4);
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    NSData *startCode = [NSData dataWithBytes:bytes length:length];
    
    [self returnDataToTCPWithHeadData:startCode andData:sps];
    [self returnDataToTCPWithHeadData:startCode andData:pps];
}

- (void)gotVpsSpsPps:(NSData *)vps sps:(NSData*)sps pps:(NSData*)pps
{
    //    NSLog(@"-------- 编码后SpsPps长度: gotSpsPps %d %d", (int)[sps length] + 4, (int)[pps length]+4);
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    NSData *startCode = [NSData dataWithBytes:bytes length:length];
    
    [self returnDataToTCPWithHeadData:startCode andData:vps];
    [self returnDataToTCPWithHeadData:startCode andData:sps];
    [self returnDataToTCPWithHeadData:startCode andData:pps];
}

- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    //    NSLog(@"--------- 编码后数据长度： %d -----", (int)[data length]);
    //    NSLog(@"----------- data = %@ ------------", data);
    
    // 把每一帧的所有NALU数据前四个字节变成0x00 00 00 01之后再写入文件
    const char bytes[] = "\x00\x00\x00\x01";  // null null null 标题开始
    size_t length = (sizeof bytes) - 1; //字符串文字具有隐式结尾 '\0'  。    把上一段内容中的’\0‘去掉，
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length]; // 复制C数组所包含的数据来初始化NSData的数据
    
    [self returnDataToTCPWithHeadData:ByteHeader andData:data];
}

-(void)returnDataToTCPWithHeadData:(NSData*)headData andData:(NSData*)data
{
    //    printf("---- video 编码后的数据data大小 = %d + %d \n",(int)[headData length] ,(int)[data length]);
    NSMutableData *tempData = [NSMutableData dataWithData:headData];
    [tempData appendData:data];
    
    // 传给socket
    if (self.returnDataBlock) {
        self.returnDataBlock(tempData);
    }
}


- (void)oneSecondStatisticEncodesFPS{
    static double lastTime = 0;
    static int encodes = 0;
    encodes ++;
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    if(timeInterval - lastTime > 1){
        NSLog(@"encodes fps :%d",encodes);
        encodes = 0;
        lastTime = timeInterval;
    }
}

static void didCompressFinished(
                                void * CM_NULLABLE outputCallbackRefCon,
                                void * CM_NULLABLE sourceFrameRefCon,
                                OSStatus status,
                                VTEncodeInfoFlags infoFlags,
                                CM_NULLABLE CMSampleBufferRef sampleBuffer ){
    
    
    if(status != 0){
        return;
    }
    
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    if (@available(iOS 11.0, *)) {
        JGVideoEncoder *encoder = (__bridge JGVideoEncoder*)outputCallbackRefCon;
        
        //判断是否为关键帧
        bool keyframe = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
        
        [encoder oneSecondStatisticEncodesFPS];
        //关键帧获取vps,sps，pps数据
        if(keyframe){
            
            CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
            size_t vparameterSetSize, vparameterSetCount;
            const uint8_t *vparameterSet;
            
            OSStatus statusCode = CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(format, 0, &vparameterSet, &vparameterSetSize, &vparameterSetCount, 0 );
            
            if (statusCode == noErr)
            {
                //found vps and check sps
                size_t sparameterSetSize, sparameterSetCount;
                const uint8_t *sparameterSet;
                statusCode = CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(format, 1, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0 );
                if (statusCode == noErr)
                {
                    // Found sps and now check for pps
                    size_t pparameterSetSize, pparameterSetCount;
                    const uint8_t *pparameterSet;
                    OSStatus statusCode = CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(format, 2, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0 );
                    if (statusCode == noErr)
                    {
                        // Found pps
                        NSData *vps = [NSData dataWithBytes:vparameterSet length:vparameterSetSize];
                        NSData *sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                        NSData *pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                        if (encoder)
                        {
//                            [encoder gotSpsPps:sps pps:pps];  // 获取sps & pps数据
                            [encoder gotVpsSpsPps:vps sps:sps pps:pps];  // 获取 vps &sps & pps数据
                        }
                    }
                }
            }
            
        }
        
        //写入数据
        CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        size_t length, totalLength;
        char *dataPointer;
        OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
        if (statusCodeRet == noErr) {
            size_t bufferOffset = 0;
            static const int AVCCHeaderLength = 4; // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
            
            // 循环获取nalu数据
            while (bufferOffset < totalLength - AVCCHeaderLength) {
                uint32_t NALUnitLength = 0;
                // Read the NAL unit length
                memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
                
                // 从大端转系统端
                NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
                
                NSData* data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
                [encoder gotEncodedData:data isKeyFrame:keyframe];
                
                // Move to the next NAL unit in the block buffer
                bufferOffset += AVCCHeaderLength + NALUnitLength;
            }
        }
    }
    
    
}

@end

