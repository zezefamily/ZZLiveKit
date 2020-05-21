//
//  ZZVideoDecoder.h
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/5/21.
//  Copyright © 2020 泽泽. All rights reserved.
//  H.264 Decoder

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
NS_ASSUME_NONNULL_BEGIN

@protocol ZZVideoDecoderDelegate <NSObject>

/** H264解码数据回调 */
- (void)videoDecodeOutputDataCallback:(CVImageBufferRef)imageBuffer;

@end

@interface ZZVideoDecoder : NSObject

/** 代理 */
@property (weak, nonatomic) id<ZZVideoDecoderDelegate> delegate;

/** 解码NALU数据 */
-(void)decodeNaluData:(NSData *)naluData;

@end

NS_ASSUME_NONNULL_END
