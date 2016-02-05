//
//  AppDelegate.h
//  FaceDetectionExample
//
//  Created by Johann Dowa on 11-11-01.
//  Copyright (c) 2011 ManiacDev.Com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreImage/CoreImage.h>
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"

#import "ViewController.h"

#import "AVFoundation/AVFoundation.h"

#import "AudioSignalGenerator.h"
#import "AudioQueueObject.h"
#import "AudioSignalAnalyzer.h"
#import "BinaryRecognizer.h"

//The app delegate is being used currently to run all of the handlers and main algorithms (face detection, \
depth integration, video/sensor callbacks). video and sensor data callbacks should be moved to special \
classes

@class ViewController;


@interface AppDelegate : UIResponder <UIApplicationDelegate>;


@property (strong, nonatomic) UIWindow *window;

@property AVCaptureSession* captureSession;
@property (strong,atomic) NSMutableArray *widths,*previous_widths;
@property (atomic) CGFloat axial_displacement,delta_width,depth;
@property (nonatomic) AudioSignalGenerator *generator;
@property (nonatomic) AudioSignalAnalyzer* analyzer;
@property (nonatomic) BinaryRecognizer* recognizer;



@property (strong, nonatomic) ViewController *viewController;

@end

@interface AppDelegate() <AVCaptureVideoDataOutputSampleBufferDelegate>;
@end