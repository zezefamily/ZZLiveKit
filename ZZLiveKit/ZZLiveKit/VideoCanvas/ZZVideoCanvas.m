//
//  ZZVideoCanvas.m
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/3/18.
//  Copyright © 2020 泽泽. All rights reserved.
/**
 AVCaptureSession 协调数据的输入,输出
 AVCaptureConnection
 AVCaptureDevice
 AVCaptureInput
 AVCaptureOutput
    AVCaptureMovieFileOutput
    AVCaptureStillImageOutput
    AVCaptureVideoDataOutput
    AVCaptureAudioDataOutput
 AVCaptureVideoPreviewLayer
 Notifications:
    AVCaptureSessionRuntimeErrorNotification
    AVCaptureDeviceWasConnectedNotification/AVCaptureDeviceWasDisconnectedNotification
 */
/**
 
 [UIDevice userInterfaceIdiom] == UIUserInterfaceIdiomPhone
 [UIDevice userInterfaceIdiom] == UIUserInterfaceIdiomPad
 
 #define  IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
 #define  IS_PAD (UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPad)
 
 #ifdef IS_IPHONE
 //#import iPhone的framework
 #else
 //#import iPad的framework
 #endif
 
*/


#import "ZZVideoCanvas.h"
@interface ZZVideoCanvas ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureDevice *_frontCamera;      // 前置摄像头
    AVCaptureDevice *_backCamera;       // 后置摄像头
}
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
    [self loadInputDevices];
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

#pragma mark - 初始化可用的前后置摄像头
- (void)loadInputDevices
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
//        //设置对焦模式
//        if([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
//            CGPoint autofocusPoint = CGPointMake(0.5f,0.5f);
//            [device setFocusPointOfInterest:autofocusPoint];
//            [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
//        }
//        //设置曝光
//        if([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
//            CGPoint ExposurePoint = CGPointMake(0.5f,0.5f);
//            [device setExposurePointOfInterest:ExposurePoint];
//            [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
//        }
        if(device.position == AVCaptureDevicePositionBack){
            _backCamera = device;
            
        }
        if(device.position == AVCaptureDevicePositionFront){
            _frontCamera = device;
        }
    }
}
- (AVCaptureDeviceInput *)getCaptureDeviceWithMode:(NSInteger)mode
{
    NSError *error = nil;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:mode == 0?_frontCamera:_backCamera error:&error];
    if(!error){
        return deviceInput;
    }else{
        NSLog(@"error == %@",error);
        return nil;
    }
}
- (void)loadDeviceInput
{
    self.captureDeviceInput = [self getCaptureDeviceWithMode:0];
    if(self.captureDeviceInput == nil){
        NSLog(@"AVCaptureDevice => AVCaptureDeviceInput失败");
        return;
    }
}

- (void)setFrameRate:(NSInteger)frameRate
{
    NSInteger rate = frameRate;
    AVFrameRateRange *frameRange = [self.captureDeviceInput.device.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0];
    if(rate > frameRange.maxFrameRate || rate < frameRange.minFrameRate){return;}
    [self.captureSession beginConfiguration];
    self.captureDeviceInput.device.activeVideoMaxFrameDuration = CMTimeMake(1, (int)rate);
    self.captureDeviceInput.device.activeVideoMinFrameDuration = CMTimeMake(1, (int)rate);
    [self.captureSession commitConfiguration];
}

- (void)loadDeviceOutput
{
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    //输出配置kCVPixelBufferPixelFormatTypeKey：
    NSDictionary *videoSetting = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey, nil];
    [self.videoDataOutput setVideoSettings:videoSetting];
     NSLog(@"\nself.videoDataOutput.availableVideoCVPixelFormatTypes == %@\navailableVideoCodecTypes == %@",self.videoDataOutput.availableVideoCVPixelFormatTypes,self.videoDataOutput.availableVideoCodecTypes);
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
    if([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]){
        [self.captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    }
    // 获取连接并设置屏幕方向
    self.captureConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    self.captureConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    if(self.captureDeviceInput.device.position == AVCaptureDevicePositionFront && self.captureConnection.supportsVideoMirroring){
        self.captureConnection.videoMirrored = YES;
    }
    [self setFrameRate:15];
    //获取预览layer 设置方向并渲染
    self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    //设置显示比例
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
- (void)switchCameraWithMode:(NSInteger)mode
{
    [self.captureSession beginConfiguration];
    [self.captureSession removeInput:self.captureDeviceInput];
    self.captureDeviceInput = nil;
    self.captureDeviceInput = [self getCaptureDeviceWithMode:mode];
    if([self.captureSession canAddInput:self.captureDeviceInput]){
        [self.captureSession addInput:self.captureDeviceInput];
    }
    //这里需要重新设置一下
    self.captureConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    self.captureConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    if(self.captureDeviceInput.device.position == AVCaptureDevicePositionFront && self.captureConnection.supportsVideoMirroring){
        self.captureConnection.videoMirrored = YES;
    }
    [self.captureSession commitConfiguration];
}
#pragma mark - 设置视频帧率 default:30fps

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
// 每当AVCaptureVideoDataOutput实例输出新的视频帧时触发调用
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if([self.delegate respondsToSelector:@selector(videoCaptureDataCallback:)]){
        [self.delegate videoCaptureDataCallback:sampleBuffer];
    }
}

#pragma mark - setter
- (void)setRenderView:(UIView *)renderView
{
    _renderView = renderView;
    if(self.renderView){
        self.videoPreviewLayer.frame = self.renderView.bounds;
        [self.renderView.layer addSublayer:self.videoPreviewLayer];
    }
}
@end

