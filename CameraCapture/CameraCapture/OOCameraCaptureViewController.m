//
//  OOCameraCaptureViewController.m
//  CameraCapture
//
//  Created by BrureZCQ on 6/12/14.
//  Copyright (c) 2014 OpeningO,Inc ( http://openingo.github.io/ http://zhucongqi.cn/ ). All rights reserved.
//

#import "OOCameraCaptureViewController.h"

#import "OOCameraCapture.h"

@interface OOCameraCaptureViewController ()
{
    UIImageView *_captureView;
}
@end

@implementation OOCameraCaptureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[OOCameraCapture capture] startCapture];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(video) name:kUpdateCapture object:nil];
    
    AVCaptureVideoPreviewLayer* preview = [[OOCameraCapture capture] getPreviewLayer];
    [preview removeFromSuperlayer];
    preview.frame = self.view.bounds;
    [[preview connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [self.view.layer addSublayer:preview];
    _captureView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, self.view.bounds.size.width*0.4, self.view.bounds.size.height*0.3)];
    [self.view addSubview:_captureView];
//    _captureView.transform = CGAffineTransformMakeRotation(M_PI*3.5);
//    CGAffineTransform transform = CGAffineTransformMakeTranslation(self.view.bounds.size.height*0.3, self.view.bounds.size.width*0.4);
//    transform = CGAffineTransformRotate(transform, M_PI / 2.0 );
//    _captureView.transform = transform;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[OOCameraCapture capture] stopCapture];
}

- (void)video
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSData *data = [[OOCameraCapture capture] captureData];
        _captureView.image = [UIImage imageWithData:data];
    });
}

@end
