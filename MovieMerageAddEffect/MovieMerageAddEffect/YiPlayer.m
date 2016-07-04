//
//  YiPlayer.m
//  MovieMerageAddEffect
//
//  Created by macro macro on 16/6/28.
//  Copyright © 2016年 macro macro. All rights reserved.
//

#import "YiPlayer.h"
@interface YiPlayer()<UIGestureRecognizerDelegate>
@property(nonatomic,strong)UIButton    *playButton;
@property(nonatomic,strong)AVPlayer   *player;
@property(nonatomic,strong)AVPlayerItem     *playerItem;

@end 
@implementation YiPlayer

- (instancetype)initWithFrame:(CGRect)frame{
    self    =   [super initWithFrame:frame];
    if (self) {
        [self initYiPlayer];
    }
    return self;
}

- (void)initYiPlayer{
    _player =   [[AVPlayer alloc]initWithURL:[NSURL fileURLWithPath:@""]];
}
@end
