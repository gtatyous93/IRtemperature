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

//what

@class ViewController;


@interface AppDelegate : UIResponder <UIApplicationDelegate>;


@property (strong, nonatomic) UIWindow *window;

@property AVCaptureSession* captureSession;
@property (strong,atomic) NSMutableArray *widths,*previous_widths;
@property (atomic) CGFloat axial_displacement,delta_width,depth;



@property (strong, nonatomic) ViewController *viewController;

@end

@interface AppDelegate() <AVCaptureVideoDataOutputSampleBufferDelegate>;
@end