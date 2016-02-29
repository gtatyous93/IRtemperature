//
//  UIViewController_CoreMotionViewController.h
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/19/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "queue.h"
#import <CoreMotion/CoreMotion.h>

#define SAMPLING_PERIOD .2
typedef struct {
    NSTimeInterval delta;
    int x;
    int y;
    int z;
} accel_point_t;

typedef struct {
    NSTimeInterval delta;
    int x;
    int y;
    int z;
} rotation_point_t;


//@interface UIViewController ()
@interface CoreMotionViewController : UIViewController

@property (strong, atomic) NSMutableArray *accel_FIFO;
@property (strong, atomic) NSMutableArray *rotat_FIFO;

@property (nonatomic) double currentMaxAccelX;
@property (nonatomic) double currentMaxAccelY;
@property (nonatomic) double currentMaxAccelZ;

@property (nonatomic) double currentMaxRotX;
@property (nonatomic) double currentMaxRotY;
@property (nonatomic) double currentMaxRotZ;

@property (atomic) CGFloat axial_displacement,depth;
@property (nonatomic) bool capturing;


@property (strong, nonatomic) IBOutlet UILabel *accX;
@property (strong, nonatomic) IBOutlet UILabel *accY;
@property (strong, nonatomic) IBOutlet UILabel *accZ;

@property (strong, nonatomic) IBOutlet UILabel *rotX;
@property (strong, nonatomic) IBOutlet UILabel *rotY;
@property (strong, nonatomic) IBOutlet UILabel *rotZ;

@property (strong, nonatomic) IBOutlet UILabel *maxAccX;
@property (strong, nonatomic) IBOutlet UILabel *maxAccY;
@property (strong, nonatomic) IBOutlet UILabel *maxAccZ;

@property (strong, nonatomic) IBOutlet UILabel *maxRotX;
@property (strong, nonatomic) IBOutlet UILabel *maxRotY;
@property (strong, nonatomic) IBOutlet UILabel *maxRotZ;

- (IBAction)integrator:(id)sender;

@property (strong, nonatomic) CMMotionManager *motionManager;


@end
