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
#import "ZZVideoPramasModel.h"
#import "ZZVideoCanvas.h"

#import "GPUImage.h"
@interface ViewController ()
{
    ZZVideoCanvas *_videoCanvas;
}
@end

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
    _videoCanvas  = [[ZZVideoCanvas alloc]initWithFrame:CGRectMake(100, 100, 400, 300)];
    _videoCanvas.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_videoCanvas];
}

- (IBAction)btnClick:(UIButton *)sender {
//    NSData *data = [[NSUserDefaults standardUserDefaults]objectForKey:@"TEST"];
//    ZZVideoPramasModel *model = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//    NSLog(@"model.vid == %@",model.vid);
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
 #import "GPUImageGammaFilter.h"             // 灰度系数(0.0 - 3.0, with 1.0 as the default)
 
 */
@end
