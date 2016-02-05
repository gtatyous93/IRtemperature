//#import <UIKit/UIKit.h>
//#import <CoreMotion/CoreMotion.h>

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>
#import "queue.h"

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
<UITextFieldDelegate,UIPickerViewDataSource,UIPickerViewDelegate>
{
    
    UITextField *myTextField;
    UIPickerView *myPickerView;
    NSArray *pickerArray;
}

@property (strong, atomic) NSMutableArray *accel_FIFO;
@property (strong, atomic) NSMutableArray *rotat_FIFO;

@property (nonatomic) AVCaptureVideoPreviewLayer * previewLayer;
@property (nonatomic) AVCaptureSession * captureSession;


@property (strong, nonatomic) IBOutlet UILabel *IBdepth;

@property (strong, nonatomic) IBOutlet UILabel *accX;
@property (strong, nonatomic) IBOutlet UILabel *accY;
@property (strong, nonatomic) IBOutlet UILabel *accZ;


@property (nonatomic) double currentMaxAccelX;
@property (nonatomic) double currentMaxAccelY;
@property (nonatomic) double currentMaxAccelZ;
@property (nonatomic) double currentMaxRotX;
@property (nonatomic) double currentMaxRotY;
@property (nonatomic) double currentMaxRotZ;

@property (nonatomic) IBOutlet UIView *cameraPreviewView; 

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