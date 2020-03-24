//
//  ZZVideoCodecTool.h
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/3/18.
//  Copyright © 2020 泽泽. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

typedef NS_ENUM(NSUInteger,ZZVideoEncoderProfileLevel) {
    /*基本画质。支持I/P 帧，只支持无交错（Progressive）和CAVLC；主要应用：可视电话，会议电视，和无线通讯等实时视频通讯领域*/
    ZZVideoEncoderProfileLevelBP,
    /*进阶画质。支持I/P/B/SP/SI 帧，只支持无交错（Progressive）和CAVLC*/
    ZZVideoEncoderProfileLevelEP,
    /*主流画质。提供I/P/B 帧，支持无交错（Progressive）和交错（Interlaced），也支持CAVLC 和CABAC 的支持；主要应用：数字广播电视和数字视频存储*/
    ZZVideoEncoderProfileLevelMP,
    /*高级画质。在main Profile 的基础上增加了8×8内部预测、自定义量化、 无损视频编码和更多的YUV 格式；应用于广电和存储领域*/
    ZZVideoEncoderProfileLevelHP
};


NS_ASSUME_NONNULL_BEGIN
@interface ZZVideoEncoderParam : NSObject
//设置编码的画质，默认：BP
@property (nonatomic,assign) ZZVideoEncoderProfileLevel profileLevel;
//编码内容的宽度
@property (nonatomic,assign) NSInteger encodeWidth;
//编码内容的高度
@property (nonatomic,assign) NSInteger encodeHeight;
//编码类型
@property (nonatomic,assign) CMVideoCodecType encodeType;
//码率 kbps
@property (nonatomic,assign) NSInteger bitRate;
//帧率 fps 默认15bps
@property (nonatomic,assign) NSInteger frameRate;
//最大I帧间隔 s 默认240s一个帧
@property (nonatomic,assign) NSInteger maxKeyFrameInterval;
//是否允许产生B帧 默认NO
@property (nonatomic,assign) BOOL allowFrameReordering;
@end


@protocol ZZVideoCodecToolDelegate <NSObject>

/// 编码输出数据
/// @param data 数据的二进制数据
/// @param isKeyFrame 是否为关键帧
- (void)videoEncodeOutputDataCallBack:(NSData *)data isKeyFrame:(BOOL)isKeyFrame;

@end

@interface ZZVideoCodecTool : NSObject

@property (nonatomic,weak) id<ZZVideoCodecToolDelegate> delegate;

@property (nonatomic,strong) ZZVideoEncoderParam *videoEncodeParam;

- (instancetype)initWithParam:(ZZVideoEncoderParam *)param;

- (BOOL)startVideoEncode;

- (BOOL)stopVideoEncode;

- (BOOL)videoEncodeInputSampleBuffer:(CMSampleBufferRef)sampleBuffer isForceKeyFrame:(BOOL)forceKeyFrame;

- (BOOL)changeBitRate:(NSInteger)bitRate;

@end


NS_ASSUME_NONNULL_END
