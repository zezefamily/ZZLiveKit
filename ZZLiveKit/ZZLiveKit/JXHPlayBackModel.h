//
//  JXHPlayBackModel.h
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/3/26.
//  Copyright © 2020 泽泽. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JXHPlayBackModel : NSObject
@property (nonatomic,assign) NSInteger packetType;
@property (nonatomic,assign) NSTimeInterval keyPutTime;
@property (nonatomic,strong) NSDictionary *packet;
@end

NS_ASSUME_NONNULL_END
/**
 "packetType": 306,
 "keyPutTime": 1584507826746,
 "packet": {
   "options": { "1": "video-record", "2": "", "3": "1", "4": "start" }
 }
 */
