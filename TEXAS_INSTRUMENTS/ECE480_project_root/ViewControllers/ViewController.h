//#import <UIKit/UIKit.h>
//#import <CoreMotion/CoreMotion.h>

#import <UIKit/UIKit.h>
#import <CoreAudio/CoreAudioTypes.h>




@interface ViewController : UINavigationController
<UITextFieldDelegate,UIPickerViewDataSource,UIPickerViewDelegate>
{
    
    UITextField *myTextField;
    UIPickerView *myPickerView;
    NSArray *pickerArray;
}


@end