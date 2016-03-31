//
//  AudioViewController.m
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/19/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioViewController.h"



OSStatus recordingCallback(void *inRefCon,
                           AudioUnitRenderActionFlags *ioActionFlags,
                           const AudioTimeStamp *inTimeStamp,
                           UInt32 inBusNumber,
                           UInt32 inNumberFrames,
                           AudioBufferList *ioData) {
    
    // the data gets rendered here
    AudioBuffer buffer;
    static int a = 0;
    // a variable where we check the status
    OSStatus status;
    
  
    //This is the reference to the object who owns the callback.
    if(!inRefCon) return 0;
    AudioViewController *viewController = (__bridge AudioViewController*) inRefCon;
  
    
    /*
     on this point we define the number of channels, which is mono
     for the iphone. the number of frames is usally 512 or 1024.
     */
    buffer.mDataByteSize = inNumberFrames * sizeof(IN_SAMPLE_TYPE) ; // sample size
    buffer.mNumberChannels = 1; // one channel
    buffer.mData = malloc( inNumberFrames * sizeof(IN_SAMPLE_TYPE) ); // buffer size
    
    // we put our buffer into a bufferlist array for rendering
    /*
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    // render input and check for error
   // status = AudioUnitRender([viewController audioUnit], ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames,     &bufferList);
    //[viewController hasError:status:__FILE__:__LINE__];
    
    // process the bufferlist in the audio processor
    */
     //[viewController processBuffer:&buffer];
    // clean up the buffer
    

//    int thingie = bufferList.mBuffers[0].mData;
//    if (thingie)   [viewController frequencyLabel].text = [NSString stringWithFormat:@"%i",thingie];
    //free(bufferList.mBuffers[0].mData);
    
    return noErr;
}

OSStatus RenderTone(
                    void *inRefCon,
                    AudioUnitRenderActionFlags 	*ioActionFlags,
                    const AudioTimeStamp 		*inTimeStamp,
                    UInt32 						inBusNumber,
                    UInt32 						inNumberFrames,
                    AudioBufferList 			*ioData)

{
    // Fixed amplitude is good enough for our purposes
    const double amplitude = .45;
    
    // Get the tone parameters out of the view controller
    AudioViewController *viewController = (__bridge AudioViewController *)inRefCon;
    double theta = viewController->theta;
    double theta_increment = 2.0 * M_PI * viewController->frequency / viewController->sampleRate;
    
    // This is a mono tone generator so we only need the first buffer
    const int channel = 0;
    Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
    int *rchnl = (int *)ioData->mBuffers[1].mData;

  
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++)
    {
        
#ifdef SQUARE_GEN
        if ((theta < (1.0 * M_PI)) && (theta > 0.0))
        {
            //positive
            buffer[frame] = amplitude;
        }
        if ((theta < (2.0 * M_PI)) && (theta > (1.0 * M_PI)))
        {
            //negative
            buffer[frame] = -amplitude;
        }
#else
         buffer[frame] = sin(theta) * amplitude;
#endif
        theta += theta_increment;
        if (theta > 2.0 * M_PI)
        {
            theta -= 2.0 * M_PI;
        }
        if ([viewController->myIntegers count] != 0)
        {
          rchnl[frame] = (int) viewController->myIntegers[0];
          [viewController->myIntegers removeObjectAtIndex:0];
          viewController.cmdstatus.text = @"";
          viewController.cmdstatus.text = @"sent!";
          NSLog(@"sent");
        }
    }
    
    // Store the theta back in the view controller
    viewController->theta = theta;
    
    return noErr;
}

void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
    if(inClientData){
        AudioViewController *viewController = (__bridge AudioViewController *)inClientData;
        [viewController stop];
    }
    
    
}

@implementation AudioViewController

@synthesize frequencySlider;
@synthesize playButton;
@synthesize frequencyLabel;
@synthesize sampleLabel;


//input streaming

-(void)initializeAudio
{
    OSStatus status;
    
    // We define the audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output; // we want to ouput
    desc.componentSubType = kAudioUnitSubType_RemoteIO; // we want in and ouput
    desc.componentFlags = 0; // must be zero
    desc.componentFlagsMask = 0; // must be zero
    desc.componentManufacturer = kAudioUnitManufacturer_Apple; // select provider
    
    // find the AU component by description
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // create audio unit by component
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    
//    [self hasError:status:__FILE__:__LINE__];
    
    // define that we want record io on the input bus
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO, // use io
                                  kAudioUnitScope_Input, // scope to input
                                  kInputBus, // select input bus (1)
                                  &flag, // set flag
                                  sizeof(flag));
//    [self hasError:status:__FILE__:__LINE__];
    
    // define that we want play on io on the output bus
  
   /*
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO, // use io
                                  kAudioUnitScope_Output, // scope to output
                                  kOutputBus, // select output bus (0)
                                  &flag, // set flag
                                  sizeof(flag));
                                  */
    
//    [self hasError:status:__FILE__:__LINE__];
    
    /*
     We need to specifie our format on which we want to work.
     We use Linear PCM cause its uncompressed and we work on raw data.
     for more informations check.
     
     We want 16 bits, 2 bytes per packet/frames at 44khz
     */

    
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate         = IN_SAMPLE_RATE;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mChannelsPerFrame   = 1;
    audioFormat.mBitsPerChannel     = 8*sizeof(IN_SAMPLE_TYPE);//16;
    audioFormat.mBytesPerPacket     = sizeof(IN_SAMPLE_TYPE);//2;
    audioFormat.mBytesPerFrame      = sizeof(IN_SAMPLE_TYPE);//2;
     
    /*
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate         = IN_SAMPLE_RATE;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
    audioFormat.mBytesPerPacket     = 4;
    audioFormat.mFramesPerPacket    = 4;
    audioFormat.mBytesPerFrame      = 1;
    audioFormat.mChannelsPerFrame   = 1;
    audioFormat.mBitsPerChannel     = 32;
    */
    // set the format on the output stream
  
    /*
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    */
    
//    [self hasError:status:__FILE__:__LINE__];
  
  
    // set the format on the input stream
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,        //kOutputBus
                                  &audioFormat,
                                  sizeof(audioFormat));
  
  NSAssert1(status == noErr, @"Error setting thingie 2: %d", status);
//    [self hasError:status:__FILE__:__LINE__];
    
    /**
     We need to define a callback structure which holds
     a pointer to the recordingCallback and a reference to
     the audio processor object
     */
    AURenderCallbackStruct callbackStruct;
    
    // set recording callback
    callbackStruct.inputProc = recordingCallback; // recordingCallback pointer
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    
    // set input callback to recording callback on the input bus
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
  NSAssert1(status == noErr, @"Error setting thingie: %d", status);
  
  
    //[self hasError:status:__FILE__:__LINE__];
    
    /*
     We do the same on the output stream to hear what is coming
     from the input stream
     */
    //callbackStruct.inputProc = playbackCallback;
    //callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    
    // set playbackCallback as callback on our renderer for the output bus
  
    /*
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global, //kAudioUnitScope_Global
                                  kOutputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    
    */
    //[self hasError:status:__FILE__:__LINE__];
    
    // reset flag to 0
    flag = 0;
    
    /*
     we need to tell the audio unit to allocate the render buffer,
     that we can directly write into it.
     */
    /*
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
                                  */
  
  
  
    /*
     we set the number of channels to mono and allocate our block size to
     1024 bytes.
     */

/*
    audioBuffer.mNumberChannels = 1;
    audioBuffer.mDataByteSize = BYTES_PER_BLOCK;
    audioBuffer.mData = malloc( BYTES_PER_BLOCK );
    */
    
    // Initialize the Audio Unit and cross fingers =)
 
    status = AudioUnitInitialize(audioUnit);
    
    NSLog(@"Started");
    
}


#pragma mark processing


-(void)processBuffer:(AudioBuffer*) audioBuffer
{
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        //Type must match packet size
        IN_SAMPLE_TYPE *editBuffer = audioBuffer->mData;
        NSMutableArray *myarray = [[NSMutableArray alloc] init];
        
        // loop over every packet
        for (int nb = 0; nb < (audioBuffer->mDataByteSize / 2); nb++) {
            
            // we check if the gain has been modified to save resoures
            if (_gain != 0) {
                // we need more accuracy in our calculation so we calculate with doubles
                double gainSample = ((double)editBuffer[nb])/32767.0;
                //our signal range cant be higher or lesser -1.0/1.0 for playback example
                gainSample = (gainSample < -1.0) ? -1.0 : (gainSample > 1.0) ? 1.0 : gainSample;
                // multiply the new signal back to short
                gainSample = gainSample * 32767.0;
                // write calculate sample back to the buffer
                //            editBuffer[nb] = (SInt16)gainSample;
               
                
                if(_current_sample_index <= 0)
                {
                    
                    //_current_sample_index = 32;
                    _string_sample = [_string_sample substringFromIndex:1];
                    sampleLabel.text = _string_sample;//[NSString stringWithFormat:@"%x",_current_sample];
                    //_current_sample = 0;
                    //_string_sample = @"";
                }
                else _current_sample_index--;
                if(editBuffer[nb] > threshold)
                {
                    //_current_sample |=  1 << _current_sample_index;
                    _string_sample = [_string_sample stringByAppendingString:@"1"];
                }
                else _string_sample = [_string_sample stringByAppendingString:@"0"];
                [myarray addObject:[NSNumber numberWithInt:editBuffer[nb]]];
            }
        }
        [myarray removeAllObjects];
        
    }];

}

- (IBAction)sliderChanged:(id)sender
{
    UISlider * slider = (UISlider *)sender;
    threshold = 0.01*(slider.value - .5);
    frequencyLabel.text = [NSString stringWithFormat:@"%4.4f", threshold];
//    frequency = 10000 + 10000*(slider.value - 0.5);

    //    if(slider.value > .5) frequency = 100000*slider.value;
//    else    frequency = (10000*slider.value);
 //   frequencyLabel.text = [NSString stringWithFormat:@"%4.4f", frequency];
    //sampleLabel.text =[NSString stringWithFormat:@"%4.1f Hz", frequency];
}

- (void)createToneUnit
{
    // Configure the search parameters to find the default playback output unit
    // (called the kAudioUnitSubType_RemoteIO on iOS but
    // kAudioUnitSubType_DefaultOutput on Mac OS X)
    AudioComponentDescription defaultOutputDescription;
    defaultOutputDescription.componentType = kAudioUnitType_Output;
    defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    defaultOutputDescription.componentFlags = 0;
    defaultOutputDescription.componentFlagsMask = 0;
    
    // Get the default playback output unit
    AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
    NSAssert(defaultOutput, @"Can't find default output");
    
    // Create a new unit based on this that we'll use for output
    OSErr err = AudioComponentInstanceNew(defaultOutput, &toneUnit);
    NSAssert1(toneUnit, @"Error creating unit: %hd", err);
    
    // Set our tone rendering function on the unit
    AURenderCallbackStruct input;
    input.inputProc = RenderTone;
    input.inputProcRefCon = (__bridge void * _Nullable)(self);
    err = AudioUnitSetProperty(toneUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
    NSAssert1(err == noErr, @"Error setting callback: %ld", err);
    
    // Set the format to 32 bit, single channel, floating point, linear PCM
    const int four_bytes_per_float = 4;
    const int eight_bits_per_byte = 8;
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate = sampleRate;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags =
    kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    streamFormat.mBytesPerPacket = four_bytes_per_float;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mBytesPerFrame = 2*four_bytes_per_float;
    streamFormat.mChannelsPerFrame = 2;
    streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
    err = AudioUnitSetProperty (toneUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
    //NSAssert1(err == noErr, @"Error setting stream format: %ld", err);
}

- (IBAction)send:(id)sender {
  UIButton * selectedButton = (UIButton *)sender;
  if (toneUnit)
  {
    //just push to the buffer because rendertone is already running when circuit is powered up
    
    //[selectedButton setTitle:NSLocalizedString(@"sending...", nil) forState:0];
    _cmdstatus.text = @"";
    _cmdstatus.text = @"sending...";
    //NSLog(@"sending...");
    [myIntegers addObject:[NSNumber numberWithInteger:0xA]];
    [myIntegers addObject:[NSNumber numberWithInteger:0x5]];
    //NSLog(@"done sending");
    //[selectedButton setTitle:NSLocalizedString(@"Send", nil) forState:0];
  }
  else
  {
    //cannot send commands if circuit is not powered up
    _cmdstatus.text = @"failed!";
  }

}

- (IBAction)play:(id)sender
{
    UIButton * selectedButton = (UIButton *)sender;
    if (toneUnit)
    {
        AudioOutputUnitStop(toneUnit);
        AudioUnitUninitialize(toneUnit);
        AudioComponentInstanceDispose(toneUnit);
        toneUnit = nil;
        
        [selectedButton setTitle:NSLocalizedString(@"Play", nil) forState:0];
    }
    else
    {
        [self createToneUnit];
        
        // Stop changing parameters on the unit
        OSErr err = AudioUnitInitialize(toneUnit);
        NSAssert1(err == noErr, @"Error initializing unit: %ld", err);
        
        // Start playback
        err = AudioOutputUnitStart(toneUnit);
        NSAssert1(err == noErr, @"Error starting unit: %ld", err);
        
        [selectedButton setTitle:NSLocalizedString(@"Stop", nil) forState:0];
    }
}

- (IBAction) record: (id) sender
{
        UIButton * selectedButton = (UIButton *)sender;
    if(audioUnit) {}
        else {}
    if(recordState.recording)
    {
        recordState.recording = false;
        OSStatus status = AudioOutputUnitStop(audioUnit);
        [selectedButton setTitle:NSLocalizedString(@"Record", nil) forState:0];
        
    }
    else
    {
        recordState.recording = true;
        [selectedButton setTitle:NSLocalizedString(@"Stop", nil) forState:0];
        OSStatus status = AudioOutputUnitStart(audioUnit);
    }
    
}

- (void)stop
{
    if (toneUnit)
    {
        [self play:playButton];
    }
    AudioOutputUnitStop(audioUnit);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeAudio]; //input stream
  
    myIntegers = [NSMutableArray array];
    _string_sample = @"";
    frequency = 18000;
    _current_sample_index = 31;
    _gain = 1;
    [self sliderChanged:frequencySlider];
    sampleRate = OUT_SAMPLE_RATE; //for output
    
    OSStatus result = AudioSessionInitialize(NULL, NULL, ToneInterruptionListener, (__bridge void *)(self));
    if (result == kAudioSessionNoError)
    {
        UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
        AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    }
    AudioSessionSetActive(true);
}

- (void)viewDidUnload {
    self.frequencyLabel = nil;
    self.sampleLabel = nil;
    self.playButton = nil;
    self.frequencySlider = nil;
    
    AudioSessionSetActive(false);
}


@end