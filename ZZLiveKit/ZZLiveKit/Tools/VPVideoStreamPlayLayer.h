//
//  VPVideoStreamPlayLayer.h
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/5/21.
//  Copyright © 2020 泽泽. All rights reserved.
//  摘自网络   关于OpenGLES GLSL语言 为目前的认知盲区

#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>
NS_ASSUME_NONNULL_BEGIN

@interface VPVideoStreamPlayLayer : CAEAGLLayer

/** 根据frame初始化播放器 */
- (id)initWithFrame:(CGRect)frame;

- (void)inputPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
