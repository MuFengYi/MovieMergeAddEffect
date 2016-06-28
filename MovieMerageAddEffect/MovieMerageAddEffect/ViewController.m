//
//  ViewController.m
//  MovieMerge
//
//  Created by Macrotellect on 16/6/24.
//  Copyright © 2016年 Macrotellect. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "WMPlayer.h"
@interface ViewController ()
@property(nonatomic,strong)WMPlayer *wmPlayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _wmPlayer   =   [[WMPlayer alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height/2)];
    [self.view addSubview:_wmPlayer];
    NSString    *videoPath  =   [[NSBundle mainBundle]pathForResource:@"1" ofType:@"mp4"];
//    NSString *outPutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"merage.mp4"];
    [_wmPlayer setURLString:videoPath];
}
- (IBAction)dsadasdsa:(id)sender {
    [self combVideos];
}

#pragma  mark 2个视频的合成
- (void)combVideos{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *firstVideo = [mainBundle pathForResource:@"xx" ofType:@"mp4"];
    NSString *secondVideo = [mainBundle pathForResource:@"cc" ofType:@"mp4"];
    
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *firstAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:firstVideo] options:optDict];
    AVAsset *secondAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:secondVideo] options:optDict];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    //为视频类型的的Track
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //由于没有计算当前CMTime的起始位置，现在插入0的位置,所以合并出来的视频是后添加在前面，可以计算一下时间，插入到指定位置
    //CMTimeRangeMake 指定起去始位置
    CMTimeRange firstTimeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
    CMTimeRange secondTimeRange = CMTimeRangeMake(kCMTimeZero, secondAsset.duration);
    [compositionTrack insertTimeRange:secondTimeRange ofTrack:[secondAsset tracksWithMediaType:AVMediaTypeVideo][0] atTime:kCMTimeZero error:nil];
    [compositionTrack insertTimeRange:firstTimeRange ofTrack:[firstAsset tracksWithMediaType:AVMediaTypeVideo][0] atTime:kCMTimeZero error:nil];
    
    
    //只合并视频，导出后声音会消失，所以需要把声音插入到混淆器中
    //添加音频,添加本地其他音乐也可以,与视频一致
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioTrack insertTimeRange:secondTimeRange ofTrack:[firstAsset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:nil];
    [audioTrack insertTimeRange:firstTimeRange ofTrack:[firstAsset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:nil];
}

- (void)exportVideo:(AVMutableComposition*)composition{
    AVAssetExportSession *exporterSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    exporterSession.outputFileType = AVFileTypeMPEG4;
    //混合后的视频输出路径
    NSString *outPutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"merage.mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:outPutPath error:nil];
    }
    NSURL *outPutUrl = [NSURL fileURLWithPath:outPutPath];
    exporterSession.outputURL = outPutUrl; //如果文件已存在，将造成导出失败
    exporterSession.shouldOptimizeForNetworkUse = YES; //用于互联网传输
    [exporterSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exporterSession.status) {
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"exporter Unknow");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"exporter Canceled");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"exporter Failed");
                NSLog(@"AVAssetExportSession.error======%@",exporterSession.error);
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"exporter Waiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"exporter Exporting");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"exporter Completed");
                dispatch_async(dispatch_get_main_queue(), ^{
                [_wmPlayer setURLString:outPutPath];
                    [_wmPlayer play];
                });
                
//                [_wmPlayer play];
//                [self writeVideoToPhotoLibrary:[NSURL fileURLWithPath:outPutPath]];
                break;
                
        }
    }];
}


#pragma mark  对视频加雪花的视频
- (IBAction)addSnowEffect:(id)sender{
    NSBundle    *bundle =   [NSBundle mainBundle];
    NSString    *originalVideo  =   [bundle pathForResource:@"1" ofType:@"mp4"];
    NSString    *snowVideo  =   [bundle pathForResource:@"qiege_huicen" ofType:@"mp4"];
    AVAsset     *oringalAsset    =   [AVAsset assetWithURL:[NSURL fileURLWithPath:originalVideo]];
    AVAsset     *snowAsset  =   [AVAsset assetWithURL:[NSURL fileURLWithPath:snowVideo]];
    NSString    *musicAudio =   [bundle pathForResource:@"ShaLaLa" ofType:@"mp3"];
    AVAsset     *musicAsset =   [AVAsset assetWithURL:[NSURL fileURLWithPath:musicAudio]];
    
    AVMutableComposition    *composition    =   [[AVMutableComposition alloc]init];
    AVMutableCompositionTrack   *compositionTrack    =   [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTimeRange orignalTimeRange = CMTimeRangeMake(kCMTimeZero, oringalAsset.duration);
//    AVAssetTrack    *oringalTrack   =   [snowAsset tracksWithMediaType:AVMediaTypeVideo][0];
//    AVAssetTrack    *snowTrack  =   [oringalAsset tracksWithMediaType:AVMediaTypeVideo][0];
//    NSValue *timeRangeValue =   [NSValue valueWithCMTimeRange:orignalTimeRange];
//    NSArray     *timeArray  =   [NSArray arrayWithObjects:timeRangeValue, timeRangeValue ,nil];
//    NSArray     *tracksArray    =   [NSArray arrayWithObjects:oringalTrack,snowTrack, nil];
//    [compositionTrack insertTimeRanges:timeArray    ofTracks:tracksArray    atTime:kCMTimeZero error:nil];
//    [compositionTrack insertTimeRange:orignalTimeRange ofTrack:[snowAsset tracksWithMediaType:AVMediaTypeVideo][0] atTime:kCMTimeZero error:nil];
    [compositionTrack insertTimeRange:orignalTimeRange ofTrack:[oringalAsset tracksWithMediaType:AVMediaTypeVideo][0] atTime:kCMTimeZero error:nil];
    
    //只合并视频，导出后声音会消失，所以需要把声音插入到混淆器中
    //添加音频,添加本地其他音乐也可以,与视频一致
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
//    [audioTrack insertTimeRange:orignalTimeRange ofTrack:[oringalAsset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:nil];
    [audioTrack insertTimeRange:orignalTimeRange ofTrack:[musicAsset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:nil];
    [self exportVideo:composition];
}

#pragma  mark 视频保存到相册
-(void)writeVideoToPhotoLibrary:(NSURL*)url{
    ALAssetsLibrary *libary =   [[ALAssetsLibrary alloc]init];
    [libary writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetUrl,NSError *error){
        if (error) {
            NSLog(@"error=%@",error);
            
        }else{
            NSLog(@"保存视频完成");
        }
    }];
    
}

@end
