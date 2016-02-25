//
//  UIViewController_AudioViewController.h
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/19/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "AppDelegate.h"

#import "AVFoundation/AVFoundation.h"

#import "AudioQueueObject.h"
#import "AudioSignalGenerator.h"
#import "AudioSignalAnalyzer.h"
#import "BinaryRecognizer.h"

#import <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFile.h>

#define NUM_BUFFERS 3
#define SECONDS_TO_RECORD 10


// Struct defining recording state
typedef struct
{
    AudioStreamBasicDescription  dataFormat;
    AudioQueueRef                queue;
    AudioQueueBufferRef          buffers[NUM_BUFFERS];
    AudioFileID                  audioFile;
    SInt64                       currentPacket;
    bool                         recording;
} RecordState;

// Struct defining playback state
typedef struct
{
    AudioStreamBasicDescription  dataFormat;
    AudioQueueRef                queue;
    AudioQueueBufferRef          buffers[NUM_BUFFERS];
    AudioFileID                  audioFile;
    SInt64                       currentPacket;
    bool                         playing;
} PlayState;

@interface AudioViewController : UIViewController
{
    UILabel* labelStatus;
    UIButton* buttonRecord;
    UIButton* buttonPlay;
    RecordState recordState;
    PlayState playState;
    CFURLRef fileURL;
    UISlider *frequencySlider;
    AudioComponentInstance toneUnit;
    
@public
    double frequency;
    double sampleRate;
    double theta;
}

@property (nonatomic, retain) IBOutlet UISlider *frequencySlider;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet UILabel *frequencyLabel;

- (IBAction)sliderChanged:(UISlider *)frequencySlider;


//Using standard core Audio stuff
@property (nonatomic) AudioQueueRef *TransmitterAudioQUeue;
@property (nonatomic) AudioQueueRef *ReceiverAudioQUeue;
//@property (retain) IBOutlet UIButton *thebutton;

//Using iPhone hacks
@property (nonatomic) AudioSignalGenerator *generator;
@property (nonatomic) AudioSignalAnalyzer* analyzer;
@property (nonatomic) BinaryRecognizer* recognizer;



- (IBAction)tone:(id)sender;
- (IBAction)record:(id)sender;



//Stuff from application online

- (BOOL)getFilename:(char*)buffer maxLenth:(int)maxBufferLength;
- (void)setupAudioFormat:(AudioStreamBasicDescription*)format;
- (void)recordPressed:(id)sender;
- (void)playPressed:(id)sender;
- (void)startRecording;
- (void)stopRecording;
- (void)startPlayback;
- (void)stopPlayback;








@end
