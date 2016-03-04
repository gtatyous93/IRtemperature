//
//  CameraViewController.m
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/19/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoController.h"
@import Foundation;


aFacialPoints atrianglePoints;


@implementation VideoController


@synthesize IBdepth = _IBdepth;


@synthesize captureSession = _captureSession;
@synthesize previewLayer = _previewLayer;
@synthesize cameraPreviewView = _cameraPreviewView;
@synthesize widths = _widths;

@synthesize dist_LE_RE = _dist_LE_RE;
@synthesize dist_LE_M = _dist_LE_M;
@synthesize dist_RE_M = _dist_RE_M;
@synthesize dist_face = _dist_face;
@synthesize face_bool = _face_bool;



//This is the callback for the video buffer queue
//Compliant with protocol set in the SetupCaptureSession function when the queue is configured


//// Module specific methods

- (UIImage*)rotateUIImage:(UIImage*)sourceImage clockwise:(BOOL)clockwise
{
    CGSize size = sourceImage.size;
    UIGraphicsBeginImageContext(CGSizeMake(size.height, size.width));
    [[UIImage imageWithCGImage:[sourceImage CGImage] scale:1.0 orientation:clockwise ? UIImageOrientationRight : UIImageOrientationLeft] drawInRect:CGRectMake(0,0,size.height ,size.width)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

// Create a UIImage from sample buffer data
- (CIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    //NSLog(@"imageFromSampleBuffer: called");
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
    CIImage *image = [CIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

-(BOOL) getFeatureWidth:(CIImage *)frame_sample
{
    //Perform image analysis on a still image. This is used in conjunction with the video frame buffer handler (captureOutput)
    //CIImage* image = [CIImage imageWithCGImage:facePicture.image.CGImage]; //extract frames from video?
    
    CIImage * image = frame_sample;// = [frame_sample CIImage];
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy]];
    NSArray* features = [detector featuresInImage:image];
    atrianglePoints.valid = false;
    if([features count] == 0) return false;
    
    //Clear array (for synchronization purposes.. see main loop logic)
    for (NSUInteger i = 0; i < [_widths count]; ++i) {
        NSNumber * zero = [_widths objectAtIndex:i];
        zero = [NSNumber numberWithFloat: 0.0];
        [_widths replaceObjectAtIndex:i withObject:zero];
    }
    
    // FeatureWidth_t current_feature;
    for(CIFaceFeature* faceFeature in features)
    {
        // get the width of feature pairs on the face
        
        if(faceFeature.hasLeftEyePosition && faceFeature.hasRightEyePosition)
        {
            [_widths replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.rightEyePosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.rightEyePosition.y),2))]];
        }
        if(faceFeature.hasRightEyePosition && faceFeature.hasMouthPosition)
        {
            [_widths replaceObjectAtIndex:1 withObject:[NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.rightEyePosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.rightEyePosition.y),2)) ]];
        }
        if(faceFeature.hasLeftEyePosition && faceFeature.hasMouthPosition)
        {
            [_widths replaceObjectAtIndex:2 withObject:[NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.mouthPosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.mouthPosition.y),2)) ]];
        }
        [_widths replaceObjectAtIndex:3 withObject:[NSNumber numberWithFloat:faceFeature.bounds.size.width]];
        
        //Calculate area
        if(faceFeature.hasLeftEyePosition && faceFeature.hasMouthPosition && faceFeature.hasRightEyePosition)
        {
            atrianglePoints.valid = true;
            atrianglePoints.LE_x = faceFeature.leftEyePosition.x;
            atrianglePoints.LE_y = faceFeature.leftEyePosition.y;
            atrianglePoints.RE_x = faceFeature.rightEyePosition.x;
            atrianglePoints.RE_y = faceFeature.rightEyePosition.y;
            atrianglePoints.Mouth_x = faceFeature.mouthPosition.x;
            atrianglePoints.Mouth_y = faceFeature.mouthPosition.y;
            
            float a,b,c,d;
            a = faceFeature.rightEyePosition.x - faceFeature.mouthPosition.x;
            b = faceFeature.rightEyePosition.y - faceFeature.mouthPosition.y;
            c = faceFeature.leftEyePosition.x - faceFeature.mouthPosition.x;
            d = faceFeature.leftEyePosition.y - faceFeature.mouthPosition.x;
            _widths[3] = [NSNumber numberWithFloat:fabsf((a*d) - (b*c))/2];
        }
    }
    return true;
    
    
    
}

-(void) setupCaptureSession:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)delegate
{
    //Enable back-facing camera and set up a capture session, generate a stream out output frames and pass them to a callback serial queue
    // Grab the back-facing camera
    AVCaptureDevice *backFacingCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == AVCaptureDevicePositionFront) backFacingCamera = device;
    }  
    // Create the capture session
    _captureSession = [[AVCaptureSession alloc] init];
    
    // Add the video input
    NSError *error = nil;
    AVCaptureDeviceInput* videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:backFacingCamera error:&error];
    
    if ([_captureSession canAddInput:videoInput]) [_captureSession addInput:videoInput];
    
    // Add the video frame output
    AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    
    // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured \
    A serial dispatch queue guarantees that video frames will be delivered in order
    
    //[videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    dispatch_queue_t videoOutputQueue = dispatch_queue_create("VideoOutputQueue", DISPATCH_QUEUE_SERIAL);
    [videoOutput setSampleBufferDelegate:delegate queue:videoOutputQueue];
    
    videoOutput.videoSettings =
    [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    //Set up camera display on view
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_previewLayer setFrame:CGRectMake(0, 0, _cameraPreviewView.frame.size.width, _cameraPreviewView.frame.size.height)];
    
    //-- Add the layer to the view that should display the camera input
    [self.cameraPreviewView.layer addSublayer:_previewLayer];
    
    
    self.drawLayer = [CAShapeLayer layer];
    CGRect parentBox = [_previewLayer frame];
    [self.drawLayer setFrame:parentBox];
    [self.drawLayer setDelegate:self];
    [self.drawLayer setNeedsDisplay];
    [self.cameraPreviewView.layer addSublayer:self.drawLayer];
    
    //Set minFrameDuration to cap framerate
    if ( [_captureSession canAddOutput:videoOutput] ) [_captureSession addOutput:videoOutput];
    else NSLog(@"Couldn't add video output");
    
    // Start capturing
    [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    if (![_captureSession isRunning]) [_captureSession startRunning];
}

- (void) ConfigCamera
{
    //Duplicate of code in the AppDelegate
    
    //-- Setup Capture Session.
    _captureSession = [[AVCaptureSession alloc] init];
    
    //-- Creata a video device and input from that Device.  Add the input to the capture session.
    AVCaptureDevice * videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if(videoDevice == nil) assert(0);
    
    //-- Add the device to the session.
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if(error) assert(0);
    
    [_captureSession addInput:input];
    
    //-- Configure the preview layer
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_previewLayer setFrame:CGRectMake(0, 0, _cameraPreviewView.frame.size.width, _cameraPreviewView.frame.size.height)];
    
    //-- Add the layer to the view that should display the camera input
    [self.cameraPreviewView.layer addSublayer:_previewLayer];
    
    //-- Start the camera
    [_captureSession startRunning];
    
    
}

#pragma mark - View lifecycle


- (void)viewDidLoad
{
    //Called after the controller's view is loaded into memory
    
    [super viewDidLoad];
    _widths = [NSMutableArray arrayWithCapacity:4];
    _trianglePath = [UIBezierPath bezierPath];
    atrianglePoints.valid = false;
    atrianglePoints.LE_x = 0;
    atrianglePoints.LE_y = 0;
    atrianglePoints.RE_x = 0;
    atrianglePoints.RE_y = 0;
    atrianglePoints.Mouth_x = 0;
    atrianglePoints.Mouth_y = 0;
    while([_widths count] < 4)
    {
        [_widths addObject:[NSNumber numberWithFloat: 1.0]];
    }
    [self setupCaptureSession ];
    [self.drawLayer setNeedsDisplay];
    [self.cameraPreviewView.layer addSublayer:self.drawLayer];
    
    CGSize sizeOfCamera = _cameraPreviewView.layer.frame.size;
    CGSize sizeOfView = self.view.bounds.size;
    
}


@end
