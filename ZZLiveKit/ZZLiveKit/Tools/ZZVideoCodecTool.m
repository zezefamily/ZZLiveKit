//
//  ZZVideoCodecTool.m
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/3/18.
//  Copyright © 2020 泽泽. All rights reserved.
//
/**
 H264 帧内压缩,帧间压缩,帧内压缩是生成I帧的算法，帧间压缩是生成B帧和P帧的算法
 I:完整编码的帧，关键帧
 P:参考I帧生成的包含差异部分的编码的帧
 B:参考前后帧编码的帧
 */

#import "ZZVideoCodecTool.h"
#import <VideoToolbox/VideoToolbox.h>

@implementation ZZVideoEncoderParam
- (instancetype)init
{
    if(self == [super init]){
        self.profileLevel = ZZVideoEncoderProfileLevelBP;
        self.encodeType = kCMVideoCodecType_H264;
        self.bitRate = 1024 * 1024;
        self.frameRate = 15;
        self.maxKeyFrameInterval = 240;
        self.allowFrameReordering = NO;
    }
    return self;
}
@end


@interface ZZVideoCodecTool ()
{
    
}
@property (nonatomic,assign) VTCompressionSessionRef sessionRef;

@end
@implementation ZZVideoCodecTool
- (instancetype)initWithParam:(ZZVideoEncoderParam *)param
{
    if(self == [super init]){
        self.videoEncodeParam = param;
        [self instanceSession];
    }
    return self;
}


- (void)instanceSession
{
    //1.创建编码器
    OSStatus status = VTCompressionSessionCreate(NULL, 320, 240, kCMVideoCodecType_H264, NULL, NULL, NULL, outputCallback, (__bridge void * _Nullable)(self), &(_sessionRef));
    if(noErr != status){
        NSLog(@"VTCompressionSessionCreate failed:%d",(int)status);
        return;
    }
    if(NULL == self.sessionRef){
        NSLog(@"ZZVideoCodecTool::调用顺序错误");
        return;
    }
    //2.设置编码器属性 准备编码
    // 设置码率 512kbps
    status = VTSessionSetProperty(_sessionRef, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(512 * 1024));
    // 设置画质 ProfileLevel为BP3.1
    /**
        实时直播：
        低清Baseline Level 1.3
        标清Baseline Level 3
        半高清Baseline Level 3.1
        全高清Baseline Level 4.1
    */
    status = VTSessionSetProperty(_sessionRef, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_3_1);
    // 设置实时编码输出（避免延迟）
    status = VTSessionSetProperty(_sessionRef, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    // 配置是否产生B帧 kCFBooleanFalse
    status = VTSessionSetProperty(_sessionRef, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    // 配置最大I帧间隔  15帧 x 240秒 = 3600帧，也就是每隔3600帧编一个I帧
    status = VTSessionSetProperty(_sessionRef, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(15 * 240));
    // 配置I帧持续时间，240秒编一个I帧
    status = VTSessionSetProperty(_sessionRef, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef)@(240));
    //3.编码器准备编码
    status = VTCompressionSessionPrepareToEncodeFrames(_sessionRef);
}

- (BOOL)startVideoEncode
{
    if(NULL == _sessionRef){
        NSLog(@"ZZVideoCodecTool::调用顺序错误");
        return NO;
    }
    //编码器准备编码
    OSStatus status = VTCompressionSessionPrepareToEncodeFrames(_sessionRef);
    if(noErr != status){
        NSLog(@"ZZVideoCodecTool:VTCompressionSessionPrepareToEncodeFrames failed status:%d", (int)status);
        return NO;
    }
    return YES;
}

- (BOOL)stopVideoEncode
{
    if(NULL != _sessionRef){
        return NO;
    }
    //停止编码
    OSStatus status = VTCompressionSessionCompleteFrames(_sessionRef, kCMTimeInvalid);
    if(noErr != status){
        NSLog(@"ZZVideoCodecTool::VTCompressionSessionCompleteFrames failed! status:%d", (int)status);
        return NO;
    }
    return YES;
}

- (BOOL)videoEncodeInputSampleBuffer:(CMSampleBufferRef)sampleBuffer isForceKeyFrame:(BOOL)forceKeyFrame
{
    //CMSampleBufferRef --> CVImageBufferRef
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    NSDictionary *frameProperties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame:@(0)};
    /*
     VTCompressionSessionEncodeFrame(
        CM_NONNULL VTCompressionSessionRef    session,
        CM_NONNULL CVImageBufferRef            imageBuffer,
        CMTime                                presentationTimeStamp,
        CMTime                                duration, // may be kCMTimeInvalid
        CM_NULLABLE CFDictionaryRef            frameProperties,
        void * CM_NULLABLE                    sourceFrameRefcon,
        VTEncodeInfoFlags * CM_NULLABLE        infoFlagsOut )
     */
    VTCompressionSessionEncodeFrame(_sessionRef, imageBuffer, kCMTimeInvalid, kCMTimeInvalid, (__bridge CFDictionaryRef)frameProperties, NULL, NULL);
    return YES;
}

#pragma mark - 编码回调结果???????
void outputCallback(void * CM_NULLABLE outputCallbackRefCon,void * CM_NULLABLE sourceFrameRefCon,OSStatus status,VTEncodeInfoFlags infoFlags,CM_NULLABLE CMSampleBufferRef sampleBuffer ){
    if (noErr != status || nil == sampleBuffer)
    {
        NSLog(@"VEVideoEncoder::encodeOutputCallback Error : %d!", (int)status);
        return;
    }
    if (nil == outputCallbackRefCon)
    {
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer))
    {
        return;
    }
    if (infoFlags & kVTEncodeInfo_FrameDropped)
    {
        NSLog(@"VEVideoEncoder::H264 encode dropped frame.");
        return;
    }
    ZZVideoCodecTool *encoder = (__bridge ZZVideoCodecTool *)outputCallbackRefCon;
    const char header[] = "\x00\x00\x00\x01";
    size_t headerLen = (sizeof header) - 1;
    NSData *headerData = [NSData dataWithBytes:header length:headerLen];
    
    // 判断是否是关键帧
    bool isKeyFrame = !CFDictionaryContainsKey((CFDictionaryRef)CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0), (const void *)kCMSampleAttachmentKey_NotSync);
    
    if (isKeyFrame)
    {
        NSLog(@"VEVideoEncoder::编码了一个关键帧");
        CMFormatDescriptionRef formatDescriptionRef = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        // 关键帧需要加上SPS、PPS信息
        size_t sParameterSetSize, sParameterSetCount;
        const uint8_t *sParameterSet;
        OSStatus spsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDescriptionRef, 0, &sParameterSet, &sParameterSetSize, &sParameterSetCount, 0);
        
        size_t pParameterSetSize, pParameterSetCount;
        const uint8_t *pParameterSet;
        OSStatus ppsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDescriptionRef, 1, &pParameterSet, &pParameterSetSize, &pParameterSetCount, 0);
        
        if (noErr == spsStatus && noErr == ppsStatus)
        {
            NSData *sps = [NSData dataWithBytes:sParameterSet length:sParameterSetSize];
            NSData *pps = [NSData dataWithBytes:pParameterSet length:pParameterSetSize];
            NSMutableData *spsData = [NSMutableData data];
            [spsData appendData:headerData];
            [spsData appendData:sps];
            if ([encoder.delegate respondsToSelector:@selector(videoEncodeOutputDataCallBack:isKeyFrame:)])
            {
                [encoder.delegate videoEncodeOutputDataCallBack:spsData isKeyFrame:isKeyFrame];
            }
            
            NSMutableData *ppsData = [NSMutableData data];
            [ppsData appendData:headerData];
            [ppsData appendData:pps];
            
            if ([encoder.delegate respondsToSelector:@selector(videoEncodeOutputDataCallBack:isKeyFrame:)])
            {
                [encoder.delegate videoEncodeOutputDataCallBack:ppsData isKeyFrame:isKeyFrame];
            }
        }
    }
    
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    status = CMBlockBufferGetDataPointer(blockBuffer, 0, &length, &totalLength, &dataPointer);
    if (noErr != status)
    {
        NSLog(@"VEVideoEncoder::CMBlockBufferGetDataPointer Error : %d!", (int)status);
        return;
    }
    
    size_t bufferOffset = 0;
    static const int avcHeaderLength = 4;
    while (bufferOffset < totalLength - avcHeaderLength)
    {
        // 读取 NAL 单元长度
        uint32_t nalUnitLength = 0;
        memcpy(&nalUnitLength, dataPointer + bufferOffset, avcHeaderLength);
        
        // 大端转小端
        nalUnitLength = CFSwapInt32BigToHost(nalUnitLength);
        
        NSData *frameData = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + avcHeaderLength) length:nalUnitLength];
        
        NSMutableData *outputFrameData = [NSMutableData data];
        [outputFrameData appendData:headerData];
        [outputFrameData appendData:frameData];
        
        bufferOffset += avcHeaderLength + nalUnitLength;
        
        if ([encoder.delegate respondsToSelector:@selector(videoEncodeOutputDataCallBack:isKeyFrame:)])
        {
            [encoder.delegate videoEncodeOutputDataCallBack:outputFrameData isKeyFrame:isKeyFrame];
        }
    }
}


- (BOOL)changeBitRate:(NSInteger)bitRate
{
    return YES;
}

- (void)dealloc
{
    if(NULL != _sessionRef){
        return;
    }
    VTCompressionSessionCompleteFrames(_sessionRef, kCMTimeInvalid);
    //释放编码器
    VTCompressionSessionInvalidate(_sessionRef);
    CFRelease(_sessionRef);
    _sessionRef = NULL;
}
@end
