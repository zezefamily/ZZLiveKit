//
//  JXHPlayBackView.h
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/3/25.
//  Copyright © 2020 泽泽. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface JXHPlayBackView : UIView

- (void)jxh_playeVideoWithURL:(NSString *)urlString scriptFileName:(NSString *)scriptFileName currentServerTime:(float)serverTime teacherServerTime:(float)teacherServerTime;

@end

NS_ASSUME_NONNULL_END
