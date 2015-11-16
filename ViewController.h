#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "queue.h"

double currentMaxAccelX;
double currentMaxAccelY;
double currentMaxAccelZ;
double currentMaxRotX;
double currentMaxRotY;
double currentMaxRotZ;


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


@interface ViewController : UIViewController

@property (strong, atomic) NSMutableArray *accel_FIFO;
@property (strong, atomic) NSMutableArray *rotat_FIFO;


@property (strong, nonatomic) IBOutlet UILabel *accX;
@property (strong, nonatomic) IBOutlet UILabel *accY;
@property (strong, nonatomic) IBOutlet UILabel *accZ;

@property (strong, nonatomic) IBOutlet UILabel *maxAccX;
@property (strong, nonatomic) IBOutlet UILabel *maxAccY;
@property (strong, nonatomic) IBOutlet UILabel *maxAccZ;

@property (strong, nonatomic) IBOutlet UILabel *rotX;
@property (strong, nonatomic) IBOutlet UILabel *rotY;
@property (strong, nonatomic) IBOutlet UILabel *rotZ;

@property (strong, nonatomic) IBOutlet UILabel *maxRotX;
@property (strong, nonatomic) IBOutlet UILabel *maxRotY;
@property (strong, nonatomic) IBOutlet UILabel *maxRotZ;




- (IBAction)resetMaxValues:(id)sender;

@property (strong, nonatomic) CMMotionManager *motionManager;

@end