//
//  JXHPlayBackView.m
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/3/25.
//  Copyright © 2020 泽泽. All rights reserved.
//

#import "JXHPlayBackView.h"
#import "ZZAVPlayerView.h"
#import "MJExtension.h"
#import "JXHPlayBackModel.h"
#import "Toast.h"
@interface JXHPlayBackView ()<ZZAVPlayerViewDelegate>
{
    dispatch_source_t _timer;
    NSMutableArray *_scriptArray;
    float _playInterval;        //秒数间隔
    BOOL _isBufferEmpty;
    NSTimeInterval _startTime;
}
@property (nonatomic,strong) ZZAVPlayerView *playerView;
@end
@implementation JXHPlayBackView
- (instancetype)initWithFrame:(CGRect)frame
{
    if(self == [super initWithFrame:frame]){
        [self loadPlayer];
    }
    return self;
}
- (void)loadPlayer
{
    _isBufferEmpty = NO;
    _startTime = 1584507826746;
    self.playerView = [[ZZAVPlayerView alloc]init];
    self.playerView.frame = self.bounds;
    self.playerView.delegate = self;
    [self addSubview:self.playerView];
    _scriptArray = [NSMutableArray array];
}
- (void)jxh_playeVideoWithURL:(NSString *)urlString scriptFileName:(NSString *)scriptFileName currentServerTime:(float)serverTime teacherServerTime:(float)teacherServerTime
{
    if(urlString == nil || [urlString isEqualToString:@""]||[scriptFileName isEqualToString:@""]||scriptFileName == nil || serverTime == 0.0 || teacherServerTime == 0.0){
        NSLog(@"参数有误,启动失败");
        return;
    }
    NSString *path = [[NSBundle mainBundle]pathForResource:@"message" ofType:@"json"];
    NSData *jsonData = [[NSData alloc]initWithContentsOfFile:path];
    NSArray *jsonArr = [jsonData mj_JSONObject];
    _scriptArray = [JXHPlayBackModel mj_objectArrayWithKeyValuesArray:jsonArr];
    _playInterval = 0;
    //(serverTime - teacherServerTime)/1000.0;
    NSString *path1 = [[NSBundle mainBundle]pathForResource:@"video" ofType:@"mp4"];
    [self.playerView setURL:[NSURL fileURLWithPath:path1]];
//    [self.playerView setURL:[NSURL URLWithString:urlString]];
    __weak typeof(ZZAVPlayerView *) weakPlayer = self.playerView;
    [self.playerView seekToTime:_playInterval completionHandler:^(BOOL finish) {
        [weakPlayer play];
    }];
}

#pragma mark - ZZAVPlayerViewDelegate
- (void)videoPlayerIsReadyToPlayVideo:(ZZAVPlayerView *)playerView
{
    NSLog(@"准备或开始播放");
}
//播放完毕
- (void)videoPlayerDidReachEnd:(ZZAVPlayerView *)playerView
{
    NSLog(@"播放完毕");
    [self stopTimer];
}
//当前播放时间
- (void)videoPlayer:(ZZAVPlayerView *)playerView timeDidChange:(CGFloat)time
{
    int currentTime = (int)time;
    JXHPlayBackModel *model = [_scriptArray firstObject];
    NSTimeInterval _offsetTime = (model.keyPutTime - _startTime)/1000;
    NSLog(@"\ntime == %f,%.2d:%.2d\n_offsetTime = %f",time,currentTime/60,currentTime%60,_offsetTime);
    if(_offsetTime < 0){
        if(_scriptArray.count>0){
           [_scriptArray removeObjectAtIndex:0];
        }
    }
    if(_offsetTime >= 0 && _offsetTime >= currentTime && _offsetTime <= currentTime+1){
        NSLog(@"一条数据\npacket == %@",model.packet);
        [self makeToast:[NSString stringWithFormat:@"%@",model.packet]];
        if(_scriptArray.count>0){
            [_scriptArray removeObjectAtIndex:0];
        }
    }
}
//duration 当前缓冲的长度
- (void)videoPlayer:(ZZAVPlayerView *)playerView loadedTimeRangeDidChange:(CGFloat )duration
{
//    NSLog(@"当前缓冲的长度duration = %f",duration);
}
//进行跳转后没数据 即播放卡顿
- (void)videoPlayerPlaybackBufferEmpty:(ZZAVPlayerView *)playerView
{
    NSLog(@"卡住了");
    _isBufferEmpty = YES;
}
// 进行跳转后有数据 能够继续播放
- (void)videoPlayerPlaybackLikelyToKeepUp:(ZZAVPlayerView *)playerView
{
    NSLog(@"继续播放");
    if(_isBufferEmpty){
        NSLog(@"跳过卡顿时长");
        NSTimeInterval currentInterval = _playInterval;
        [self removeOutTimeModel:currentInterval];
        _isBufferEmpty = NO;
        __weak typeof(ZZAVPlayerView *) weakPlayer = self.playerView;
        [self.playerView seekToTime:currentInterval completionHandler:^(BOOL finish) {
            [weakPlayer play];
        }];
    }
    if(_timer == nil){
        [self startTimer];
    }
}
//加载失败
- (void)videoPlayer:(ZZAVPlayerView *)playerView didFailWithError:(NSError *)error
{
    NSLog(@"载入失败");
}

- (void)startTimer
{
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_timer, ^{
            self->_playInterval+=1;
//            NSLog(@"_playInterval:%.f",self->_playInterval);
            
    });
    
    dispatch_resume(_timer);
}
- (void)stopTimer
{
    if(_timer){
        dispatch_cancel(_timer);
        _timer = nil;
    }
}

//移除掉卡过的时间节点数据
- (void)removeOutTimeModel:(NSTimeInterval)currentInterval
{
    //offsetTime < currentInterval 都移除掉
    NSMutableArray *tempArr = [_scriptArray mutableCopy];
    for(int i = 0;i<tempArr.count;i++){
        JXHPlayBackModel *model = _scriptArray[i];
        NSTimeInterval _offsetTime = (model.keyPutTime - _startTime)/1000;
        if(_offsetTime < currentInterval){
            [_scriptArray removeObject:model];
        }else{
            break;
        }
    }
}


@end
