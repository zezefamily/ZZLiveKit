//
//  ZZVideoCanvas.m
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/3/18.
//  Copyright © 2020 泽泽. All rights reserved.
//

#import "ZZVideoCanvas.h"

@interface ZZVideoCanvas ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic,strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureConnection *captureConnection;
@property (nonatomic,strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic,strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic,assign) BOOL isCapturing;
@end
@implementation ZZVideoCanvas
- (instancetype)initWithVideoView:(UIView *)renderView
{
    if(self == [super init]){
        _renderView = renderView;
        [self loadAVComponent];
    }
    return self;
}
- (instancetype)init
{
    if(self == [super init]){
        [self loadAVComponent];
    }
    return self;
}

- (void)loadAVComponent
{
    [self loadDeviceInput];
    [self loadDeviceOutput];
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
- (void)loadDeviceOutput
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
    self.captureSession = [[AVCaptureSession alloc]init];
    //不使用应用实例 避免被异常挂起
    self.captureSession.usesApplicationAudioSession = NO;
    //添加输入设备到会话
    if([self.captureSession canAddInput:self.captureDeviceInput]){
        [self.captureSession addInput:self.captureDeviceInput];
    }
    //添加输出设备到会话
    if([self.captureSession canAddOutput:self.videoDataOutput]){
        [self.captureSession addOutput:self.videoDataOutput];
    }
    //设置分辨率
    if([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]){
        [self.captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    // 获取连接并设置屏幕方向
    self.captureConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    self.captureConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    if(self.captureDeviceInput.device.position == AVCaptureDevicePositionFront && self.captureConnection.supportsVideoMirroring){
        self.captureConnection.videoMirrored = YES;
    }
    //获取预览layer 设置方向并渲染
    self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    if(self.renderView){
        self.videoPreviewLayer.frame = self.renderView.bounds;
        [self.renderView.layer addSublayer:self.videoPreviewLayer];
    }
}

- (BOOL)startCapture
{
    if(self.isCapturing){
        return NO;
    }
    // 摄像头权限判断
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (videoAuthStatus != AVAuthorizationStatusAuthorized)
    {
        return NO;
    }
    [self.captureSession startRunning];
    self.isCapturing = YES;
    return YES;
}

- (void)stopCapture
{
    if(self.isCapturing){
        [self.captureSession stopRunning];
        self.isCapturing = NO;
    }
}

#pragma mark - 切换摄像头

#pragma mark - 设置视频帧率 default:30fps

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
// 每当AVCaptureVideoDataOutput实例输出新的视频帧时触发调用
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if([self.delegate respondsToSelector:@selector(videoCaptureDataCallback:)]){
        [self.delegate videoCaptureDataCallback:sampleBuffer];
    }
}

#pragma mark - setter  getter
- (void)setRenderView:(UIView *)renderView
{
    _renderView = renderView;
    if(self.renderView){
        self.videoPreviewLayer.frame = self.renderView.bounds;
        [self.renderView.layer addSublayer:self.videoPreviewLayer];
    }
}
@end

