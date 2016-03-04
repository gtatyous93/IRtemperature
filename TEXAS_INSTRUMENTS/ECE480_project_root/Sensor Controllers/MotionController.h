//
//  MotionController.h
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 3/2/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#ifndef MotionController_h
#define MotionController_h

//
//  MotionController.m
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/28/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "queue.h"
#import <CoreMotion/CoreMotion.h>

//@interface UIViewController ()
@interface MotionController : UIViewController

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, atomic) NSMutableArray *accel_FIFO;
@property (atomic) CGFloat axial_displacement,depth;
@property (nonatomic) bool capturing;
@property (nonatomic) float samplePeriod;


- (IBAction)integrator:(id)sender;
- (void) ConfigMotionSensors:(CMDeviceMotionHandler)handler withSamplePeriod:(float)samplingPeriod;




@end

#endif /* MotionController_h */