//
//  JXHPlayBackView.h
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/3/25.
//  Copyright © 2020 泽泽. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol JXHPlayBackViewDelegate <NSObject>

/// 节点消息回调
/// @param messageType 消息类型
/// @param message 消息体
- (void)playbackWithMessageType:(NSInteger)messageType message:(NSDictionary *)message;

/// 视频状态
/// @param status 状态   -1:载入失败  1:播放完成
- (void)playvideoStatusChanged:(NSInteger)status;

@end

@interface JXHPlayBackView : UIView

@property (nonatomic,weak) id<JXHPlayBackViewDelegate> delegate;

//- (void)jxh_loadVideoWithURL:(NSString *)urlString;

/// 播放视频
/// @param urlString 视频URL
/// @param scriptFileName 脚本文件名称
/// @param serverTime 当前服务器时间（s）
/// @param teacherServerTime 老师发起时服务器时间 (s)
/// @param relativeStartTime 相对开始时间
- (void)jxh_playeVideoWithURL:(NSString *)urlString scriptFileName:(NSString *)scriptFileName currentServerTime:(int)serverTime teacherServerTime:(int)teacherServerTime relativeStartTime:(int)relativeStartTime;

- (void)jxh_stopVideo;

- (void)jxh_palyerDestory;

@end

NS_ASSUME_NONNULL_END
