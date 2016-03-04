//
//  CoreMotionViewController.m
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/19/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <Foundation/Foundation.h>


#import "CoreMotionViewController.h"

@implementation CoreMotionViewController

@synthesize accX = _accelX;
@synthesize accY = _accelY;
@synthesize accZ = _accelZ;

@synthesize rotX = _rotX;
@synthesize rotY = _rotY;
@synthesize rotZ = _rotZ;

@synthesize accel_FIFO = _accel_FIFO;
@synthesize rotat_FIFO = _rotat_FIFO;


-(void)outputMotionData:(CMDeviceMotion *)motion
{
    self.rotX.text = [NSString stringWithFormat:@" %.3fg",[motion attitude].pitch];
    self.rotY.text = [NSString stringWithFormat:@" %.3fg",[motion attitude].roll];
    //self.rotZ.text = [NSString stringWithFormat:@" %.4fg",[motion attitude].yaw];
    
    self.accX.text = [NSString stringWithFormat:@" %.3fg",[motion userAcceleration].x];
    self.accY.text = [NSString stringWithFormat:@" %.3fg",[motion userAcceleration].y];
    self.accZ.text = [NSString stringWithFormat:@" %.3fg",[motion userAcceleration].z];
    
    

    
//    self.accY.text = [NSString stringWithFormat:@" %.2fg",[motion gravity]];
    if(_capturing)
    {
        accel_point_t accel_point;
        accel_point.x = [motion userAcceleration].x;
        accel_point.y = [motion userAcceleration].y;
        accel_point.z = [motion userAcceleration].z;
        
        rotation_point_t rotation_point;
        rotation_point.x = [motion attitude].pitch;
        rotation_point.y = [motion attitude].roll;
        rotation_point.z = [motion attitude].yaw;
        
        //[_accel_FIFO enqueue:[NSValue valueWithBytes:&accel_point objCType:@encode(accel_point_t)]];
        //[_rotat_FIFO enqueue:[NSValue valueWithBytes:&rotation_point objCType:@encode(rotation_point_t)]];
        float adjusted_accel = ([motion userAcceleration].z)/9.806;
        NSNumber *sample = [NSNumber numberWithFloat:adjusted_accel];
        [_accel_FIFO addObject:sample];
        
    }
    
}


//Accelerometer callback: reads Accelerations and outputs them to view
-(void)outputAccelertionData:(CMAcceleration)acceleration
{
    accel_point_t accel_point;
    accel_point.x = acceleration.x;
    accel_point.y = acceleration.y;
    accel_point.z = acceleration.z;
    
    self.accX.text = [NSString stringWithFormat:@" %.2fg",acceleration.x];
    self.accY.text = [NSString stringWithFormat:@" %.2fg",acceleration.y];
    self.accZ.text = [NSString stringWithFormat:@" %.2fg",acceleration.z];
    
    //Obtain a time point to calculate deltas between successive measurements. may be uneccesary since interval is fixed
    NSDate *accel_start = [[NSDate alloc] init];
    accel_point.delta = [accel_start timeIntervalSinceNow];
    
    //TODO: Use threads
    //Queue of the 8 most recent readings from the accelerometer
    while( [_accel_FIFO count ] >= 8)
    {
        [_accel_FIFO dequeue] ;
    }
    
    //Enqueue a 4-variable point, 3 axes + time measure
    [_accel_FIFO enqueue:[NSValue valueWithBytes:&accel_point objCType:@encode(accel_point_t)]];
    
}

//Gyroscope callback: Reads rotation measurements and outputs them onto textboxes in the view
-(void)outputRotationData:(CMRotationRate)rotation
{
    
    rotation_point_t rotation_point;
    rotation_point.x = rotation.x;
    rotation_point.y = rotation.y;
    rotation_point.z = rotation.z;
    
    self.rotX.text = [NSString stringWithFormat:@" %.2fr/s",rotation.x];
    self.rotY.text = [NSString stringWithFormat:@" %.2fr/s",rotation.y];
    self.rotZ.text = [NSString stringWithFormat:@" %.2fr/s",rotation.z];
    
    
    NSDate *rotate_start = [[NSDate alloc] init];
    rotation_point.delta = [rotate_start timeIntervalSinceNow];
    
    //TODO: Use threads
    //Queue of the 8 most recent rotation measurements
    while( [_rotat_FIFO count ] >= 8)
    {
        [_rotat_FIFO dequeue];
    }
    //Enqueue a 4-variable point, 3 axes + time measure
    [_rotat_FIFO enqueue:[NSValue valueWithBytes:&rotation_point objCType:@encode(rotation_point_t)]];
    
    
}

- (IBAction)integrator:(id)sender
{
    UIButton *selectedButton = (UIButton *)sender;
   if(_capturing)
   {
       //then stop capturing
       _capturing = false;
       //double integrate
       float ALPHA = 0.15f;
       float sample_sum = 0.0;
      
       /*
       NSMutableArray* temparray = [NSMutableArray array];
       for( NSNumber* sample in _accel_FIFO)
       {
           //output[i] = output[i] + ALPHA * (input[i] - output[i]);
       //    float ALPHA*sample;
        //   y[i] := α * x[i] + (1-α) * y[i-1];
        //   [temparray addObject:[NSNumber numberWithFloat:]];
       }
       */
       NSMutableArray * integral = [NSMutableArray array];
       for( NSNumber* sample in _accel_FIFO)
       {
           sample_sum += SAMPLING_PERIOD*[sample floatValue]*100;
           [integral addObject:[NSNumber numberWithFloat:sample_sum]];
       }
       sample_sum = 0;
       for( NSNumber* sample in integral)
       {
           sample_sum += SAMPLING_PERIOD*[sample floatValue];
       }
       
       self.rotZ.text = [NSString stringWithFormat:@" %.4fcm",sample_sum];
       [_accel_FIFO removeAllObjects];
       self.view.backgroundColor = [UIColor redColor];
       [selectedButton setTitle:NSLocalizedString(@"Start", nil) forState:0];
   }
   else
   {
       //then start capturing
       _capturing = true;
       self.view.backgroundColor = [UIColor greenColor];
       [selectedButton setTitle:NSLocalizedString(@"Stop", nil) forState:0];
       
   }
    
}


-(int)displacement_capture_reset
{
    //return the measured displacement along the axis aligned with the camera relative to a start point
    //reset the start point of displacement to the current position
    static double previous_time; //double integrate the axial acceleration over the time bounds between successive measurements
    double current_time =[[NSDate date] timeIntervalSince1970];
    //    NSTimeInterval timeInterval = [previous_time timeIntervalSinceNow];
    double delta_inter = 0;
    
    double time_interval = current_time - previous_time;
    while(delta_inter <= time_interval)
    {
        accel_point_t *p = (__bridge accel_point_t *)([_accel_FIFO objectAtIndex:0]);
        //delta_inter += p.delta ;
        delta_inter += 0.2;
        
        //] objectAtIndex:0 ];
        [_accel_FIFO  dequeue];
    }
    
    //remove all queued acceleration measurements
    while( [ _accel_FIFO count ] > 0)
    {
        [_accel_FIFO dequeue] ;
    }
    
    //Double integrate over buffer of xyz acceleration using current_time and previous_time as bounds
    //Determine the axis along which the back-facing camera and target are aligned using gyroscope and accelerometer ("gravity" as seen by accelerometer)
    //take dot product with doubly integrated accel measure
    
    previous_time = [[NSDate date] timeIntervalSince1970];
    return 1;
}

-(CGFloat)calculate_depth:(CGFloat)delta_width withDisplacement:(CGFloat)displacement
{
    //TODO: experimentally determine the relationship between d_featureWidth/d_axialDistance and depth
    CGFloat div;
    div = delta_width/displacement;
    return div;
}



- (void) ConfigMotionSensors
{
    //Update the motion manager intervals here
    _motionManager = [[CMMotionManager alloc] init];
    //_motionManager.accelerometerUpdateInterval = .2;
    //_motionManager.gyroUpdateInterval = .05;
    _motionManager.deviceMotionUpdateInterval = SAMPLING_PERIOD;
    
    
    //Create lambda functions ("blocks" in objective C) to set as the actual handlers for the queues. These \
    lambda functions will call the outputXdata functions
    
    //[_motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) { [self outputAccelertionData:accelerometerData.acceleration]; if(error) { NSLog(@"%@", error); } }];
    
    //[_motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData *gyroData, NSError *error) { [self outputRotationData:gyroData.rotationRate]; if(error) { NSLog(@"%@", error); } }];
    
    [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motionData, NSError *error) { [self outputMotionData:motionData]; if(error) { NSLog(@"%@", error); } }];
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
    _capturing = false;
    self.view.backgroundColor = [UIColor redColor];
    _accel_FIFO = [[NSMutableArray alloc] init];
    _rotat_FIFO = [[NSMutableArray alloc] init];
    [self ConfigMotionSensors];
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