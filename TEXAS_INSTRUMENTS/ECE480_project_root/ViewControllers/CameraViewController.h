//
//  UIViewController_CameraViewController.h
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/19/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>

@interface CameraViewController : UIViewController

@property (nonatomic) AVCaptureVideoPreviewLayer * previewLayer;
@property (nonatomic) CAShapeLayer * drawLayer;
@property (nonatomic) UIBezierPath* trianglePath;

@property (nonatomic) AVCaptureSession * captureSession;
@property (strong,atomic) NSMutableArray *widths,*previous_widths;
@property (atomic) CGFloat delta_width;

@property (strong, nonatomic) IBOutlet UILabel *IBdepth;

@property (nonatomic) IBOutlet UIView *cameraPreviewView;
@property (strong, atomic) IBOutlet UILabel *dist_LE_RE;
@property (strong, atomic) IBOutlet UILabel *dist_LE_M;
@property (strong, atomic) IBOutlet UILabel *dist_RE_M;
@property (strong, atomic) IBOutlet UILabel *dist_face;
@property (strong, atomic) IBOutlet UILabel *face_bool;


-(BOOL) getFeatureWidth:(CIImage *)frame_sample;

- (CIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection;

-(void) setupCaptureSession;
- (void)drawme ;

@end


@interface CameraViewController() <AVCaptureVideoDataOutputSampleBufferDelegate>;
@end
