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
@interface ZZVideoCodecTool ()
{
    OSStatus _status;
    VTCompressionOutputCallback _outputCallback;
    VTCompressionSessionRef _sessionRef;
}
@end
@implementation ZZVideoCodecTool
- (instancetype)init
{
    if(self == [super init]){
        [self instanceSession];
    }
    return self;
}
- (void)instanceSession
{
    //1.创建编码器
    _status = VTCompressionSessionCreate(NULL, 640, 320, kCMVideoCodecType_H264, NULL, NULL, NULL, _outputCallback, (__bridge void * _Nullable)(self), &(_sessionRef));
    //2.设置编码器属性 准备编码
    // 设置码率 512kbps
    OSStatus status = VTSessionSetProperty(_sessionRef, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(512 * 1024));
    // 设置ProfileLevel为BP3.1
    status = VTSessionSetProperty(_sessionRef, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_3_1);
    // 设置实时编码输出（避免延迟）
    status = VTSessionSetProperty(_sessionRef, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    // 配置是否产生B帧 kCFBooleanFalse
    status = VTSessionSetProperty(_sessionRef, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanTrue);
    // 配置最大I帧间隔  15帧 x 240秒 = 3600帧，也就是每隔3600帧编一个I帧
    status = VTSessionSetProperty(_sessionRef, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(15 * 240));
    // 配置I帧持续时间，240秒编一个I帧
    status = VTSessionSetProperty(_sessionRef, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef)@(240));
    //3.编码器准备编码
    status = VTCompressionSessionPrepareToEncodeFrames(_sessionRef);
}

- (void)startEcodeFrameWithSampleBuffer:(CMSampleBufferRef)sampleBufferRef
{
    //CMSampleBufferRef --> CVImageBufferRef
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBufferRef);
    NSDictionary *frameProperties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame:@(0)};
    VTCompressionSessionEncodeFrame(_sessionRef, imageBuffer, kCMTimeInvalid, kCMTimeInvalid, (__bridge CFDictionaryRef)frameProperties, NULL, NULL);
}

- (void)stopEcodeFrame
{
    //停止编码
    VTCompressionSessionCompleteFrames(_sessionRef, kCMTimeInvalid);
    //释放编码器
    VTCompressionSessionInvalidate(_sessionRef);
    CFRelease(_sessionRef);
    _sessionRef = NULL;
}

@end
