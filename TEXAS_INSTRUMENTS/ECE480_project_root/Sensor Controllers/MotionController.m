//
//  CoreMotionViewController.m
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/19/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MotionController.h"

@implementation MotionController

@synthesize accel_FIFO = _accel_FIFO;


- (IBAction)integrator:(id)sender
{
    UIButton *selectedButton = (UIButton *)sender;
    if(_capturing)
    {
        //then stop capturing, and calculate the double integral
        _capturing = false;
        [selectedButton setTitle:NSLocalizedString(@"Start", nil) forState:0];
    }
    else
    {
        //then start capturing
        _capturing = true;
        [selectedButton setTitle:NSLocalizedString(@"Stop", nil) forState:0];
        
    }
    
}

-(float)getDisplacement
{
    float sample_sum = 0.0;
    NSMutableArray * integral = [NSMutableArray array];
    for( NSNumber* sample in _accel_FIFO)
    {
        sample_sum += _samplePeriod*[sample floatValue]*100;
        [integral addObject:[NSNumber numberWithFloat:sample_sum]];
    }
    sample_sum = 0;
    for( NSNumber* sample in integral)
    {
        sample_sum += _samplePeriod*[sample floatValue];
    }
    
    [_accel_FIFO removeAllObjects];
    return sample_sum;
    
}


-(void)outputMotionData:(CMDeviceMotion *)motion
{
    if(_capturing)
    {
        float adjusted_accel = ([motion userAcceleration].z)/9.806;
        NSNumber *sample = [NSNumber numberWithFloat:adjusted_accel];
        [_accel_FIFO addObject:sample];
    }
    
}


-(CGFloat)calculate_depth:(CGFloat)delta_width withDisplacement:(CGFloat)displacement
{
    //TODO: experimentally determine the relationship between d_featureWidth/d_axialDistance and depth
    CGFloat div;
    div = delta_width/displacement;
    return div;
}



- (void) ConfigMotionSensors:(CMDeviceMotionHandler)handler withSamplePeriod:(float)samplingPeriod
{
    _samplePeriod = samplingPeriod;
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.deviceMotionUpdateInterval = _samplePeriod;
    [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];

}


#pragma mark - View lifecycle


- (void)viewDidLoad
{
    //Called after the controller's view is loaded into memory
    [super viewDidLoad];
    _capturing = false;
    _accel_FIFO = [[NSMutableArray alloc] init];
    [self ConfigMotionSensors:^(CMDeviceMotion *motionData, NSError *error) { [self outputMotionData:motionData]; if(error) { NSLog(@"%@", error); } } withSamplePeriod:.02];
    
}


@end