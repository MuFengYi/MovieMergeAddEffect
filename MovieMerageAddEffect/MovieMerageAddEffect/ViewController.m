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
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)dsadasdsa:(id)sender {
    [self combVideos];
}

- (void)combVideos{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *firstVideo = [mainBundle pathForResource:@"cc" ofType:@"mp4"];
    NSString *secondVideo = [mainBundle pathForResource:@"xx" ofType:@"mp4"];
    
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
    

    AVAssetExportSession *exporterSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    exporterSession.outputFileType = AVFileTypeMPEG4;
    //混合后的视频输出路径
    NSString *outPutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"xx.mp4"];
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
                 [self writeVideoToPhotoLibrary:[NSURL fileURLWithPath:outPutPath]];
                break;
                
        }
    }];
}
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
