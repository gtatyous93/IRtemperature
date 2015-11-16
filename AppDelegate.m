

#import "AppDelegate.h"

#import "ViewController.h"




@implementation AppDelegate
@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize widths = _widths;


/*
 Continuously take readings of phone's displacement (reset if line of sight is broken)
 - displacement reading should be calculated every time a new frame sample is taken
 - measurement should be applied to each comparison of two frames' detected widths before reset
 Take readings of some parameter from the target (eye space, face width, the distance between any two nodes)
 - if one of the nodes is "lost," switch to a new pair or measurement
 - if the tracking ID of the face is lost/reset, then reset measurements
 calculate the rate for a series of points
 - if more points need to be collected, display message on screen
 - if a sufficient number of points have been collected, forward measured depth to temperature calculation
 Need to determine relationship between d_spacing/d_displacement and absolute depth
 */


typedef enum FeatureWidth
{
    FW,FL, //face width and length
    RE_LE, //right eye to left eye
    RE_M, //right eye to mouth
    LE_M, //left eye to mouth
} FeatureWidth_t;



-(void) setupCaptureSession
{
    //Enable back-facing camera and set up a capture session, generate a stream out output frames and pass them to a callback serial queue
    
    
    // Grab the back-facing camera
    AVCaptureDevice *backFacingCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == AVCaptureDevicePositionBack) backFacingCamera = device;
    }
    
    // Create the capture session
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    
    // Add the video input
    NSError *error = nil;
    AVCaptureDeviceInput* videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:backFacingCamera error:&error];
    if ([captureSession canAddInput:videoInput]) [captureSession addInput:videoInput];
    
    // Add the video frame output
    AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order

    //[videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    dispatch_queue_t videoOutputQueue = dispatch_queue_create("VideoOutputQueue", DISPATCH_QUEUE_SERIAL);
    
    [videoOutput setSampleBufferDelegate:self queue:videoOutputQueue];
    
    videoOutput.videoSettings =
    [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    
    // If you wish to cap the frame rate to a known value, such as 15 fps, set minFrameDuration.
    
    if ( [captureSession canAddOutput:videoOutput] ) [captureSession addOutput:videoOutput];
    else NSLog(@"Couldn't add video output");
    
    // Start capturing
    [captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    if (![captureSession isRunning]) [captureSession startRunning];
}

//This is the callback for the buffer queue, it is called every time ... a frame enters the buffer?
//Compliant with protocol set in the SetupCaptureSession function when the queue is configured
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"captureOutput: didOutputSampleBufferFromConnection");
    
    // Create a UIImage from the sample buffer data
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
    [self getFeatureWidth:image];
    for (NSNumber* width_reading in _widths) //iterate through LE_RE, RE_M, LE_M, facewidth
    {
        if ([width_reading compare:0]) //reset case: measured width feature was reset
        {
            //reset state information about previous reading
            [_previous_widths replaceObjectAtIndex:[_widths indexOfObject:width_reading]withObject:0];
            
        }
        else
        {
            _axial_displacement = [self displacement_capture_reset]; //positive: closer, negative: farther
            _delta_width =  [width_reading floatValue] - [[_previous_widths objectAtIndex:[_widths indexOfObject:width_reading]] floatValue]; //positive: became larger, negative: became smaller
            _depth = [self calculate_depth:_delta_width withDisplacement:_axial_displacement];
        }
        
    }
}

// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
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
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}


//this should be the frame callback
-(void) getFeatureWidth:(UIImage *)frame_sample
{
    //CIImage* image = [CIImage imageWithCGImage:facePicture.image.CGImage]; //extract frames from video?
    CIImage * image = frame_sample.CIImage;
    
    
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
    NSArray* features = [detector featuresInImage:image];
    ////

    //_widths = {0,0,0,0};
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
            _widths[0] = [NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.rightEyePosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.rightEyePosition.y),2))];
        }
        if(faceFeature.hasRightEyePosition && faceFeature.hasMouthPosition)
        {
            _widths[1] = [NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.rightEyePosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.rightEyePosition.y),2)) ];
        }
        if(faceFeature.hasLeftEyePosition && faceFeature.hasMouthPosition)
        {
            _widths[2] = [NSNumber numberWithFloat:sqrt(pow((faceFeature.leftEyePosition.x -  faceFeature.mouthPosition.x),2) + pow((faceFeature.leftEyePosition.y -  faceFeature.mouthPosition.y),2)) ];
        }
        _widths[3] = [NSNumber numberWithFloat:faceFeature.bounds.size.width];

    }
    
    
    
}


-(int)displacement_capture_reset
{
    //return the measured displacement along the axis aligned with the camera relative to a start point
    //reset the start point of displacement to the current position
    static double previous_time; //double integrate the axial acceleration over the time bounds between successive measurements
    double current_time =[[NSDate date] timeIntervalSince1970];
//    NSTimeInterval timeInterval = [previous_time timeIntervalSinceNow];
 
    double ret = current_time - previous_time;
    
    //Double integrate over a time indexed buffer of xyz acceleration using current_time and previous_time as bounds
    //Determine the axis along which the back-facing camera and target are aligned using gyroscope and accelerometer ("gravity" as seen by accelerometer)
    //take dot product with doubly integrated accel measure
    
    previous_time = [[NSDate date] timeIntervalSince1970];
    return ret;
}

-(CGFloat)calculate_depth:(CGFloat)delta_width withDisplacement:(CGFloat)displacement
{
    //TODO: experimentally determine the relationship between d_featureWidth/d_axialDistance and depth
    CGFloat div;
    div = delta_width/displacement;
    return div;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end




/*
 - (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
 {
 //
 
 
 // got an image
 CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
 CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
 CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
 if (attachments)
 CFRelease(attachments);
 
 /kCGImagePropertyOrientation values
 The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
 by the TIFF and EXIF specifications -- see enumeration of integer constants.
 The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
 
 used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
 If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image.
 
 
 int exifOrientation = 6; //   6  =  0th row is on the right, and 0th column is the top. Portrait mode.
 NSDictionary *imageOptions = @{CIDetectorImageOrientation : @(exifOrientation)};
 NSArray *features = [self.faceDetector featuresInImage:ciImage options:imageOptions];
 
 // get the clean aperture
 // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
 // that represents image data valid for display.
 CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
 CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false );
 
 // called asynchronously as the capture output is capturing sample buffers, this method asks the face detector
 // to detect features
 dispatch_async(dispatch_get_main_queue(), ^(void) {
 CGSize parentFrameSize = [self.previewView frame].size;
 NSString *gravity = [self.previewLayer videoGravity];
 
 CGRect previewBox = [DetectFace videoPreviewBoxForGravity:gravity frameSize:parentFrameSize apertureSize:clap.size];
 if([self.delegate respondsToSelector:@selector(detectedFaceController:features:forVideoBox:withPreviewBox:)])
 [self.delegate detectedFaceController:self features:features forVideoBox:clap withPreviewBox:previewBox];
 });
 }
 */

