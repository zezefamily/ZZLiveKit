//
//  ZZVideoCanvas.h
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/3/18.
//  Copyright © 2020 泽泽. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@protocol ZZVideoCanvasDelegate <NSObject>

- (void)videoCaptureDataCallback:(CMSampleBufferRef)sampleBuffer;

@end

@interface ZZVideoCanvas : NSObject

- (instancetype)initWithVideoView:(UIView *)videoView;

@property (nonatomic,strong) UIView *renderView;

@property (nonatomic,weak) id<ZZVideoCanvasDelegate> delegate;

- (BOOL)startCapture;

- (void)stopCapture;

@end

NS_ASSUME_NONNULL_END
