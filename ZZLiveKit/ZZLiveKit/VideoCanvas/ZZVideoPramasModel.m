//
//  ZZVideoPramasModel.m
//  ZZLiveKit
//
//  Created by 泽泽 on 2020/3/20.
//  Copyright © 2020 泽泽. All rights reserved.
//

#import "ZZVideoPramasModel.h"

@implementation ZZVideoPramasModel

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_vid forKey:@"vid"];
}
- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    if(self == [super init]){
        self.vid = [coder decodeObjectForKey:@"vid"];
    }
    return self;
}

@end
