//
//  OOCameraCapture.m
//  CameraCapture
//
//  Created by BrureZCQ on 6/12/14.
//  Copyright (c) 2014 OpeningO,Inc ( http://openingo.github.io/ http://zhucongqi.cn/ ). All rights reserved.
//

#import "OOCameraCapture.h"

static OOCameraCapture *_theServer;

@interface OOCameraCapture()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureVideoPreviewLayer *_preLayer;
    AVCaptureSession *_session;
    NSData *_imageData;
}
@end

@implementation OOCameraCapture

+ (OOCameraCapture *)capture
{
    return _theServer;
}

+ (void)initialize
{
    if (self == [OOCameraCapture class])
    {
        _theServer = [[OOCameraCapture alloc] init];
        [_theServer setupCaptureSession];
    }
}

// Create and configure a capture session and start it running
- (void)setupCaptureSession
{
    if (_session != nil) {
        return;
    }
    
    NSError *error = nil;
	
    // Create the session
    _session = [[AVCaptureSession alloc] init];
	
    // Configure the session to produce lower resolution video frames, if your
    // processing algorithm can cope. We'll specify medium quality for the
    // chosen device.
    _session.sessionPreset = AVCaptureSessionPresetMedium;
	
    // Find a suitable AVCaptureDevice
    AVCaptureDevice *device = [self getFrontCamera];
	
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
																		error:&error];
    if (!input) {
        // Handling the error appropriately.
    }
    [_session addInput:input];
	
    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [_session addOutput:output];
	
    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
	
    // Specify the pixel format
   	output.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                            [NSNumber numberWithInt: 320], (id)kCVPixelBufferWidthKey,
                            [NSNumber numberWithInt: 240], (id)kCVPixelBufferHeightKey,
                            nil];
//    output.minFrameDuration = CMTimeMake(1, 15);
    
	_preLayer = [AVCaptureVideoPreviewLayer layerWithSession: _session];
    _preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (void)startCapture
{
    [_session startRunning];
}

- (void)stopCapture
{
    if (_session)
    {
        [_session stopRunning];
        _session = nil;
    }
}

#pragma mark - Gets

- (AVCaptureVideoPreviewLayer *)getPreviewLayer
{
    return _preLayer;
}

- (NSData *)captureData
{
    return _imageData;
}

- (AVCaptureDevice *)getFrontCamera
{
    //获取前置摄像头设备
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in cameras)
    {
        if (device.position == AVCaptureDevicePositionFront)
            return device;
    }
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
}

#pragma mark - Common

// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
	
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
	
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
	
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
												 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
	
    // Create an image object from the Quartz image
    //UIImage *image = [UIImage imageWithCGImage:quartzImage];
	UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationRight];
	
    // Release the Quartz image
    CGImageRelease(quartzImage);
	
    return (image);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    _imageData = UIImageJPEGRepresentation([self imageFromSampleBuffer:sampleBuffer], 0.3);
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateCapture object:nil];
}

@end
