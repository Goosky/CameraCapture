//
//  OOCameraCapture.h
//  CameraCapture
//
//  Created by BrureZCQ on 6/12/14.
//  Copyright (c) 2014 OpeningO,Inc ( http://openingo.github.io/ http://zhucongqi.cn/ ). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVFoundation/AVCaptureSession.h"
#import "AVFoundation/AVCaptureOutput.h"
#import "AVFoundation/AVCaptureDevice.h"
#import "AVFoundation/AVCaptureInput.h"
#import "AVFoundation/AVCaptureVideoPreviewLayer.h"
#import "AVFoundation/AVMediaFormat.h"

#define kUpdateCapture  @"UpdateCapture"

@interface OOCameraCapture : NSObject


+ (OOCameraCapture *)capture;
- (AVCaptureVideoPreviewLayer *)getPreviewLayer;
- (void)startCapture;
- (void)stopCapture;
- (NSData *)captureData;

@end
