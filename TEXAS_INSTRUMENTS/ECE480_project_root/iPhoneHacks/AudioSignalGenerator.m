//
//  AudioSignalGenerator.m
//  FSK Terminal
//
//  Created by George Dean on 1/6/09.
//  Copyright 2009 Perceptive Development. All rights reserved.
//

#include <AudioToolbox/AudioToolbox.h>
#import "AudioQueueObject.h"
#import "AudioSignalGenerator.h"

#define NUM_CHANNELS 2
#define NUM_BUFFERS 3
#define BUFFER_SIZE 4096
#define SAMPLE_TYPE short
#define MAX_NUMBER 32767
#define SAMPLE_RATE 44100

typedef void (*AudioQueueOutputCallback)(
void * __nullable       inUserData,
AudioQueueRef           inAQ,
AudioQueueBufferRef     inBuffer);

#pragma mark - audio queue -

static void playbackCallback (
							  void					*inUserData,
							  AudioQueueRef			inAQ,
							  AudioQueueBufferRef	inBuffer
) {
	// This is not a Cocoa thread, it needs a manually allocated pool
//    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// This callback, being outside the implementation block, needs a reference to the AudioSignalGenerator object
	AudioSignalGenerator *player = (__bridge AudioSignalGenerator *) inUserData;
	if ([player stopped]) return;
//    if (!inBuffer) return;
	//[player fillBuffer:inBuffer->mAudioData];
    int count = 0;
    
    SAMPLE_TYPE *casted_buffer = (SAMPLE_TYPE *)inBuffer->mAudioData;
    
    for (int i = 0; i < BUFFER_SIZE / sizeof(SAMPLE_TYPE); i += NUM_CHANNELS)
    {
        double float_sample = sin(count / 10.0);
        
        SAMPLE_TYPE int_sample = (SAMPLE_TYPE)(float_sample * MAX_NUMBER);
        
        for (int j = 0; j < NUM_CHANNELS; j++)
        {
            casted_buffer[i + j] = int_sample;
        }
        
        count++;
    }
    
    
	
    

	AudioQueueEnqueueBuffer (
								 inAQ,
								 inBuffer,
								 player.bufferPacketCount,
								 player.packetDescriptions
								 );
	
//	[pool release];
}

@implementation AudioSignalGenerator


@synthesize packetDescriptions;
@synthesize bufferByteSize;
@synthesize bufferPacketCount;
@synthesize stopped;
@synthesize audioPlayerShouldStopImmediately;


- (id) init {
	
	self = [super init];
	
	if (self != nil) {
		[self setupAudioFormat];
		[self setupPlaybackAudioQueueObject];
		self.stopped = NO;
		self.audioPlayerShouldStopImmediately = NO;
	}
	
	return self;
}

- (void) setupAudioFormat
{
    
    audioFormat.mSampleRate       = SAMPLE_RATE;
    audioFormat.mFormatID         = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mBitsPerChannel   = 8 * sizeof(SAMPLE_TYPE);
    audioFormat.mChannelsPerFrame = NUM_CHANNELS;
    audioFormat.mBytesPerFrame    = sizeof(SAMPLE_TYPE) * NUM_CHANNELS;
    audioFormat.mFramesPerPacket  = 1;
    audioFormat.mBytesPerPacket   = audioFormat.mBytesPerFrame * audioFormat.mFramesPerPacket;
    audioFormat.mReserved         = 0;
    
    
}

- (void) fillBuffer: (void*) buffer
{


}

- (void) setupPlaybackAudioQueueObject {
	
	// create the playback audio queue object
	AudioQueueNewOutput (&audioFormat,                  //input format
						 playbackCallback,              //callback process
						 (__bridge void * _Nullable)(self), //in user
						 NULL,        //callback run loop: CFRunLoopGetCurrent ()
						 NULL,         //callback runloop mode: kCFRunLoopCommonModes
						 0,								//flags
						 &queueObject                   //output AQ
						 );
    
	AudioQueueSetParameter (
							queueObject,
							kAudioQueueParam_Volume,
							1.0f
							);
	
}

- (void) setupAudioQueueBuffers {
	
	// prime the queue with some data before starting
	// allocate and enqueue buffers				
	int bufferIndex;
    AudioQueueRef temp_queue;
    AudioQueueBufferRef buffers[3];
    self.bufferByteSize = BUFFER_SIZE;
    
//    AudioQueueNewOutput(self.audioFormat, playbackCallback, NULL, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &temp_queue);
    //Allocate 3 buffers of specified length for the queueObject
	for (bufferIndex = 0; bufferIndex < 2; ++bufferIndex) {
		
		AudioQueueAllocateBuffer (
								  queueObject,
								  [self bufferByteSize],
								  &buffers[bufferIndex]
								  );
        
		playbackCallback ( 
						  (__bridge void *)(self),
						  queueObject,
						  buffers[bufferIndex]
						  );
		
		if ([self stopped]) break;
	}
    //self.queueObject = temp_queue;
}


- (void) play {
	
	[self setupAudioQueueBuffers];
	
	AudioQueueStart (
					 self.queueObject,
					 NULL			// start time. NULL means ASAP.
					 );
}

- (void) stop {
		
	AudioQueueStop (
					self.queueObject,
					self.audioPlayerShouldStopImmediately
					);
	
}


- (void) pause {
	
	AudioQueuePause (
					 self.queueObject
					 );
}


- (void) resume {
	
	AudioQueueStart (
					 self.queueObject,
					 NULL			// start time. NULL means ASAP
					 );
}


- (void) dealloc {
	
	AudioQueueDispose (
					   queueObject, 
					   YES
					   );
	
	//[super dealloc];
}

@end
