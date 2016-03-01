//
//  AudioViewController.m
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/19/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioViewController.h"

/*
void interruptionListenerCallback (
                                   void	*inUserData,
                                   UInt32	interruptionState
                                   ) {
    // This callback, being outside the implementation block, needs a reference
    //	to the AudioViewController object

    AudioViewController *controller = (__bridge AudioViewController*) inUserData; //catch bad access exception, occurs when closing phone
    if (interruptionState == kAudioSessionBeginInterruption) {
        
        NSLog (@"Interrupted. Stopping recording/playback.");
        
        [controller.analyzer stop];
        [controller.generator pause];
    } else if (interruptionState == kAudioSessionEndInterruption) {
        // if the interruption was removed, resume recording
        [controller.analyzer record];
        [controller.generator resume];
    }
}
 */


/*
NSURL* squareURL;

static void generate_file(void)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:[documentsDirectory stringByAppendingPathComponent:@"Documents"] withIntermediateDirectories:NO attributes:nil error:&error];
    
    double hz = FREQUENCY;
    assert (hz > 0);
    NSLog (@"generating %f hz tone", hz);
    NSString *fileName = @"SQUARE.aif";//[NSString stringWithFormat: FILENAME_FORMAT, hz];
    //        NSString *filePath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent: fileName];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSURL *fileURL = [NSURL fileURLWithPath: filePath];
    // Prepare the format
    AudioStreamBasicDescription asbd;
    memset(&asbd, 0, sizeof(asbd));
    asbd.mSampleRate = SAMPLE_RATE;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    asbd.mBitsPerChannel = 16;
    asbd.mChannelsPerFrame = 1;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = 2; asbd.mBytesPerPacket = 2;
    // Set up the file
    AudioFileID audioFile;
    OSStatus audioErr = noErr;
    audioErr = AudioFileCreateWithURL((__bridge CFURLRef)fileURL,
                                      kAudioFileAIFFType,
                                      &asbd,
                                      kAudioFileFlags_EraseFile,
                                      &audioFile);
    assert (audioErr == noErr);
    // Start writing samples
    long maxSampleCount = SAMPLE_RATE;
    long sampleCount = 0;
    UInt32 bytesToWrite = 2;
    double wavelengthInSamples = SAMPLE_RATE / hz;
    while (sampleCount < maxSampleCount) {
        for (int i=0; i<wavelengthInSamples; i++) {
            // Square wave
            SInt16 sample;
            if (i < wavelengthInSamples/2) {
                sample = CFSwapInt16HostToBig (SHRT_MAX); } else {
                    sample = CFSwapInt16HostToBig (SHRT_MIN); }
            audioErr = AudioFileWriteBytes(audioFile, false,
                                           sampleCount*2, &bytesToWrite, &sample);
            assert (audioErr == noErr); sampleCount++;
            
            //NSLog (@"wrote %ld samples", sampleCount);
        }
    }
    audioErr = AudioFileClose(audioFile); assert (audioErr == noErr);
    squareURL = fileURL;
}

@implementation AudioViewController


@synthesize analyzer = _analyzer;
@synthesize generator = _generator;
@synthesize TransmitterAudioQUeue = _TransmitterAudioQUeue;
@synthesize ReceiverAudioQUeue = _ReceiverAudioQUeue;

*/





///-------------------------------

OSStatus playbackCallback(
                          void *inRefCon,
                          AudioUnitRenderActionFlags 	*ioActionFlags,
                          const AudioTimeStamp 		*inTimeStamp,
                          UInt32 						inBusNumber,
                          UInt32 						inNumberFrames,
                          AudioBufferList 			*ioData)
{
    return noErr;
}

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
    
    /**
     This is the reference to the object who owns the callback.
     */
    if(!inRefCon) return 0;
    AudioViewController *viewController = (__bridge AudioViewController*) inRefCon;
    
    /**
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
     [viewController processBuffer:&buffer];
    
    
    
    
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
    const double amplitude = .5;
    
    // Get the tone parameters out of the view controller
    AudioViewController *viewController = (__bridge AudioViewController *)inRefCon;
    double theta = viewController->theta;
    double theta_increment = 2.0 * M_PI * viewController->frequency / viewController->sampleRate;
    
    // This is a mono tone generator so we only need the first buffer
    const int channel = 0;
    Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
    
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
    }
    
    // Store the theta back in the view controller
    viewController->theta = theta;
    
    return noErr;
}

void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
    AudioViewController *viewController =
    (__bridge AudioViewController *)inClientData;
    
    [viewController stop];
    
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
   
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO, // use io
                                  kAudioUnitScope_Output, // scope to output
                                  kOutputBus, // select output bus (0)
                                  &flag, // set flag
                                  sizeof(flag));
    
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
    
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    
    
//    [self hasError:status:__FILE__:__LINE__];
    
    // set the format on the input stream
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,        //kOutputBus
                                  &audioFormat,
                                  sizeof(audioFormat));
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
    
    //[self hasError:status:__FILE__:__LINE__];
    
    /*
     We do the same on the output stream to hear what is coming
     from the input stream
     */
    //callbackStruct.inputProc = playbackCallback;
    //callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    
    // set playbackCallback as callback on our renderer for the output bus
    
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global, //kAudioUnitScope_Global
                                  kOutputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    
    
    //[self hasError:status:__FILE__:__LINE__];
    
    // reset flag to 0
    flag = 0;
    
    /*
     we need to tell the audio unit to allocate the render buffer,
     that we can directly write into it.
     */
    
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    
    
    /*
     we set the number of channels to mono and allocate our block size to
     1024 bytes.
     */

    audioBuffer.mNumberChannels = 1;
    audioBuffer.mDataByteSize = BYTES_PER_BLOCK;
    audioBuffer.mData = malloc( BYTES_PER_BLOCK );
    
    // Initialize the Audio Unit and cross fingers =)
 
    status = AudioUnitInitialize(audioUnit);
    
    NSLog(@"Started");
    
}


#pragma mark processing

/*
-(void)processBuffer: (AudioBufferList*) audioBufferList
{
    AudioBuffer sourceBuffer = audioBufferList->mBuffers[0];
    
    // we check here if the input data byte size has changed
    if (audioBuffer.mDataByteSize != sourceBuffer.mDataByteSize) {
        // clear old buffer
        free(audioBuffer.mData);
        // assing new byte size and allocate them on mData
        audioBuffer.mDataByteSize = sourceBuffer.mDataByteSize;
        audioBuffer.mData = malloc(sourceBuffer.mDataByteSize);
    }
 */
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
/*
 
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        
        int *data_sample = audioBufferList->mBuffers[0].mData;
        //00 2a 44 16, 00 f6 c2 16,
        //             00 e2 1f 18,
        //82 59, c4 13, c4 91, 00 00
        
        //data_sample = (data_sample&0x00FFFF00) >> 8;
//        _min_sample = MIN(_min_sample,data_sample);
//        _max_sample = MAX(_min_sample,data_sample);
//        _mid_voltage = (_max_sample - _min_sample)/2;
        
        if(_current_sample_index ==0) {
            _current_sample_index = 31;
            //update on main thread output window
            sampleLabel.text = [NSString stringWithFormat:@"%x",_current_sample];
            _current_sample = 0;
        }
        else _current_sample_index--;
        
        int temp;
        if( data_sample > _mid_voltage) temp = 1;
        else temp = 0;
       //int temp = (((data_sample&0x000000FF) ? 1 : 0 ) << _current_sample_index);
        
        _current_sample |= temp<<_current_sample_index;
        //thingie = (thingie&0x00FFFF00)>>8;

        //Your code goes in here
        //NSLog(@"Main Thread Code");
        
    }];
    */
    
    
    /**
     Here we modify the raw data buffer now.
     In my example this is a simple input volume gain.
     iOS 5 has this on board now, but as example quite good.
     */
    /*
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        //Type must match packet size
        int bit_index = 32;
        IN_SAMPLE_TYPE *editBuffer = audioBufferList->mBuffers[0].mData;
        NSMutableArray *myarray = [[NSMutableArray alloc] init];
        
        // loop over every packet
        for (int nb = 0; nb < (audioBufferList->mBuffers[0].mDataByteSize / 2); nb++) {
            
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
                if(editBuffer[nb] > 0)
                {
                    _current_sample |=  1 << bit_index;
                }
                bit_index--;
                if(bit_index <= 0)
                {
                    
                    bit_index = 32;
                    sampleLabel.text = [NSString stringWithFormat:@"%x",_current_sample];
                    _current_sample = 0;
                }
                [myarray addObject:[NSNumber numberWithInt:editBuffer[nb]]];
            }
        }
        bit_index = 0;
        [myarray removeAllObjects];
        
    }];
    // copy incoming audio data to the audio buffer
    
    //memcpy(audioBuffer.mData, audioBufferList->mBuffers[0].mData, audioBufferList->mBuffers[0].mDataByteSize);
    
}
     */




//






- (IBAction)sliderChanged:(id)sender
{
    UISlider * slider = (UISlider *)sender;
    threshold = 0.01*(slider.value - .5);
//    frequency = 15000 + 10000*(slider.value - 0.5);
//    if(slider.value > .5) frequency = 100000*slider.value;
//    else    frequency = (10000*slider.value);
    frequencyLabel.text = [NSString stringWithFormat:@"%4.4f", threshold];
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
    streamFormat.mBytesPerFrame = four_bytes_per_float;
    streamFormat.mChannelsPerFrame = 1;
    streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
    err = AudioUnitSetProperty (toneUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
    NSAssert1(err == noErr, @"Error setting stream format: %ld", err);
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
    
    _string_sample = @"";
    frequency = 18000;
    _current_sample_index = 31;
    _gain = 1;
    [self sliderChanged:frequencySlider];
    sampleRate = OUT_SAMPLE_RATE; //for output
    
    OSStatus result = AudioSessionInitialize(NULL, NULL, ToneInterruptionListener, (__bridge void *)(self));
    if (result == kAudioSessionNoError)
    {
        UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
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



///-------------------------------

//
//  AudioRecorderAppDelegate.m
//  AudioRecorder
//
//  Copyright TrailsintheSand.com 2008. All rights reserved.
//



// Declare C callback functions
/*
void AudioInputCallback(void * inUserData,  // Custom audio metadata
                        AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer,
                        const AudioTimeStamp * inStartTime,
                        UInt32 inNumberPacketDescriptions,
                        const AudioStreamPacketDescription * inPacketDescs);

void AudioOutputCallback(void * inUserData,
                         AudioQueueRef outAQ,
                         AudioQueueBufferRef outBuffer);



// Takes a filled buffer and writes it to disk, "emptying" the buffer
void AudioInputCallback(void * inUserData,
                        AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer,
                        const AudioTimeStamp * inStartTime,
                        UInt32 inNumberPacketDescriptions,
                        const AudioStreamPacketDescription * inPacketDescs)
{
    RecordState * recordState = (RecordState*)inUserData;
    if (!recordState->recording)
    {
        printf("Not recording, returning\n");
    }
    
    // if (inNumberPacketDescriptions == 0 && recordState->dataFormat.mBytesPerPacket != 0)
    // {
    //     inNumberPacketDescriptions = inBuffer->mAudioDataByteSize / recordState->dataFormat.mBytesPerPacket;
    // }
    
    printf("Writing buffer %lld\n", recordState->currentPacket);
    OSStatus status = AudioFileWritePackets(recordState->audioFile,
                                            false,
                                            inBuffer->mAudioDataByteSize,
                                            inPacketDescs,
                                            recordState->currentPacket,
                                            &inNumberPacketDescriptions,
                                            inBuffer->mAudioData);
    if (status == 0)
    {
        recordState->currentPacket += inNumberPacketDescriptions;
    }
    
    AudioQueueEnqueueBuffer(recordState->queue, inBuffer, 0, NULL);
}

// Fills an empty buffer with data and sends it to the speaker
void AudioOutputCallback(void * inUserData,
                         AudioQueueRef outAQ,
                         AudioQueueBufferRef outBuffer)
{
    PlayState* playState = (PlayState*)inUserData;
    if(!playState->playing)
    {
        printf("Not playing, returning\n");
        return;
    }
    
    printf("Queuing buffer %lld for playback\n", playState->currentPacket);
    
    AudioStreamPacketDescription* packetDescs;
    
    UInt32 bytesRead;
    UInt32 numPackets = 8000;
    OSStatus status;
    status = AudioFileReadPackets(playState->audioFile,
                                  false,
                                  &bytesRead,
                                  packetDescs,
                                  playState->currentPacket,
                                  &numPackets,
                                  outBuffer->mAudioData);
    
    if (numPackets)
    {
        outBuffer->mAudioDataByteSize = bytesRead;
        status = AudioQueueEnqueueBuffer(playState->queue,
                                         outBuffer,
                                         0,
                                         packetDescs);
        
        playState->currentPacket += numPackets;
    }
    else
    {
        if (playState->playing)
        {
            AudioQueueStop(playState->queue, false);
            AudioFileClose(playState->audioFile);
            playState->playing = false;
        }
        
        AudioQueueFreeBuffer(playState->queue, outBuffer);
    }
    
}

- (void)setupAudioFormat:(AudioStreamBasicDescription*)format
{
    format->mSampleRate = 8000.0;
    format->mFormatID = kAudioFormatLinearPCM;
    format->mFramesPerPacket = 1;
    format->mChannelsPerFrame = 1;//default 1
    format->mBytesPerFrame = 2;
    format->mBytesPerPacket = 2;
    format->mBitsPerChannel = 16;
    format->mReserved = 0;
    format->mFormatFlags = kLinearPCMFormatFlagIsBigEndian     |
    kLinearPCMFormatFlagIsSignedInteger |
    kLinearPCMFormatFlagIsPacked;
}

- (void)recordPressed:(id)sender
{
    if (!playState.playing)
    {
        if (!recordState.recording)
        {
            printf("Starting recording\n");
            [self startRecording];
        }
        else
        {
            printf("Stopping recording\n");
            [self stopRecording];
        }
    }
    else
    {
        printf("Can't start recording, currently playing\n");
    }
}

- (void)playPressed:(id)sender
{
    if (!recordState.recording)
    {
        if (!playState.playing)
        {
            printf("Starting playback\n");
            [self startPlayback];
        }
        else
        {
            printf("Stopping playback\n");
            [self stopPlayback];
        }
    }
}

- (void)startRecording
{
    [self setupAudioFormat:&recordState.dataFormat];
    
    recordState.currentPacket = 0;
    
    OSStatus status;
    status = AudioQueueNewInput(&recordState.dataFormat,
                                AudioInputCallback,
                                &recordState,
                                CFRunLoopGetCurrent(),
                                kCFRunLoopCommonModes,
                                0,
                                &recordState.queue);
    
    if (status == 0)
    {
        // Prime recording buffers with empty data
        for (int i = 0; i < NUM_BUFFERS; i++)
        {
            AudioQueueAllocateBuffer(recordState.queue, 16000, &recordState.buffers[i]);
            AudioQueueEnqueueBuffer (recordState.queue, recordState.buffers[i], 0, NULL);
        }
        
        status = AudioFileCreateWithURL(fileURL,
                                        kAudioFileAIFFType,
                                        &recordState.dataFormat,
                                        kAudioFileFlags_EraseFile,
                                        &recordState.audioFile);
        if (status == 0)
        {
            recordState.recording = true;
            status = AudioQueueStart(recordState.queue, NULL);
            if (status == 0)
            {
                labelStatus.text = @"Recording";
            }
        }
    }
    
    if (status != 0)
    {
        [self stopRecording];
        labelStatus.text = @"Record Failed";
    }
}

- (void)stopRecording
{
    recordState.recording = false;
    
    AudioQueueStop(recordState.queue, true);
    for(int i = 0; i < NUM_BUFFERS; i++)
    {
        AudioQueueFreeBuffer(recordState.queue, recordState.buffers[i]);
    }
    
    AudioQueueDispose(recordState.queue, true);
    AudioFileClose(recordState.audioFile);
    labelStatus.text = @"Idle";
}

- (void)startPlayback
{
    
    NSURL *_squareURL = squareURL;
    playState.currentPacket = 0;
    
    [self setupAudioFormat:&playState.dataFormat];
    
    OSStatus status;
    status = AudioFileOpenURL((__bridge CFURLRef _Nonnull)(squareURL), kAudioFileReadPermission, kAudioFileAIFFType, &playState.audioFile);
    if (status == 0)
    {
        status = AudioQueueNewOutput(&playState.dataFormat,
                                     AudioOutputCallback,
                                     &playState,
                                     CFRunLoopGetCurrent(),
                                     kCFRunLoopCommonModes,
                                     0,
                                     &playState.queue);
        
        if (status == 0)
        {
            // Allocate and prime playback buffers
            playState.playing = true;
            for (int i = 0; i < NUM_BUFFERS && playState.playing; i++)
            {
                AudioQueueAllocateBuffer(playState.queue, 16000, &playState.buffers[i]);
                AudioOutputCallback(&playState, playState.queue, playState.buffers[i]);
            }
            
            status = AudioQueueStart(playState.queue, NULL);
            if (status == 0)
            {
                labelStatus.text = @"Playing";
            }
        }
    }
    
    if (status != 0)
    {
        [self stopPlayback];
        labelStatus.text = @"Play failed";
    }
}

- (void)stopPlayback
{
    playState.playing = false;
    
    for(int i = 0; i < NUM_BUFFERS; i++)
    {
        AudioQueueFreeBuffer(playState.queue, playState.buffers[i]);
    }
    
    AudioQueueDispose(playState.queue, true);
    AudioFileClose(playState.audioFile);
}

- (void)dealloc
{
    
    CFRelease(fileURL);
    CFRelease((__bridge CFTypeRef)(squareURL));
 
    // [labelStatus release];
    // [buttonRecord release];
    // [buttonPlay release];
    // [window release];
    // [super dealloc];

}

- (BOOL)getFilename:(char*)buffer maxLenth:(int)maxBufferLength
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString* docDir = [paths objectAtIndex:0];
    
    NSString* file = [docDir stringByAppendingString:@"/recording.aif"];
    return [file getCString:buffer maxLength:maxBufferLength encoding:NSUTF8StringEncoding];
}

- (IBAction)play:(id)sender
{

    UIButton *button = (UIButton *)sender;
    if (!recordState.recording)
    {
        if (!playState.playing)
        {
            button.enabled = FALSE;
            [button setTitle:@"Stop" forState:UIControlStateNormal];
            button.enabled = TRUE;
            printf("Starting playback\n");
            [self startPlayback];
        }
        else
        {
            button.enabled = FALSE;
            [button setTitle:@"Play" forState:UIControlStateNormal];
            button.enabled = TRUE;
            printf("Stopping playback\n");
            [self stopPlayback];
        }
    }
    [sender setNeedsLayout];
}

- (IBAction) record: (id) sender
{
    if (!playState.playing)
    {
        if (!recordState.recording)
        {
            printf("Starting recording\n");
            [self startRecording];
        }
        else
        {
            printf("Stopping recording\n");
            [self stopRecording];
        }
    }
    else
    {
        printf("Can't start recording, currently playing\n");
    }
}

//UIView inherited methods

- (void)didReceiveMemoryWarning
{
    
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


- (void)viewDidLoad
{
    //Called after the controller's view is loaded into memory
    
    [super viewDidLoad];
    char path[256];
    [self getFilename:path maxLenth:sizeof path];
    generate_file();
    fileURL = CFURLCreateFromFileSystemRepresentation(NULL, (UInt8*)path, strlen(path), false);
    
    // Init state variables
    playState.playing = false;
    recordState.recording = false;

//    [self ConfigAudio];
    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
 */


@end