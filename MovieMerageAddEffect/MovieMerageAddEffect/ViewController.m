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
+ (NSArray*)videoAsset{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *firstVideo = [mainBundle pathForResource:@"xx" ofType:@"mp4"];
    NSString *qiegeVideo    =   [mainBundle pathForResource:@"qiege_pianwei" ofType:@"mp4"];
    NSString *secondVideo = [mainBundle pathForResource:@"cc" ofType:@"mp4"];
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *firstAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:firstVideo] options:optDict];
    AVAsset *secondAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:secondVideo] options:optDict];
    AVAsset *qiegeAsset =   [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:qiegeVideo] options:optDict];
    NSArray *videoAsset =   [NSArray arrayWithObjects:firstAsset, qiegeAsset,secondAsset,nil];
    return videoAsset;
}

- (IBAction)dsadasdsa:(id)sender {
    [self combVideos];
}

#pragma  mark 2个视频的合成
- (void)combVideos{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *firstVideo = [mainBundle pathForResource:@"1" ofType:@"mp4"];
    NSString *secondVideo = [mainBundle pathForResource:@"2" ofType:@"mp4"];
    NSString *endedVideo    =   [mainBundle pathForResource:@"qiege_pianwei" ofType:@"mp4"];
    
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *firstAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:firstVideo] options:optDict];
    AVAsset *secondAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:secondVideo] options:optDict];
    AVAsset *endedAsset   = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:endedVideo] options:optDict];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    //为视频类型的的Track
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //由于没有计算当前CMTime的起始位置，现在插入0的位置,所以合并出来的视频是后添加在前面，可以计算一下时间，插入到指定位置
    //CMTimeRangeMake 指定起去始位置
    CMTimeRange firstTimeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
    CMTimeRange secondTimeRange = CMTimeRangeMake(kCMTimeZero, secondAsset.duration);
    CMTimeRange endedTimeRange   =  CMTimeRangeMake(kCMTimeZero, endedAsset.duration);
        [compositionTrack insertTimeRange:firstTimeRange ofTrack:[firstAsset tracksWithMediaType:AVMediaTypeVideo][0] atTime:kCMTimeZero error:nil];
    [compositionTrack insertTimeRange:secondTimeRange ofTrack:[secondAsset tracksWithMediaType:AVMediaTypeVideo][0] atTime:firstTimeRange.duration error:nil];
//    [compositionTrack insertTimeRange:endedTimeRange ofTrack:[endedAsset tracksWithMediaType:AVMediaTypeVideo][0] atTime:secondTimeRange.duration error:nil];
    
    //只合并视频，导出后声音会消失，所以需要把声音插入到混淆器中
    //添加音频,添加本地其他音乐也可以,与视频一致
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTimeRange totalTimeRange  =   CMTimeRangeMake(kCMTimeZero,CMTimeAdd(CMTimeAdd(secondTimeRange.duration, firstTimeRange.duration), endedTimeRange.duration));
    [audioTrack insertTimeRange:firstTimeRange ofTrack:[firstAsset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:nil];
     [audioTrack insertTimeRange:secondTimeRange ofTrack:[firstAsset tracksWithMediaType:AVMediaTypeAudio][0] atTime:firstAsset.duration error:nil];
    
    AVVideoComposition  *videoComposition   =   [AVVideoComposition videoCompositionWithPropertiesOfAsset:composition];
    
    NSArray *transitionInstructions =    videoComposition.instructions;
    AVVideoCompositionLayerInstruction  *layerInstruction   =   [transitionInstructions firstObject];
    
    
    [self exportVideo:composition withVideoComPosition:nil];
}

- (void)exportVideo:(AVMutableComposition*)composition withVideoComPosition:(AVMutableVideoComposition*)videoComposition{
    AVAssetExportSession *exporterSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    if (videoComposition!=nil) {
        exporterSession.videoComposition    =   videoComposition;
    }
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
    AVAsset     *oringalAsset                      =   [AVAsset assetWithURL:[NSURL fileURLWithPath:originalVideo]];
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
    [self exportVideo:composition withVideoComPosition:nil];
}

#pragma  mark 视频保存到相册
- (void)writeVideoToPhotoLibrary:(NSURL*)url{
    ALAssetsLibrary *libary =   [[ALAssetsLibrary alloc]init];
    [libary writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetUrl,NSError *error){
        if (error) {
            NSLog(@"error=%@",error);
            
        }else{
            NSLog(@"保存视频完成");
        }
    }];
    
}

#pragma mark 视频转场过度效果
- (IBAction)addTransferEffect:(id)sender{
//    AVVideoComposition
//      AVVideoCompositionInstruction
//        AVVideoCompositionLayerInstruction
        //部署视频布局
    
    NSBundle    *bundle =   [NSBundle mainBundle];
    NSString    *originalVideo  =   [bundle pathForResource:@"1" ofType:@"mp4"];
    NSString    *transferVideo  =   [bundle pathForResource:@"qiege_huicen" ofType:@"mp4"];
    NSString    *snowVideo  =   [bundle pathForResource:@"xx" ofType:@"mp4"];
    AVAsset     *oringalAsset                      =   [AVAsset assetWithURL:[NSURL fileURLWithPath:originalVideo]];
    AVAsset     *snowAsset  =   [AVAsset assetWithURL:[NSURL fileURLWithPath:snowVideo]];
    AVAsset     *transferAsset  =   [AVAsset assetWithURL:[NSURL fileURLWithPath:transferVideo]];
    NSString    *musicAudio =   [bundle pathForResource:@"ShaLaLa" ofType:@"mp3"];
    AVAsset     *musicAsset =   [AVAsset assetWithURL:[NSURL fileURLWithPath:musicAudio]];
    
    AVMutableComposition    *composition =   [AVMutableComposition composition];
    
    AVMutableCompositionTrack   *trackA =   [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack   *trackB =   [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack   *trackC =   [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    
    NSArray     *videoTracks    =   @[trackA,trackC,trackB];
    NSArray     *videoAssets    =   [NSArray arrayWithObjects:oringalAsset,transferAsset,snowAsset,nil] ;
    CMTime      cursorTime  =   kCMTimeZero;
    CMTime      transitionDuration  =   CMTimeMake(2, 1);
    
    for (NSUInteger i = 0; i<videoAssets.count; i++) {
//        NSUInteger  trackIndex  =   i%2;
        AVMutableCompositionTrack   *currentTrack   =   videoTracks[i];
        
        AVAsset     *asset =   videoAssets[i];
        
        AVAssetTrack    *assetTrack =   [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        
        CMTimeRange timeRange   =   CMTimeRangeMake(kCMTimeZero, asset.duration);
        [currentTrack insertTimeRange:timeRange ofTrack:assetTrack atTime:asset.duration error:nil];
//        cursorTime  =   CMTimeAdd(cursorTime, timeRange.duration);
//        cursorTime  =   CMTimeSubtract(cursorTime, transitionDuration);
        
        //只合并视频，导出后声音会消失，所以需要把声音插入到混淆器中
        //添加音频,添加本地其他音乐也可以,与视频一致
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        //    [audioTrack insertTimeRange:orignalTimeRange ofTrack:[oringalAsset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:nil];
        [audioTrack insertTimeRange:timeRange ofTrack:[musicAsset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:nil];
    }
    
    [self exportVideo:composition withVideoComPosition:nil];
//    NSArray *tracks =   [compositon tracksWithMediaType:AVMediaTypeVideo];
//    
//    NSMutableArray  *assetArray =   [NSMutableArray arrayWithObjects:oringalAsset,transferAsset,snowAsset, nil];
//    [self testVideoCompostion:compositon withAssetArray:assetArray];
}

#pragma mark 计算通过和过渡的时间范围
- (void)testVideoCompostion:(AVMutableComposition*)composition withAssetArray:(NSMutableArray*)videoAssets{
    
    CMTime  cursorTime  =   kCMTimeZero;
    
    //2 second transition duration
    CMTime transDuration    =   CMTimeMake(2, 1);
    NSMutableArray  *passThroughTimeRanges  =   [NSMutableArray array];
    NSMutableArray  *transitionTimeRanges   =   [NSMutableArray array];
    
    NSUInteger  videoCount  =   [videoAssets count];
    
    for (NSUInteger i=0; i<videoCount; i++) {
        AVAsset *asset  =   videoAssets[i];
        CMTimeRange timeRange   =   CMTimeRangeMake(cursorTime, asset.duration);
        if (i>0 ) {
            timeRange.start =   CMTimeAdd(timeRange.start, transDuration);
            timeRange.duration  =   CMTimeSubtract(timeRange.duration, transDuration);
        }
        if (i+1<videoCount) {
            timeRange.duration  =   CMTimeSubtract(timeRange.duration, transDuration);
        }
        
        [passThroughTimeRanges addObject:[NSValue valueWithCMTimeRange:timeRange]];
        
        cursorTime  =   CMTimeAdd(cursorTime, asset.duration);
        cursorTime  =   CMTimeSubtract(cursorTime, transDuration);
        
        if (i+1<videoCount) {
            timeRange   =   CMTimeRangeMake(cursorTime, transDuration);
            NSValue *timeRangeValue     =   [NSValue valueWithCMTimeRange:timeRange];
            [transitionTimeRanges addObject:timeRangeValue];
        }
    }
    
    [self creatGroupAndLayerCommand:composition withPassThroughTimeRanges:passThroughTimeRanges withTransitionTimeRanges:transitionTimeRanges];
}

#pragma mark 创建组合和层指令
- (void)creatGroupAndLayerCommand:(AVMutableComposition *)composition withPassThroughTimeRanges:(NSMutableArray*)passThroughTimeRanges withTransitionTimeRanges:(NSMutableArray*)transitionTimeRanges{
    NSMutableArray  *compositionInstructions    =   [NSMutableArray array];
    
    NSArray *tracks =   [composition tracksWithMediaType:AVMediaTypeVideo];
    
    for (NSUInteger i=0; i<passThroughTimeRanges.count; i++) {
        NSUInteger  trackIndex  =   i%2;
        AVMutableCompositionTrack   *currentTrack   =   tracks[trackIndex];
        
        AVMutableVideoCompositionInstruction    *instruction    =   [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange   =   [passThroughTimeRanges[i] CMTimeRangeValue];
        
        AVMutableVideoCompositionLayerInstruction   *layerInstruction   =   [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:currentTrack];
        instruction.layerInstructions   =   @[layerInstruction];
        
        [compositionInstructions addObject:instruction];
        
        if (i<transitionTimeRanges.count) {
            AVMutableCompositionTrack   *foregroundTrack =   tracks[trackIndex];
            AVMutableCompositionTrack   *backgroundTrack    =   tracks[1-trackIndex];
            
            AVMutableVideoCompositionInstruction    *instruction    =   [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            
            CMTimeRange timeRange   =   [transitionTimeRanges[i] CMTimeRangeValue];
            instruction.timeRange   =   timeRange;
            
            AVMutableVideoCompositionLayerInstruction   *fromLayerInstruction   =   [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:foregroundTrack];
            AVMutableVideoCompositionLayerInstruction   *toLayerInstruction =   [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:backgroundTrack];
            instruction.layerInstructions   =   @[fromLayerInstruction,toLayerInstruction];
            [compositionInstructions addObject:instruction];
        }
    }
    [self creatAndSetVideoComposition:compositionInstructions withComposition:composition];
}

#pragma mark 创建和配置AVVideoComposition
- (void)creatAndSetVideoComposition:(NSMutableArray*)compositionInstructions withComposition:(AVMutableComposition*)composition {
    AVMutableVideoComposition   *videoComposition   =   [AVMutableVideoComposition videoComposition];
    videoComposition.instructions   =   compositionInstructions;
    videoComposition.renderSize     =   CGSizeMake(640.f, 480.f);
    videoComposition.frameDuration  =   CMTimeMake(1, 30);
    videoComposition.renderScale      = 1.0f;
    [self exportVideo:composition withVideoComPosition:videoComposition];
}


- (IBAction)testOnlyOneVideo{
    
    NSBundle    *bundle =   [NSBundle mainBundle];
    NSString    *videoPath  =   [bundle pathForResource:@"1" ofType:@"mp4"];
    NSString    *videoPathsecond    =   [bundle pathForResource:@"2" ofType:@"mp4"];
    NSString    *musicPath  =   [bundle pathForResource:@"ShaLaLa" ofType:@"mp3"];
    AVAsset     *videoAsset =   [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
    AVAsset     *secondvideoAsset   =   [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPathsecond]];
    AVAsset     *musicAsset =   [AVAsset assetWithURL:[NSURL fileURLWithPath:musicPath]];
    
    AVMutableComposition    *composition    =   [AVMutableComposition composition];

    AVMutableCompositionTrack   *videoTrack =   [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack   *audioTrack =   [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:[videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:kCMTimeZero error:nil];
    [videoTrack insertTimeRange:CMTimeRangeMake(videoAsset.duration, secondvideoAsset.duration) ofTrack:[secondvideoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:videoAsset.duration error:nil];
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeAdd(videoAsset.duration, secondvideoAsset.duration)) ofTrack:[musicAsset tracksWithMediaType:AVMediaTypeAudio].firstObject atTime:kCMTimeZero error:nil];

    AVMutableVideoCompositionInstruction    *videoInstruction   =   [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    videoInstruction.timeRange  =   CMTimeRangeMake(kCMTimeZero,CMTimeAdd(videoAsset.duration, secondvideoAsset.duration));

    AVMutableVideoCompositionLayerInstruction   *fromLayerInstruction  =   [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    AVMutableVideoCompositionLayerInstruction   *backLayerInstruction  =   [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    AVMutableVideoComposition *    mainCompositionInst  =   [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:composition];
    //溶解过渡效果
//    [fromLayerInstruction setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:CMTimeRangeMake(CMTimeMake(2, 1), CMTimeMake(2, 1))];
    //应用擦除过渡效果
//    CGFloat videoWidth  =   mainCompositionInst.renderSize.width;
//    CGFloat videoHeight =   mainCompositionInst.renderSize.height;
//    CGRect  starRect    =   CGRectMake(0.0f, 0.0f, videoWidth, videoHeight);
//    CGRect  endRect     =   CGRectMake(0.0f, videoHeight, videoWidth, 0.0f);
//    [fromLayerInstruction setCropRectangleRampFromStartCropRectangle:starRect toEndCropRectangle:endRect timeRange:CMTimeRangeMake(CMTimeMake(5, 5), CMTimeMake(5, 5))];
//    //应用推入过渡效果
    CGAffineTransform   identityTransform   =   CGAffineTransformIdentity;
    CGFloat videowidth  =   mainCompositionInst.renderSize.width;
    CGAffineTransform   fromDestTransform   =   CGAffineTransformMakeTranslation(-videowidth, 0.0);
    CGAffineTransform   toStartTransform    =   CGAffineTransformMakeTranslation(videowidth, 0.0);
    [fromLayerInstruction setTransformRampFromStartTransform:identityTransform toEndTransform:fromDestTransform timeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)];
    [backLayerInstruction setTransformRampFromStartTransform:toStartTransform toEndTransform:identityTransform timeRange:CMTimeRangeMake(videoAsset.duration,secondvideoAsset.duration)];
    videoInstruction.layerInstructions  =   [NSArray arrayWithObjects:fromLayerInstruction, nil];
//
//    
//    
//    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
//    BOOL isVideoAssetPortrait_  = NO;
//    CGAffineTransform videoTransform = videoTrack.preferredTransform;
//    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
//        videoAssetOrientation_ = UIImageOrientationRight;
//        isVideoAssetPortrait_ = YES;
//    }
//    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
//        videoAssetOrientation_ =  UIImageOrientationLeft;
//        isVideoAssetPortrait_ = YES;
//    }
//    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
//        videoAssetOrientation_ =  UIImageOrientationUp;
//    }
//    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
//        videoAssetOrientation_ = UIImageOrientationDown;
//    }
//    
//    [fromLayerInstruction setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
//    [fromLayerInstruction setOpacity:0.0 atTime:videoAsset.duration];
//    
//    CGSize naturalSize;
//    if(isVideoAssetPortrait_){
//        naturalSize = CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width);
//    } else {
//        naturalSize = videoTrack.naturalSize;
//    }
//
//    
//    float renderWidth, renderHeight;
//    renderWidth = naturalSize.width;
//    renderHeight = naturalSize.height;
//    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
//    mainCompositionInst.instructions = [NSArray arrayWithObject:videoInstruction];
//    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    

//        // 1 - Set up the text layer
//        CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
//        [subtitle1Text setFont:@"Helvetica-Bold"];
//        [subtitle1Text setFontSize:36];
//        [subtitle1Text setFrame:CGRectMake(100, 100, naturalSize.width, 100)];
//        [subtitle1Text setString:@"MuFeng..........."];
//        [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
//        [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
//        
//        // 2 - The usual overlay
//        CALayer *overlayLayer = [CALayer layer];
//        [overlayLayer addSublayer:subtitle1Text];
//        overlayLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
//        [overlayLayer setMasksToBounds:YES];
//        
//        
//        CALayer *parentLayer = [CALayer layer];
//        CALayer *videoLayer = [CALayer layer];
//        parentLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
//        videoLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
//        [parentLayer addSublayer:videoLayer];
//        [parentLayer addSublayer:overlayLayer];
//        
//        mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool
//                                             videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];

    [self exportVideo:composition withVideoComPosition:mainCompositionInst];
}







- (IBAction)InsertVideoToTransform{
    
    NSBundle    *bundle =   [NSBundle mainBundle];
    NSString    *firstVideoPath =   [bundle pathForResource:@"6" ofType:@"mp4"];
    NSString    *secondVideoPath    =   [bundle pathForResource:@"9" ofType:@"mp4"];
    NSString    *insertVideoPath    =   [bundle pathForResource:@"8" ofType:@"mp4"];
    AVAsset *firstVideoAsset    =   [AVAsset assetWithURL:[NSURL fileURLWithPath:firstVideoPath]];
    AVAsset *secondVideoAsset   =   [AVAsset assetWithURL:[NSURL fileURLWithPath:secondVideoPath]];
    AVAsset *insertVideoAsset       =   [AVAsset assetWithURL:[NSURL fileURLWithPath:insertVideoPath]];
    
    AVAsset *audioAsset =   [AVAsset assetWithURL:[NSURL fileURLWithPath:[bundle pathForResource:@"music" ofType:@"mp3"]]];
    
    AVMutableComposition    *composition    =   [AVMutableComposition composition];
    AVMutableCompositionTrack   *videoTrack =   [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack   *audioTrack =   [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstVideoAsset.duration) ofTrack:[firstVideoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:kCMTimeZero error:nil];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, insertVideoAsset.duration) ofTrack:[insertVideoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:firstVideoAsset.duration error:nil];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondVideoAsset.duration) ofTrack:[secondVideoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:CMTimeAdd(firstVideoAsset.duration, insertVideoAsset.duration) error:nil];
    
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,CMTimeAdd(firstVideoAsset.duration, CMTimeAdd(insertVideoAsset.duration, secondVideoAsset.duration))) ofTrack:[audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject atTime:kCMTimeZero error:nil];
    [self exportVideo:composition withVideoComPosition:nil];
}
















 @end
