//
//  ViewController.m
//  FaceDetectionExample
//
//  Created by Johann Dowa on 11-11-01.
//  Copyright (c) 2011 ManiacDev.Com. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

@synthesize IBdepth = _IBdepth;

@synthesize accX = _accelX;
@synthesize accY = _accelY;
@synthesize accZ = _accelZ;

@synthesize rotX = _rotX;
@synthesize rotY = _rotY;
@synthesize rotZ = _rotZ;

@synthesize captureSession = _captureSession;
@synthesize previewLayer = _previewLayer;
@synthesize cameraPreviewView = _cameraPreviewView;



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    //-- Setup Capture Session.
    _captureSession = [[AVCaptureSession alloc] init];
    
    //-- Creata a video device and input from that Device.  Add the input to the capture session.
    AVCaptureDevice * videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if(videoDevice == nil)
        assert(0);
    
    //-- Add the device to the session.
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice
                                                                        error:&error];
    if(error)
        assert(0);
    
    [_captureSession addInput:input];
    
    //-- Configure the preview layer
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [_previewLayer setFrame:CGRectMake(0, 0, _cameraPreviewView.frame.size.width,
                                       _cameraPreviewView.frame.size.height)];
    
    //-- Add the layer to the view that should display the camera input
    [self.cameraPreviewView.layer addSublayer:_previewLayer];
    
    //-- Start the camera
    [_captureSession startRunning];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.accelerometerUpdateInterval = .2;
    _motionManager.gyroUpdateInterval = .2;
    
    [_motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                         withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                             [self outputAccelertionData:accelerometerData.acceleration];
                                             if(error) { NSLog(@"%@", error); }
                                         }];
    
    [_motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                                withHandler:^(CMGyroData *gyroData, NSError *error) {
                                    [self outputRotationData:gyroData.rotationRate];
                                }];
    
    
    
}

-(void)outputAccelertionData:(CMAcceleration)acceleration
{
    //Accelerometer callback
    accel_point_t accel_point;
    accel_point.x = acceleration.x;
    accel_point.y = acceleration.y;
    accel_point.z = acceleration.z;
    
    self.accX.text = [NSString stringWithFormat:@" %.2fg",acceleration.x];
    self.accY.text = [NSString stringWithFormat:@" %.2fg",acceleration.y];
    self.accZ.text = [NSString stringWithFormat:@" %.2fg",acceleration.z];
    
    
    
    NSDate *accel_start = [[NSDate alloc] init];
    accel_point.delta = [accel_start timeIntervalSinceNow]; //may be uneccesary since interval is fixed
    
    //should spawn a thread to do this bit
    while( [_accel_FIFO count ] >= 8)
    {
        [_accel_FIFO dequeue] ;
    }
    
    //verbose OBjective-C syntax for inserting structs into arrays
    [_accel_FIFO enqueue:[NSValue valueWithBytes:&accel_point objCType:@encode(accel_point_t)]];
    
    //   accel_point_t p;
    //   [NSValue getValue:&p];asdasdasd
    
    
}
-(void)outputRotationData:(CMRotationRate)rotation
{
    //Gyroscope callback
    rotation_point_t rotation_point;
    rotation_point.x = rotation.x;
    rotation_point.y = rotation.y;
    rotation_point.z = rotation.z;
    
    self.rotX.text = [NSString stringWithFormat:@" %.2fr/s",rotation.x];
    self.rotY.text = [NSString stringWithFormat:@" %.2fr/s",rotation.y];
    self.rotZ.text = [NSString stringWithFormat:@" %.2fr/s",rotation.z];
    
    
    NSDate *rotate_start = [[NSDate alloc] init];
    rotation_point.delta = [rotate_start timeIntervalSinceNow];
    
    //should spawn a thread to do this bit
    while( [_rotat_FIFO count ] >= 8)
    {
        [_rotat_FIFO dequeue] ;
    }
    
    //verbose OBjective-C syntax for inserting structs into arrays
    [_rotat_FIFO enqueue:[NSValue valueWithBytes:&rotation_point objCType:@encode(rotation_point_t)]];
    
    
}
- (IBAction)resetMaxValues:(id)sender {
    
    _accelX = 0;
    _accelY = 0;
    _accelZ = 0;
    
    _rotX = 0;
    _rotY = 0;
    _rotZ = 0;
    
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
