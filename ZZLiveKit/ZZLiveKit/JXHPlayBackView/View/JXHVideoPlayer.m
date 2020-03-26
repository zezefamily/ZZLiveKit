//
//  JXHVideoPlayer.m
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/3/25.
//  Copyright © 2020 泽泽. All rights reserved.
//

#import "JXHVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
@interface JXHVideoPlayer ()
{
    dispatch_source_t _timer;
    NSMutableArray *_scriptArray;
    id timeObserverToken;
}
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,assign) BOOL isPlaying;
@end
@implementation JXHVideoPlayer
- (instancetype)initWithFrame:(CGRect)frame
{
    if(self == [super initWithFrame:frame]){
        self.backgroundColor = [UIColor blackColor];
        [self loadPlayer];
    }
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)loadPlayer
{
    //0.初始化脚本容器
    _scriptArray = [NSMutableArray array];
}

- (void)startTimer
{
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_timer, ^{
    //        NSLog(@"间隔一秒");
    });
    dispatch_resume(_timer);
}

- (void)jxh_playeVideoWithURL:(NSString *)urlString scriptFileName:(NSString *)scriptFileName currentServerTime:(float)serverTime teacherServerTime:(float)teacherServerTime
{
    if(urlString == nil || [urlString isEqualToString:@""]||[scriptFileName isEqualToString:@""]||scriptFileName == nil || serverTime == 0.0 || teacherServerTime == 0.0){
        NSLog(@"参数有误,启动失败");
        return;
    }
    //1.启动定时器
    if(_timer == nil){
        [self startTimer];
    }
    //2.获取脚本文件
    //3.初始化播放器
    if(self.player == nil){
        AVPlayer *player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString:urlString]];
        if(player == nil){
            NSLog(@"播放器启动失败");
            return;
        }
        self.player = player;
        AVPlayerLayer *playerLayer = [AVPlayerLayer layer];
        playerLayer.frame = self.bounds;
        playerLayer.player = player;
        [self.layer addSublayer:playerLayer];
        //4.开始播放
        [self.player play];
        //5.添加监听
        [self addPlayerObserver];
//        __weak typeof(self) weakSelf = self;
        __weak typeof(AVPlayer *) weakPlayer = self.player;
        CMTime interval = CMTimeMakeWithSeconds(1, NSEC_PER_SEC);
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        timeObserverToken = [self.player addPeriodicTimeObserverForInterval:interval queue:mainQueue usingBlock:^(CMTime time) {
            // The value of the CMTime. value/timescale = seconds.
            // The timescale of the CMTime. value/timescale = seconds.
            //        long seconds0 = time.value/time.timescale;
            //        NSLog(@"\nseconds == %ld",seconds0);
//            CMTime currentTime =  weakPlayer.currentTime;
//            NSLog(@"\nseconds == %lld",currentTime.value/currentTime.timescale);
        }];
        //发起 teacherServerTime
        //收到 获取serverTime
        //serverTime - teacherTime  seekTimeToTime
    }
}

- (void)addPlayerObserver
{
    //        [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //        self.player.status 加载状态
    [self.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //播放完毕的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime:)
                                                            name:AVPlayerItemDidPlayToEndTimeNotification
                                                          object:nil];
    [self.player.currentItem addObserver:self
    forKeyPath:@"playbackLikelyToKeepUp"
       options:NSKeyValueObservingOptionNew
       context:nil];
    
}
- (void)removePlayerObserver
{
    [self.player removeTimeObserver:timeObserverToken];
    [self.player removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if([keyPath isEqualToString:@"status"]){
        AVPlayer *player = (AVPlayer *)object;
        switch (player.status) {
            case AVPlayerStatusUnknown:
            {
                NSLog(@"加载中...");
            }
                break;
            case AVPlayerStatusReadyToPlay:
            {
                NSLog(@"准备播放...");
            }
                break;
            case AVPlayerStatusFailed:
            {
                NSLog(@"载入失败...");
            }
                break;
            default:
                break;
        }
    }
    if([keyPath isEqualToString:@"loadedTimeRanges"]){
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        NSTimeInterval totlaBuffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
        NSLog(@"共缓冲了 %.2f",totlaBuffer);
    }
}
- (void)playerItemDidPlayToEndTime:(NSNotification *)notification
{
    NSLog(@"播放完毕");
}
- (void)jxh_play
{
    if(self.player){
        [self.player play];
    }
}

- (void)jxh_pause
{
    if(self.player){
        [self.player pause];
    }
    
}
- (void)jxh_seekToTime:(CGFloat)time
{
    if (self.player){
        [self.player.currentItem cancelPendingSeeks];
        CMTime cmTime =CMTimeMakeWithSeconds(time, 1);
         if (CMTIME_IS_INVALID(cmTime) || self.player.currentItem.status != AVPlayerStatusReadyToPlay){
             return;
         }
         [self.player seekToTime:cmTime toleranceBefore:CMTimeMake(1,1)  toleranceAfter:CMTimeMake(1,1) completionHandler:^(BOOL finished) {
             
         }];
    }
}
- (void)stopTimer
{
    if(_timer){
        dispatch_cancel(_timer);
        _timer = nil;
    }
}

- (void)dealloc
{
    NSLog(@"-%s-",__func__);
    [self stopTimer];
    [self removePlayerObserver];
    timeObserverToken = nil;
    self.player = nil;
}

/**
 CMTimeGetSeconds([_player currentTime]) / 60 可以获得当前分钟
 CMTimeGetSeconds([_player currentTime]) % 60 可以获得当前秒数
 playerItem.duration.value / _playerItem.duration.timescale / 60
 可以获得视频总分钟数
 playerItem.duration.value / _playerItem.duration.timescale % 60 可以获得视频总时间减分钟的秒数
。
 */

@end
