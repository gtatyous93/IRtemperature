//
//  UIViewController_AudioViewController.h
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/19/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVFoundation/AVFoundation.h"

#import "AudioSignalGenerator.h"
#import "AudioQueueObject.h"
#import "AudioSignalAnalyzer.h"
#import "BinaryRecognizer.h"


@interface AudioViewController : UIViewController

@property (nonatomic) AudioSignalGenerator *generator;
@property (nonatomic) AudioSignalAnalyzer* analyzer;
@property (nonatomic) BinaryRecognizer* recognizer;



- (IBAction)tone:(id)sender;


@end
