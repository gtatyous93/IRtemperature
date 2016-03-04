//
//  IntegratingViewController.h
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/28/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#ifndef IntegratingViewController_h
#define IntegratingViewController_h

#import "AudioController.h"
#import "VideoController.h"
#import "MotionController.h"

@interface IntegratingViewController : UIViewController


//@property (nonatomic) AudioController *audioControl;
//@property (nonatomic) VideoController *videoControl;
//@property (nonatomic) MotionController *motionControl;

@property VideoController*  vidControl;
@property MotionController* motControl;
@property AudioController*  audControl;


@property (strong, atomic) IBOutlet UILabel *face_bool;


@end

#endif /* IntegratingViewController_h */

