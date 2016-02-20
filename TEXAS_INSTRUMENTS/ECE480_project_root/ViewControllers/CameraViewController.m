//
//  CameraViewController.m
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/19/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CameraViewController.h"


@implementation CameraViewController


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


-(void) setupCaptureSession
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
    [videoOutput setSampleBufferDelegate:self queue:videoOutputQueue];
    
    videoOutput.videoSettings =
    [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    //Set up camera display on view
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_previewLayer setFrame:CGRectMake(0, 0, _cameraPreviewView.frame.size.width, _cameraPreviewView.frame.size.height)];
    
    //-- Add the layer to the view that should display the camera input
    [self.cameraPreviewView.layer addSublayer:_previewLayer];
    
    //Set minFrameDuration to cap framerate
    if ( [_captureSession canAddOutput:videoOutput] ) [_captureSession addOutput:videoOutput];
    else NSLog(@"Couldn't add video output");
    
    // Start capturing
    [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    if (![_captureSession isRunning]) [_captureSession startRunning];
}



// Create a UIImage from sample buffer data
- (CIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    NSLog(@"imageFromSampleBuffer: called");
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


//This is the callback for the video buffer queue
//Compliant with protocol set in the SetupCaptureSession function when the queue is configured
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"captureOutput: didOutputSampleBufferFromConnection");
    NSNumber* zero = 0;
    // Create a UIImage from the sample buffer data
    CIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
     //TODO: fix this code, it is buggy right now
    if([self getFeatureWidth:image]) self.face_bool.text = @"Face detected";
    else self.face_bool.text = @"No face";
     
     //_axial_displacement = [self displacement_capture_reset]; //positive: closer, negative: farther
     //_delta_width = [[_widths objectAtIndex:0] floatValue] - [[_previous_widths objectAtIndex:0] floatValue];
     //_depth = [self calculate_depth:_delta_width withDisplacement:_axial_displacement];
     _IBdepth.text = [NSString stringWithFormat:@" %@",_IBdepth];
    self.dist_LE_RE.text =[NSString stringWithFormat:@" %@",[[_widths objectAtIndex:0] stringValue]];
    self.dist_LE_M.text = [NSString stringWithFormat:@" %.2f",[[_widths objectAtIndex:1] doubleValue]];
    self.dist_RE_M.text = [NSString stringWithFormat:@" %.2f",[[_widths objectAtIndex:2] doubleValue]];
    self.dist_face.text = [NSString stringWithFormat:@" %.2f",[[_widths objectAtIndex:3] doubleValue]];
    
    /*
     
     //Update previous_widths
     for (NSNumber* width_reading in _widths) //iterate through LE_RE, RE_M, LE_M, facewidth
     {
     if ([width_reading compare:zero]) //reset case: measured width feature was reset
     {
     //reset state information about previous reading
     
     [_previous_widths replaceObjectAtIndex:[_widths indexOfObject:width_reading]withObject:zero];
     
     }
     else
     {
     
     //previous_widths should have the same size as
     
     //determine the difference in width for this feature from the previous capture
     NSNumber *new_num = [NSNumber numberWithFloat:
     [width_reading floatValue] -
     [[ _previous_widths objectAtIndex:[_widths indexOfObject:width_reading] ] floatValue] ];
     
     [_previous_widths replaceObjectAtIndex:[_widths indexOfObject:width_reading]withObject:new_num];
     }
     
     }
     */
    
}

-(BOOL) getFeatureWidth:(CIImage *)frame_sample
{
    //Perform image analysis on a still image. This is used in conjunction with the video frame buffer handler (captureOutput)
    //CIImage* image = [CIImage imageWithCGImage:facePicture.image.CGImage]; //extract frames from video?
    CIImage * image = frame_sample;// = [frame_sample CIImage];
    
    
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
    NSArray* features = [detector featuresInImage:image];
    ////
    if(!features) return false;
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
            //_widths[0] = [NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.rightEyePosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.rightEyePosition.y),2))];
            NSLog(@"captureOutput: didOutputSampleBufferFromConnection");
        }
        if(faceFeature.hasRightEyePosition && faceFeature.hasMouthPosition)
        {
            [_widths replaceObjectAtIndex:1 withObject:[NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.rightEyePosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.rightEyePosition.y),2)) ]];
            //_widths[1] = [NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.rightEyePosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.rightEyePosition.y),2)) ];
            NSLog(@"captureOutput: didOutputSampleBufferFromConnection");
        }
        if(faceFeature.hasLeftEyePosition && faceFeature.hasMouthPosition)
        {
            [_widths replaceObjectAtIndex:2 withObject:[NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.mouthPosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.mouthPosition.y),2)) ]];
            //_widths[2] = [NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.mouthPosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.mouthPosition.y),2)) ];
            NSLog(@"captureOutput: didOutputSampleBufferFromConnection");
        }
        [_widths replaceObjectAtIndex:3 withObject:[NSNumber numberWithFloat:faceFeature.bounds.size.width]];
        //_widths[3] = [NSNumber numberWithFloat:faceFeature.bounds.size.width];
        
    }
    return true;
    
    
    
}



//UIView inherited methods

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


- (void)viewDidLoad
{
    //Called after the controller's view is loaded into memory
    
    [super viewDidLoad];
    _widths = [NSMutableArray arrayWithCapacity:4];
    while([_widths count] < 4)
    {
        [_widths addObject:[NSNumber numberWithFloat: 0.0]];
    }
    [self setupCaptureSession ];
    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}



@end