//
//  ViewController.m
//  FaceDetectionExample
//
//  Created by Johann Dowa on 11-11-01.
//  Copyright (c) 2011 ManiacDev.Com. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    currentMaxAccelX = 0;
    currentMaxAccelY = 0;
    currentMaxAccelZ = 0;
    
    currentMaxRotX = 0;
    currentMaxRotY = 0;
    currentMaxRotZ = 0;
    
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
    accel_point.y =acceleration.y;
    accel_point.z = acceleration.z;
    
    NSDate *accel_start = [[NSDate init] alloc];
    accel_point.delta = [accel_start timeIntervalSinceNow];

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
    
    NSDate *rotate_start = [[NSDate init] alloc];
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
    
    currentMaxAccelX = 0;
    currentMaxAccelY = 0;
    currentMaxAccelZ = 0;
    
    currentMaxRotX = 0;
    currentMaxRotY = 0;
    currentMaxRotZ = 0;
    
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
