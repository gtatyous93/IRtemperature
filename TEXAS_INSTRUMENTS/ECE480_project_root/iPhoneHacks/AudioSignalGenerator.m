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

typedef void (*AudioQueueOutputCallback)(
void * __nullable       inUserData,
AudioQueueRef           inAQ,
AudioQueueBufferRef     inBuffer);


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
    if (!inBuffer) return;
	[player fillBuffer:inBuffer->mAudioData];
	
	inBuffer->mAudioDataByteSize = player.bufferByteSize;

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

- (void) setupAudioFormat {
}

- (void) fillBuffer: (void*) buffer
{
}

- (void) setupPlaybackAudioQueueObject {
	
	// create the playback audio queue object
	AudioQueueNewOutput (&audioFormat,                  //input format
						 playbackCallback,              //callback process
						 (__bridge void * _Nullable)(self), //in user
						 CFRunLoopGetCurrent (),        //callback run loop
						 kCFRunLoopCommonModes,         //callback runloop mode
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
	
    //Allocate 3 buffers of specified length for the queueObject
	for (bufferIndex = 0; bufferIndex < 3; ++bufferIndex) {
		
		AudioQueueAllocateBuffer (
								  [self queueObject_TESTIAN],
								  [self bufferByteSize],
								  &buffers[bufferIndex]
								  );
		
		playbackCallback ( 
						  (__bridge void *)(self),
						  [self queueObject_TESTIAN],
						  buffers[bufferIndex]
						  );
		
		if ([self stopped]) break;
	}
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
