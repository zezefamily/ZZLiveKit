//
//  ZZVideoCanvas.m
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/3/18.
//  Copyright © 2020 泽泽. All rights reserved.
//

#import "ZZVideoCanvas.h"
#import <AVFoundation/AVFoundation.h>
@interface ZZVideoCanvas ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic,strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureConnection *captureConnection;
@property (nonatomic,strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic,strong) AVCaptureVideoDataOutput *videoDataOutput;

@end
@implementation ZZVideoCanvas

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self == [super initWithFrame:frame]){
        [self loadAVComponent];
    }
    return self;
}

- (void)loadAVComponent
{
    [self loadDeviceInput];
    [self loadDeviceOutPut];
    [self loadAVSession];
}

//    NSArray *captureDeviceArray = [cameras filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d", AVCaptureDevicePositionFront]];
//    if (!captureDeviceArray.count)
//    {
//        NSLog(@"获取前置摄像头失败");
//        return;
//    }
- (void)loadDeviceInput
{
//    AVCaptureDevicePositionBack
//    AVCaptureDevicePositionFront
    //获取所有摄像头
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //获取前置摄像头
    AVCaptureDevice *camera;
    for (AVCaptureDevice *device in cameras) {
        if(device.position == AVCaptureDevicePositionFront){
            camera = device;
        }
    }
    if(camera == nil) return;
    NSError *errorMsg = nil;
    self.captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&errorMsg];
    if(errorMsg){
        NSLog(@"AVCaptureDevice => AVCaptureDeviceInput失败");
    }
    
}
- (void)loadDeviceOutPut
{
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    NSDictionary *videoSetting = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey, nil];
    [self.videoDataOutput setVideoSettings:videoSetting];
     
    dispatch_queue_t output_queue = dispatch_queue_create("ACVideoCaptureOutputQueue", DISPATCH_QUEUE_SERIAL);
    [self.videoDataOutput setSampleBufferDelegate:self queue:output_queue];
    //丢弃延迟的帧
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
}
- (void)loadAVSession
{
    
}
@end

/*
 年费会员套餐：
    价格：CNY 1998 (等级78)
    说明：1年内预约所有课程及服务,会员有效期内,可通过官网、公众号、客服热线预约课时，在预约时间内开始上课；
 对您的问题，我们的回答是YES; 同时我们对’年费会员套餐‘做了进一步的解释：
 年费会员套餐：
     价格：CNY 1998 (等级78)
     说明：1年内预约所有课程及服务,会员有效期内,可通过官网、公众号、客服热线预约课时，在预约时间内开始上课；
 感谢您
 */
