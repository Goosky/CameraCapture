//
//  OOCameraCapture.m
//  CameraCapture
//
//  Created by BrureZCQ on 6/12/14.
//  Copyright (c) 2014 OpeningO,Inc ( http://openingo.github.io/ http://zhucongqi.cn/ ). All rights reserved.
//

#import "OOCameraCapture.h"

static OOCameraCapture *_theServer;

@interface OOCameraCapture()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
{
    AVCaptureVideoPreviewLayer *_preLayer;
    AVCaptureSession *_captureSession;
    AVCaptureSession *_audioSession;
    NSData *_videoData;
    NSData *_audioData;
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
        [_theServer setupAudioSession];
    }
}

// Create and configure a capture session and start it running
- (void)setupCaptureSession
{
    if (_captureSession != nil) {
        return;
    }
    
    NSError *error = nil;
	
    // Create the session
    _captureSession = [[AVCaptureSession alloc] init];
	
    // Configure the session to produce lower resolution video frames, if your
    // processing algorithm can cope. We'll specify medium quality for the
    // chosen device.
    _captureSession.sessionPreset = AVCaptureSessionPresetMedium;
	
    // Find a suitable AVCaptureDevice
    AVCaptureDevice *device = [self getFrontCamera];
	
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
																		error:&error];
    if (error) {
        // Handling the error appropriately.
        NSLog(@"Error Start capture video=%@", error);
        @throw [NSException exceptionWithName:[NSString stringWithFormat:@"Error Start capture video=%@", error] reason:[NSString stringWithFormat:@"Error Start capture video=%@", error] userInfo:nil];
    }
    
    if ([_captureSession canAddInput:input]) {
        [_captureSession addInput:input];
    }
	
    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [_captureSession addOutput:output];
	
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
    
	_preLayer = [AVCaptureVideoPreviewLayer layerWithSession: _captureSession];
    _preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (void)setupAudioSession
{
    if (_audioSession != nil) {
        return;
    }
    
    NSError *error = nil;
	
    // Create the session
    _audioSession = [[AVCaptureSession alloc] init];
    
    _audioSession.sessionPreset = AVCaptureSessionPresetMedium;
    
    // Setup Audio input
    AVCaptureDevice *audioDevice = [AVCaptureDevice
                                    defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *captureAudioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if(error){
        NSLog(@"Error Start capture Audio=%@", error);
        @throw [NSException exceptionWithName:[NSString stringWithFormat:@"Error Start capture Audio=%@", error] reason:[NSString stringWithFormat:@"Error Start capture Audio=%@", error] userInfo:nil];
    }
    
    if ([_audioSession canAddInput:captureAudioInput]){
        [_audioSession addInput:captureAudioInput];
    }
    
    AVCaptureAudioDataOutput *audioCaptureOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    if ([_audioSession canAddOutput:audioCaptureOutput]){
        [_audioSession addOutput:audioCaptureOutput];
    }
    
    dispatch_queue_t audioQueue= dispatch_queue_create("audioQueue", NULL);
    [audioCaptureOutput setSampleBufferDelegate:self queue:audioQueue];
}

- (void)startCapture
{
    if (_captureSession && _audioSession) {
        [_captureSession startRunning];
        [_audioSession startRunning];
    }
}

- (void)stopCapture
{
    if (_captureSession)
    {
        [_captureSession stopRunning];
        _captureSession = nil;
    }
    if (_audioSession) {
        [_audioSession stopRunning];
        _audioSession = nil;
    }
}

#pragma mark - Gets

- (AVCaptureVideoPreviewLayer *)getPreviewLayer
{
    return _preLayer;
}

- (NSData *)captureData
{
    return _videoData;
}

- (NSData *)audioData
{
    return _audioData;
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

- (NSData *)audioDataFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    AudioBufferList audioBufferList;
    NSMutableData *data= [NSMutableData data];
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
    
    for( int y=0; y< audioBufferList.mNumberBuffers; y++ ){
        
        AudioBuffer audioBuffer = audioBufferList.mBuffers[y];
        Float32 *frame = (Float32*)audioBuffer.mData;
        
        [data appendBytes:frame length:audioBuffer.mDataByteSize];
        
    }
    
    CFRelease(blockBuffer);
//    CFRelease(ref);
//    NSError *error ;
//    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithData:data error:&error];
//    if (error) {
//        NSLog(@"============eoor%@",error);
//    }
//    [player play];
    return data;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate && AVCaptureAudioDataOutputSampleBufferDelegate

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if ([captureOutput isKindOfClass:[AVCaptureAudioDataOutput class]]) {
        _audioData = [self audioDataFromSampleBuffer:sampleBuffer];
    }else{
        _videoData = UIImageJPEGRepresentation([self imageFromSampleBuffer:sampleBuffer], 0.3);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateCapture object:nil];
}

@end
