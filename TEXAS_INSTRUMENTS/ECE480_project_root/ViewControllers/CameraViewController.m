//
//  CameraViewController.m
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/19/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CameraViewController.h"
@import Foundation;


FacialPoints trianglePoints;

float counter_guy = 0;
int offsetX = 340;
int offsetY = 380;
float scalex = .75;
float scaley = .75;

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



//This is the callback for the video buffer queue
//Compliant with protocol set in the SetupCaptureSession function when the queue is configured

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    CIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    bool face_test = [self getFeatureWidth:image];
    //_axial_displacement = [self displacement_capture_reset]; //positive: closer, negative: farther
    //_delta_width = [[_widths objectAtIndex:0] floatValue] - [[_previous_widths objectAtIndex:0] floatValue];
    //_depth = [self calculate_depth:_delta_width withDisplacement:_axial_displacement];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self drawme]; //must be in the main thread
        if(face_test)
        {
            _face_bool.text = @"Face detected";
            self.view.backgroundColor = [UIColor greenColor];
        }
        else
        {
            _face_bool.text = @"No face";
            self.view.backgroundColor = [UIColor redColor];
        }
        _dist_LE_RE.text = [NSString stringWithFormat:@" %.2f",[[_widths objectAtIndex:0] doubleValue]];
        _dist_LE_M.text =  [NSString stringWithFormat:@" %.2f",[[_widths objectAtIndex:1] doubleValue]];
        _dist_RE_M.text =  [NSString stringWithFormat:@" %.2f",[[_widths objectAtIndex:2] doubleValue]];
        _dist_face.text =  [NSString stringWithFormat:@" %.2f",[[_widths objectAtIndex:3] doubleValue]];
        
    }];    /*
            
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
            //previous_widths should have the same size as _widths. determine the difference in width for this feature from the previous capture
            NSNumber *new_num = [NSNumber numberWithFloat: [width_reading floatValue] - [[ _previous_widths objectAtIndex:[_widths indexOfObject:width_reading] ] floatValue] ];
            [_previous_widths replaceObjectAtIndex:[_widths indexOfObject:width_reading]withObject:new_num];
        }
        
    }*/
}

- (void)drawLayer:(CALayer*)layer inContext:(CGContextRef)ctx
{
    if(trianglePoints.valid){
        //Draw a triangle path (inverted across x and y) using 3 points determined from facial feature recognizer
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, (offsetX-scalex*trianglePoints.LE_x), (offsetY-scaley*trianglePoints.LE_y));
        CGContextAddLineToPoint(ctx, (offsetX-scalex*trianglePoints.RE_x), (offsetY-scaley*trianglePoints.RE_y));
        CGContextAddLineToPoint(ctx, (offsetX-scalex*trianglePoints.Mouth_x), (offsetY-scaley*trianglePoints.Mouth_y));
        CGContextClosePath(ctx);
        
        //Leave the fill empty, create a dashed line along the perimeter of the triangle path
        CGContextSetFillColor(ctx, CGColorGetComponents([UIColor clearColor].CGColor));
        //CGContextSetFillColor(ctx, CGColorGetComponents(color1.CGColor));
        [[UIColor whiteColor] setStroke];
        CGContextSetLineWidth(ctx, 5.0);
        CGFloat dash1[] = {5.0, 2.0};
        CGContextSetLineDash(ctx, 0.0, dash1, 2);
        
        CGContextStrokePath(ctx);
        CGContextDrawPath(ctx, kCGPathFill);
    }
}

- (void)drawme
{
    [self.drawLayer setNeedsDisplay];
}

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
    trianglePoints.valid = false;
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
            //_widths[0] = [NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.rightEyePosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.rightEyePosition.y),2))];
           
        }
        if(faceFeature.hasRightEyePosition && faceFeature.hasMouthPosition)
        {
            [_widths replaceObjectAtIndex:1 withObject:[NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.rightEyePosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.rightEyePosition.y),2)) ]];
            //_widths[1] = [NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.rightEyePosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.rightEyePosition.y),2)) ];
           
        }
        if(faceFeature.hasLeftEyePosition && faceFeature.hasMouthPosition)
        {
            [_widths replaceObjectAtIndex:2 withObject:[NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.mouthPosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.mouthPosition.y),2)) ]];
            //_widths[2] = [NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.mouthPosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.mouthPosition.y),2)) ];
            
        }
        [_widths replaceObjectAtIndex:3 withObject:[NSNumber numberWithFloat:faceFeature.bounds.size.width]];
        
        //Calculate area
        if(faceFeature.hasLeftEyePosition && faceFeature.hasMouthPosition && faceFeature.hasRightEyePosition)
        {
            trianglePoints.valid = true;
            trianglePoints.LE_x = faceFeature.leftEyePosition.x;
            trianglePoints.LE_y = faceFeature.leftEyePosition.y;
            trianglePoints.RE_x = faceFeature.rightEyePosition.x;
            trianglePoints.RE_y = faceFeature.rightEyePosition.y;
            trianglePoints.Mouth_x = faceFeature.mouthPosition.x;
            trianglePoints.Mouth_y = faceFeature.mouthPosition.y;
            
            float a,b,c,d;
            a = faceFeature.rightEyePosition.x - faceFeature.mouthPosition.x;
            b = faceFeature.rightEyePosition.y - faceFeature.mouthPosition.y;
            c = faceFeature.leftEyePosition.x - faceFeature.mouthPosition.x;
            d = faceFeature.leftEyePosition.y - faceFeature.mouthPosition.x;
            _widths[3] = [NSNumber numberWithFloat:fabsf((a*d) - (b*c))/2];
            
            
        }
        
    }
    
    //trianglePoints = trianglePoints;
    return true;
    
    
    
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
    _trianglePath = [UIBezierPath bezierPath];
    trianglePoints.valid = false;
    trianglePoints.LE_x = 0;
    trianglePoints.LE_y = 0;
    trianglePoints.RE_x = 0;
    trianglePoints.RE_y = 0;
    trianglePoints.Mouth_x = 0;
    trianglePoints.Mouth_y = 0;
    counter_guy = 0;
    while([_widths count] < 4)
    {
        [_widths addObject:[NSNumber numberWithFloat: 1.0]];
    }
    [self setupCaptureSession ];
    [self.drawLayer setNeedsDisplay];
    [self.cameraPreviewView.layer addSublayer:self.drawLayer];
    self.view.backgroundColor = [UIColor redColor];
    CGSize sizeOfCamera = _cameraPreviewView.layer.frame.size;
    CGSize sizeOfView = self.view.bounds.size;
    
    //camera is currently 640(x), 480(y) in feature detector
    scalex = .75;//sizeOfCamera.width/480;
    scaley = .73;//sizeOfCamera.height/640;
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

- (NSUInteger) supportedInterfaceOrientations {
    // Return a bitmask of supported orientations. If you need more,
    // use bitwise or (see the commented return).
    return UIInterfaceOrientationMaskPortrait;
    // return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    // Return the orientation you'd prefer - this is what it launches to. The
    // user can still rotate. You don't have to implement this method, in which
    // case it launches in the current orientation
    return UIInterfaceOrientationPortrait;
}



@end
