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

#import <AudioUnit/AudioUnit.h>

#define NUM_BUFFERS 3
#define SECONDS_TO_RECORD 10



///Audio unit input stream

#define max(a, b) (((a) > (b)) ? (a) : (b))
// return min value for given values
#define min(a, b) (((a) < (b)) ? (a) : (b))

#define kOutputBus 0
#define kInputBus 1

// our default sample rate
#define SAMPLE_RATE 44100.00


/////

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
    // Audio unit
    AudioComponentInstance audioUnit;
    
    // Audio buffers
    AudioBuffer audioBuffer;
    
    UILabel* sampleLabel;
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

@property (readonly) AudioBuffer audioBuffer;
@property (readonly) AudioComponentInstance audioUnit;
@property (nonatomic) float gain;



@property (nonatomic, retain) IBOutlet UISlider *frequencySlider;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet UILabel *frequencyLabel;
@property (nonatomic, retain) IBOutlet UILabel *sampleLabel;


//Using standard core Audio stuff
@property (nonatomic) AudioQueueRef *TransmitterAudioQUeue;
@property (nonatomic) AudioQueueRef *ReceiverAudioQUeue;
//@property (retain) IBOutlet UIButton *thebutton;


//Audio Streaming input

-(void)initializeAudio;
-(void)processBuffer: (AudioBufferList*) audioBufferList;

// control object
-(void)start;
-(void)stop;



//UI

- (IBAction)play:(id)sender;
- (IBAction)record:(id)sender;
- (IBAction)sliderChanged:(id)sender;



//Stuff from application online
-(void) stop;

- (BOOL)getFilename:(char*)buffer maxLenth:(int)maxBufferLength;
- (void)setupAudioFormat:(AudioStreamBasicDescription*)format;
- (void)recordPressed:(id)sender;
- (void)playPressed:(id)sender;
- (void)startRecording;
- (void)stopRecording;
- (void)startPlayback;
- (void)stopPlayback;








@end
