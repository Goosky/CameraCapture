//
//  OOCameraCapture.h
//  CameraCapture
//
//  Created by BrureZCQ on 6/12/14.
//  Copyright (c) 2014 OpeningO,Inc ( http://openingo.github.io/ http://zhucongqi.cn/ ). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#define kUpdateCapture  @"UpdateCapture"

@interface OOCameraCapture : NSObject


+ (OOCameraCapture *)capture;
- (AVCaptureVideoPreviewLayer *)getPreviewLayer;
- (void)startCapture;
- (void)stopCapture;
- (NSData *)captureData;
- (NSData *)audioData;

@end
