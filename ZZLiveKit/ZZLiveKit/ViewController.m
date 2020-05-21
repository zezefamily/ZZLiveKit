//
//  ViewController.m
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/3/18.
//  Copyright © 2020 泽泽. All rights reserved.
/*
 存储方式：
    1>NSUserDefault  应用属性 配置 相关存储
    2>归档存在 自定义model相关
        NSCoding协议
        NSCoder
        NSKeyedArchiver
        NSKeyedUnArchiver
        本质：对象->字节序列  二进制字节序列->对象
        应用：NSUserDefault 存储一些自定义的model类型数据
        缺点: 灵活性差，修改某个值 需要全部解档 然后归档
    3>SQLite3: 数据库方式存储
        会在磁盘里创建一个 sq表文件 进行增删改查
        比如常用的 FMDB 需要用到一些数据库查询语句
    4>NSFileManager 直接写入磁盘一个plist 或者 txt
    5>CoreData 基本没用过
 78bdadfe43b486f3c3433f96371a68ef263dd91d
 163ea9f61bfb0eae0b085c89ef4c31893f8c0971
 */

#import "ViewController.h"
//#import "ZZVideoPramasModel.h"

#import "Tools/ZZVideoCodecTool.h"
#import "Tools/ZZVideoDecoder.h"
#import "Tools/VPVideoStreamPlayLayer.h"
//#import "GPUImage.h"
#import "VideoCanvas/ZZVideoCanvas.h"



@interface ViewController ()<ZZVideoCanvasDelegate,ZZVideoCodecToolDelegate,ZZVideoDecoderDelegate>
{
    ZZVideoCanvas *_videoCanvas;
    ZZVideoCodecTool *_videoCodecTool;
    ZZVideoDecoder *_videoDecoder;
    VPVideoStreamPlayLayer *_playLayer;
//    JXHPlayBackView *_videoPlayer;
}
@property (weak, nonatomic) IBOutlet UIView *renderView;

@end
static NSInteger deviceMode = 0;
@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    ZZVideoPramasModel *model = [[ZZVideoPramasModel alloc]init];
//    model.vid = @"测试";
//    ZZVideoPramasModel *model1 = [model copy];
//    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
//    [[NSUserDefaults standardUserDefaults]setObject:data forKey:@"TEST"];
//    [[NSUserDefaults standardUserDefaults]synchronize];
    const char header[] = "\x00\x00\x00\x01";
    size_t headerLen = (sizeof header) - 1;
    
    _videoCanvas = [[ZZVideoCanvas alloc]initWithVideoView:self.renderView];
    _videoCanvas.delegate = self;
    ZZVideoEncoderParam *param = [[ZZVideoEncoderParam alloc]init];
    _videoCodecTool = [[ZZVideoCodecTool alloc]initWithParam:param];
    _videoCodecTool.delegate = self;
    
    _videoDecoder = [[ZZVideoDecoder alloc]init];
    _videoDecoder.delegate = self;
    
    _playLayer = [[VPVideoStreamPlayLayer alloc]initWithFrame:CGRectMake(10, 20, 320, 240)];
    _playLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.view.layer addSublayer:_playLayer];
//    _videoPlayer = [[JXHPlayBackView alloc]initWithFrame:CGRectMake(0, 20, 640, 300)];
//    [self.view addSubview:_videoPlayer];
}

- (void)videoCaptureDataCallback:(CMSampleBufferRef)sampleBuffer
{
    
//    CFStringRef sref = kCMSampleBufferAttachmentKey_ForceKeyFrame;
    [_videoCodecTool videoEncodeInputSampleBuffer:sampleBuffer isForceKeyFrame:NO];
//    NSLog(@"sref == %@",sref);
}
/*
 00 00 00 01 06:  SEI信息
 00 00 00 01 67:  0x67&0x1f = 0x07 :SPS
 00 00 00 01 68:  0x68&0x1f = 0x08 :PPS
 00 00 00 01 65:  0x65&0x1f = 0x05: IDR Slice
*/
- (void)videoEncodeOutputDataCallBack:(NSData *)data isKeyFrame:(BOOL)isKeyFrame
{
    NSLog(@"data == %@",data);
    [_videoDecoder decodeNaluData:data];
}
- (void)videoDecodeOutputDataCallback:(CVImageBufferRef)imageBuffer
{
    // CVImageBufferRef/CVPixelBufferRef  YUV格式->RGB格式
    /*
     解释：
        Y:亮度(灰度)
        U&V:色度(色彩及饱和度)
     采样方式:
        YUV4:4:4
        YUV4:2:2
        YUV4:2:0
     */
    NSLog(@"");
    [_playLayer inputPixelBuffer:imageBuffer];
}

//- (void)test03
//{
//    UIImage *inputImage = [UIImage imageNamed:@"test"];
//    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:inputImage];
//    GPUImageSepiaFilter *stillImageFilter = [[GPUImageSepiaFilter alloc] init];
//    [stillImageSource addTarget:stillImageFilter];
//    [stillImageFilter useNextFrameForImageCapture];
//    [stillImageSource processImage];
//    UIImage *currentFilteredVideoFrame = [stillImageFilter imageFromCurrentFramebuffer];
//}
//- (void)test01
//{
//    GPUImageStillCamera *stillCamera = [[GPUImageStillCamera alloc] init];
//    stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
//    GPUImageGammaFilter *filter = [[GPUImageGammaFilter alloc] init];
//    [stillCamera addTarget:filter];
//    GPUImageView *filterView = [[GPUImageView alloc]initWithFrame:CGRectMake(100, 100, 400, 300)];
//    [filter addTarget:filterView];
//    [stillCamera startCameraCapture];
////    [stillCamera capturePhotoAsJPEGProcessedUpToFilter:filter withCompletionHandler:^(NSData *processedJPEG, NSError *error) {
//////        NSLog(@"data == %@",processedJPEG);
////    }];
//}
//- (void)test02
//{
//    GPUImageVideoCamera *videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
//    videoCamera.delegate = self;
//    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
////    GPUImageFilter *customFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"Shader1"];
//    GPUImageSepiaFilter *customFilter = [[GPUImageSepiaFilter alloc] init];
//    GPUImageView *filteredVideoView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
//    // Add the view somewhere so it's visible
//    [self.view addSubview:filteredVideoView];
//    [videoCamera addTarget:customFilter];
//    [customFilter addTarget:filteredVideoView];
//    [videoCamera startCameraCapture];
//}
//
//- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
//{
//    NSLog(@"willOutputSampleBuffer");
//}

- (IBAction)btnClick:(UIButton *)sender {
//    NSData *data = [[NSUserDefaults standardUserDefaults]objectForKey:@"TEST"];
//    ZZVideoPramasModel *model = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//    NSLog(@"model.vid == %@",model.vid);
    [_videoCanvas startCapture];
    [_videoCodecTool startVideoEncode];
//    double teacherServerTime = [[NSDate date]timeIntervalSince1970];
//    double myServerTime = teacherServerTime + 30000;
//    //http://bestmathvod.oss-cn-beijing.aliyuncs.com/test/bigclass/demo.m3u8
////    [_videoPlayer jxh_loadVideoWithURL:@"http://bestmathvod.oss-cn-beijing.aliyuncs.com/test/bigclass/demo.m3u8"];
//    [_videoPlayer jxh_playeVideoWithURL:@"http://bestmathvod.oss-cn-beijing.aliyuncs.com/test/bigclass/demo.m3u8" scriptFileName:@"message.json" currentServerTime:myServerTime teacherServerTime:teacherServerTime relativeStartTime:1584507826746];
//    [self test02];
    
}
- (IBAction)stopCapture:(id)sender {
    [_videoCanvas stopCapture];
    [_videoCodecTool stopVideoEncode];
}
- (IBAction)switchCamera:(id)sender {
    deviceMode = deviceMode == 0 ? 1:0;
    [_videoCanvas switchCameraWithMode:deviceMode];
}

/*
 
 // GPUImageColorMatrixFilter ????
 #import "GPUImageFilter.h"
 #import "GPUImageTwoInputFilter.h"          // 两路输入滤波器
 #import "GPUImagePixellateFilter.h"         // 在图像或视频上应用像素化效果 (0.0 - 1.0, default 0.05)
 #import "GPUImagePixellatePositionFilter.h" // 像素位置
 #import "GPUImageSepiaFilter.h"             // 简单的棕褐色调滤镜 (0.0 - 1.0, with 1.0 as the default)
 #import "GPUImageColorInvertFilter.h"       // 反转图像的颜色
 #import "GPUImageSaturationFilter.h"        // 饱和度 (0.0 - 2.0, with 1.0 as the default)
 #import "GPUImageContrastFilter.h"          // 对比度 (0.0-4.0, with 1.0 as the default)
 #import "GPUImageExposureFilter.h"          // 曝光 (-10~10 default:0)
 #import "GPUImageBrightnessFilter.h"        // 亮度 (brightness:-1~1 default:0)
 #import "GPUImageLevelsFilter.h"            // 色阶调整 The min, max, minOut and maxOut range [0, 1]. mid >= 0
 #import "GPUImageSharpenFilter.h"           // 锐化  (-4.0 - 4.0, with 0.0 as the default)
 #import "GPUImageGammaFilter.h"             // 灰度系数(0.0 - 3.0, with 1.0 as the default)d
 
 */
@end
