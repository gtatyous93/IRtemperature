//
//  AudioViewController.m
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/19/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioViewController.h"





void interruptionListenerCallback (
                                   void	*inUserData,
                                   UInt32	interruptionState
                                   ) {
    // This callback, being outside the implementation block, needs a reference
    //	to the AudioViewController object

    AudioViewController *controller = (__bridge AudioViewController*) inUserData;
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

@implementation AudioViewController


@synthesize analyzer = _analyzer;
@synthesize generator = _generator;
@synthesize TransmitterAudioQUeue = _TransmitterAudioQUeue;
@synthesize ReceiverAudioQUeue = _ReceiverAudioQUeue;


- (void) ConfigAudio
{
    //TODO: perform this only when audio jack device is connected, and periodically check if it needs connecting
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
}

- (void) TestAudioConfig
{
    _analyzer = [[AudioSignalAnalyzer alloc] init]; //the recording audio queue [ana queueObject]
    _generator = [[AudioSignalGenerator alloc] init]; //the playback audio queue [gen queueObject]
    
    [_generator setupAudioQueueBuffers];
    
}


- (IBAction)tone:(id)sender
{

    //Button press: begin playing tone
    if([_generator isRunning])
    {
        [sender setTitle:@"Stop"];
        [_generator stop];
    }
    else
    {
        [sender setTitle:@"Play"];
        [_generator play];
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
    [self ConfigAudio];
    
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