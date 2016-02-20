

#import "AppDelegate.h"

#import "ViewController.h"






//Main stuff
@implementation AppDelegate
@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize navigationController = _navigationController;



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


/*
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
    
    
    // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured \
    A serial dispatch queue guarantees that video frames will be delivered in order
    
    //[videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    dispatch_queue_t videoOutputQueue = dispatch_queue_create("VideoOutputQueue", DISPATCH_QUEUE_SERIAL);
    [videoOutput setSampleBufferDelegate:self queue:videoOutputQueue];
    
    videoOutput.videoSettings =
    [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    //Set up camera display on view
    _viewController.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    _viewController.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_viewController.previewLayer setFrame:CGRectMake(0, 0, _viewController.cameraPreviewView.frame.size.width, _viewController.cameraPreviewView.frame.size.height)];
    
    
    //Set minFrameDuration to cap framerate
    if ( [captureSession canAddOutput:videoOutput] ) [captureSession addOutput:videoOutput];
    else NSLog(@"Couldn't add video output");
    
    // Start capturing
    [captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    if (![captureSession isRunning]) [captureSession startRunning];
}
 */






- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //...
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /*
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _viewController = (ViewController *)[sb instantiateViewControllerWithIdentifier:@"ViewC"];
    
    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [_window setRootViewController: _viewController];
    [_window makeKeyAndVisible];
    
    //Init camera, facial feature measure variable
    //_previous_widths = 0;
    //[self setupCaptureSession];
    */
    
    /*
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    //_viewController = (ViewController *)[sb instantiateViewControllerWithIdentifier:@"ViewC"];
    _navigationController= (UINavigationController*)[sb instantiateViewControllerWithIdentifier: @"ViewC"];
    
    _window.backgroundColor = [UIColor yellowColor];
    [_window setRootViewController: _navigationController];
    
    [_navigationController setNavigationBarHidden:YES];
    //[[UIApplication sharedApplication] setStatusBarHidden:YES];
    [_window makeKeyAndVisible];

    [_navigationController.view layoutSubviews];
     
     */
    
    //UINavigationController *navigationController=[[UINavigationController alloc] initWithRootViewController:_viewController];
    //[_window setRootViewController: navigationController];
    //[_window makeKeyAndVisible];

    
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

