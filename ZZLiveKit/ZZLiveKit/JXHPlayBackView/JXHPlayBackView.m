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
#import "Toast.h"
#import "JXHPlayBackModel.h"
//#import "ClassRoomAPIHandler.h"
@interface JXHPlayBackView ()<ZZAVPlayerViewDelegate>
{
    dispatch_source_t _timer;
    NSMutableArray *_scriptArray;
    int _playInterval;        //秒数间隔
    BOOL _isBufferEmpty;
    long _startTime;
    BOOL _isFristPlay;
    UILabel *_label0;
    UILabel *_label;
    
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
    _isFristPlay = YES;
    _startTime = 1584507826746;
    self.playerView = [[ZZAVPlayerView alloc]init];
    self.playerView.frame = self.bounds;
    self.playerView.delegate = self;
    [self addSubview:self.playerView];
    _scriptArray = [NSMutableArray array];
    
    _label0 = [[UILabel alloc]initWithFrame:CGRectMake(10, 100, self.frame.size.width-20, 20)];
    _label0.textColor = [UIColor redColor];
    [self addSubview:_label0];
    
    _label = [[UILabel alloc]initWithFrame:CGRectMake(10, 140, self.frame.size.width-20, 20)];
    _label.textAlignment = 0;
    _label.textColor = [UIColor redColor];
    [self addSubview:_label];
}

- (void)jxh_loadVideoWithURL:(NSString *)urlString
{
    if([urlString isEqualToString:@""]|| urlString == nil){
        return;
    }
    [self.playerView setURL:[NSURL URLWithString:urlString]];
}

- (void)jxh_playeVideoWithURL:(NSString *)urlString scriptFileName:(NSString *)scriptFileName currentServerTime:(int)serverTime teacherServerTime:(int)teacherServerTime relativeStartTime:(int)relativeStartTime
{
    if(urlString == nil || [urlString isEqualToString:@""]||[scriptFileName isEqualToString:@""]||scriptFileName == nil || serverTime == 0.0 || teacherServerTime == 0.0){
        NSLog(@"参数有误,启动失败");
        return;
    }
//    NSString *path = [JXHFileManager documentDirPathWithPath:[NSString stringWithFormat:@"scripts/%@.json",scriptFileName]];
//    if(![JXHFileManager fileExistsAtPath:path]){
//        XXLog(@"文件不存在");
//        return;
//    }
    //[[NSBundle mainBundle]pathForResource:@"message" ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://bestmathvod.oss-cn-beijing.aliyuncs.com/test/message.json"]];
//    NSData *jsonData = [[NSData alloc]initWithContentsOfFile:path];
    NSArray *jsonArr = [jsonData mj_JSONObject];
    _scriptArray = [JXHPlayBackModel mj_objectArrayWithKeyValuesArray:jsonArr];
    _playInterval = serverTime - teacherServerTime;
    NSLog(@"_playInterval == %d",_playInterval);
    _label0.text = [NSString stringWithFormat:@"开始于:%ds[%.2d:%.2d],serverTime = %d,teacherServerTime = %d",_playInterval,(int)_playInterval / 60,(int)_playInterval % 60,serverTime,teacherServerTime];
    [self.playerView setURL:[NSURL URLWithString:urlString]];
    
}

- (void)jxh_stopVideo
{
    [self stopTimer];
    [self.playerView stop];
}


#pragma mark - ZZAVPlayerViewDelegate
- (void)videoPlayerIsReadyToPlayVideo:(ZZAVPlayerView *)playerView
{
    NSLog(@"准备或开始播放");
    //    if(_isFristPlay && _playInterval > 3){
    //        NSLog(@"准备或开始播放->seekToTime");
    //        [self.playerView seekToTime:_playInterval completionHandler:^(BOOL finish) {}];
    //    }else{
    //        NSLog(@"准备或开始播放->play");
    //        [self.playerView play];
    //    }
        if(!playerView.isPlaying){
            [self.playerView play];
        }
}
//播放完毕
- (void)videoPlayerDidReachEnd:(ZZAVPlayerView *)playerView
{
    NSLog(@"播放完毕");
    [self stopTimer];
    if([self.delegate respondsToSelector:@selector(playvideoStatusChanged:)]){
        [self.delegate playvideoStatusChanged:1];
    }
}
//当前播放时间
- (void)videoPlayer:(ZZAVPlayerView *)playerView timeDidChange:(CGFloat)time
{
    int currentTime = (int)time;
    JXHPlayBackModel *model = [_scriptArray firstObject];
    NSTimeInterval _offsetTime = (model.keyPutTime - _startTime)/1000;
//    NSLog(@"\ntime == %f,%.2d:%.2d\n_offsetTime = %f",time,currentTime/60,currentTime%60,_offsetTime);
    _label.text = [NSString stringWithFormat:@"[time:%f s]-[%.2d:%.2d] [keyTime: %f s] ",time,currentTime/60,currentTime%60,_offsetTime];
    if(_offsetTime < 0){
        if(_scriptArray.count>0){
           [_scriptArray removeObjectAtIndex:0];
        }
    }
    if(_offsetTime >= 0 && _offsetTime >= currentTime && _offsetTime <= currentTime+1){
        NSLog(@"一条数据\npacket == %@",model.packet);
        [self makeToast:[NSString stringWithFormat:@"%@",model.packet]];
        [self handlerPacketWithModel:model];
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
    NSLog(@"继续播放 %d",playerView.isPlaying);
    if(_isBufferEmpty){
        NSLog(@"继续播放_isBufferEmpty = YES");
        NSLog(@"跳过卡顿时长");
        NSTimeInterval currentInterval = _playInterval;
        [self removeOutTimeModel:currentInterval];
        _isBufferEmpty = NO;
//        __weak typeof(ZZAVPlayerView *) weakPlayer = self.playerView;
        [self.playerView seekToTime:currentInterval completionHandler:^(BOOL finish) {
//            [weakPlayer play];
        }];
    }
    if(_isFristPlay){
        NSLog(@"继续播放_isFrist=YES");
        if(_isFristPlay && _playInterval > 3){
            [self removeOutTimeModel:_playInterval];
            NSLog(@"继续播放->seekToTime");
            [self.playerView seekToTime:_playInterval completionHandler:^(BOOL finish) {}];
        }else{
            NSLog(@"继续播放->play");
            [self.playerView play];
        }
        _isFristPlay = NO;
        if(_timer == nil){
            [self startTimer];
        }
    }
}
//加载失败
- (void)videoPlayer:(ZZAVPlayerView *)playerView didFailWithError:(NSError *)error
{
    NSLog(@"载入失败");
    if([self.delegate respondsToSelector:@selector(playvideoStatusChanged:)]){
        [self.delegate playvideoStatusChanged:-1];
    }
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
        JXHPlayBackModel *model = [tempArr objectAtIndex:i];
        long _offsetTime = (model.keyPutTime - _startTime)/1000;
        if(_offsetTime < currentInterval){
            NSLog(@"offsetTime == %f,currentInterval == %f",_offsetTime,currentInterval);
            [_scriptArray removeObject:model];
        }else{
            break;
        }
    }
}

- (void)handlerPacketWithModel:(JXHPlayBackModel *)model
{
    NSDictionary *options = [model.packet objectForKey:@"options"];
    NSDictionary *message = nil;
    switch (model.packetType) {
        case 302: //房间内消息
        {
             message = [options objectForKey:@"1"];
            
        }
            break;
        case 306: //共享更新消息
        {
            message = options;
        }
            break;
        default:
            break;
    }
    
    if([self.delegate respondsToSelector:@selector(playbackWithMessageType:message:)]){
        [self.delegate playbackWithMessageType:model.packetType message:message];
    }
}

- (void)jxh_palyerDestory
{
    [self stopTimer];
    [self.playerView stop];
}
- (void)dealloc
{
    [self jxh_palyerDestory];
}

@end
