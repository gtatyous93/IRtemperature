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




//Output settings
#define OUT_SAMPLE_RATE 500000.00 //441000.00
#define kOutputBus 0

//Input settings
#define BYTES_PER_BLOCK 32
#define IN_SAMPLE_TYPE SInt16
#define IN_SAMPLE_RATE 6060//12120.00 //set to four times the baud rate of the incoming temperature data
#define kInputBus 1


//old, delete these
#define FREQUENCY 1000
//#define SAMPLE_RATE 44100
#define DURATION 50.0
#define FILENAME_FORMAT @"%0.3f-square.aif"

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
    
//    UILabel* sampleLabel;
    UILabel* labelStatus;
    UIButton* buttonRecord;
    UIButton* buttonPlay;
    RecordState recordState;
    PlayState playState;
    CFURLRef fileURL;
    UISlider *frequencySlider;
    AudioComponentInstance toneUnit;
    
@public
    double threshold;
    double frequency;
    double sampleRate;
    double theta;
    NSMutableArray *myIntegers;
}



@property (readonly) AudioBuffer audioBuffer;
@property (readonly) AudioComponentInstance audioUnit;
@property (nonatomic) float gain;
@property (nonatomic) int min_sample;
@property (nonatomic) int max_sample;
@property (nonatomic) int mid_voltage;


@property (nonatomic, retain) IBOutlet UISlider *frequencySlider;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet UILabel *frequencyLabel;
@property (nonatomic, retain) IBOutlet UILabel *sampleLabel;


//Using standard core Audio stuff
@property (nonatomic) AudioQueueRef *TransmitterAudioQUeue;
@property (nonatomic) AudioQueueRef *ReceiverAudioQUeue;
//@property (retain) IBOutlet UIButton *thebutton;


@property (nonatomic) int current_sample_index;
@property (nonatomic) int current_sample;
@property (atomic) NSString* string_sample;
@property (weak, nonatomic) IBOutlet UILabel *cmdstatus;

//Audio Streaming input

-(void)initializeAudio;
-(void)processBuffer: (AudioBuffer*) audioBuffer;

// control object
-(void)start;
-(void)stop;



//UI

- (IBAction)play:(id)sender;
- (IBAction)record:(id)sender;
- (IBAction)sliderChanged:(id)sender;
- (IBAction)send:(id)sender;




//Stuff from application online
//-(void) stop;

- (BOOL)getFilename:(char*)buffer maxLenth:(int)maxBufferLength;
- (void)setupAudioFormat:(AudioStreamBasicDescription*)format;
- (void)recordPressed:(id)sender;
- (void)playPressed:(id)sender;
- (void)startRecording;
- (void)stopRecording;
- (void)startPlayback;
- (void)stopPlayback;








@end
