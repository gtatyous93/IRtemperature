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

#define FREQUENCY 1000
#define SAMPLE_RATE 44100
#define DURATION 50.0
#define FILENAME_FORMAT @"%0.3f-square.aif"

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














///-------------------------------

//
//  AudioRecorderAppDelegate.m
//  AudioRecorder
//
//  Copyright TrailsintheSand.com 2008. All rights reserved.
//



// Declare C callback functions
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
    /*
     [labelStatus release];
     [buttonRecord release];
     [buttonPlay release];
     [window release];
     [super dealloc];
     */
}

- (BOOL)getFilename:(char*)buffer maxLenth:(int)maxBufferLength
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString* docDir = [paths objectAtIndex:0];
    
    NSString* file = [docDir stringByAppendingString:@"/recording.aif"];
    return [file getCString:buffer maxLength:maxBufferLength encoding:NSUTF8StringEncoding];
}

- (void) ConfigAudio
{
    //TODO: perform this only when audio jack device is connected, and periodically check if it needs connecting
    /*
    AudioSessionInitialize (NULL, NULL, interruptionListenerCallback, (__bridge void *)(self));
    
    // before instantiating the recording audio queue object,
    //	set the audio session category
    UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
    AudioSessionSetProperty (kAudioSessionProperty_AudioCategory,
                             sizeof (sessionCategory),
                             &sessionCategory);
    
    //    recognizer = [[FSKRecognizer alloc] init];
    _recognizer = [[BinaryRecognizer alloc] init ];
    _analyzer = [[AudioSignalAnalyzer alloc] init];
    [_analyzer addRecognizer:_recognizer];
    //    [_recognizer addReceiver:terminalController];
    //    [_recognizer addReceiver:typeController];
    //    [self buildScanCodes];
    _generator = [[AudioSignalGenerator alloc] init];
    
    AudioSessionSetActive (true);
    //[_analyzer record];
    [_generator play];
    */
}

- (void) TestAudioConfig
{
    /*
    _analyzer = [[AudioSignalAnalyzer alloc] init]; //the recording audio queue [ana queueObject]
    _generator = [[AudioSignalGenerator alloc] init]; //the playback audio queue [gen queueObject]
    
    [_generator setupAudioQueueBuffers];
     */
    
}


- (IBAction)tone:(id)sender
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


@end