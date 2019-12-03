//
//  KTestAudio.m
//  KPlayTest5
//
//  Created by kuzalex on 11/26/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KTestAudio.h"
#define MYDEBUG
//#define MYWARN
#import "myDebug.h"


#include <AudioToolbox/AudioToolbox.h>




#define BUFFER_SIZE 44100*2*2
#define SAMPLE_TYPE short
#define MAX_NUMBER 32767
#define SAMPLE_RATE 44100

@implementation KAudioSourceToneFilter{
   
    KMediaType *_type;
    long _count;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        AudioStreamBasicDescription format;
        CMFormatDescriptionRef      cmformat;
        format.mSampleRate       = SAMPLE_RATE;
        format.mFormatID         = kAudioFormatLinearPCM;
        format.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        format.mBitsPerChannel   = 8 * sizeof(SAMPLE_TYPE);
        format.mChannelsPerFrame = 2;
        format.mBytesPerFrame    = sizeof(SAMPLE_TYPE) * format.mChannelsPerFrame;
        format.mFramesPerPacket  = 1;
        format.mBytesPerPacket   = format.mBytesPerFrame * format.mFramesPerPacket;
        format.mReserved         = 0;
        
        
       
        if (CMAudioFormatDescriptionCreate(kCFAllocatorDefault,
                      &format,
                      0,
                      NULL,
                      0,
                      NULL,
                      NULL,
                      &cmformat)!=noErr)
        {
            NSLog(@"Could not create format from AudioStreamBasicDescription");
            return nil;
        }
        
        _type = [[KMediaType alloc] initWithName:@"audio/pcm"];
        [_type setFormat:cmformat];
        
        [self.outputPins addObject:[
                                    [KOutputPin alloc] initWithFilter:self]
         ];
    }
    return self;
}

-(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin
{
    return _type;
}

- (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
{
    switch (_state) {
        case KFilterState_STOPPED:
            _count=0;
            break;
        case KFilterState_STOPPING:
        case KFilterState_PAUSING:
        case KFilterState_STARTED:
        case KFilterState_PAUSED:
            
            break;
    }
}


-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin;
{
    KMediaSample *mySample = [[KMediaSample alloc] init];
    mySample.ts = _count;
    mySample.timescale=SAMPLE_RATE;
    mySample.type=_type;
    
    
    
    unsigned char buffer[BUFFER_SIZE];
   
    SAMPLE_TYPE *casted_buffer = (SAMPLE_TYPE *)buffer;
    for (int i = 0; i < BUFFER_SIZE / sizeof(SAMPLE_TYPE); i += 2)
       {
           double float_sample = sin(_count / 10.0);
           
           SAMPLE_TYPE int_sample = (SAMPLE_TYPE)(float_sample * MAX_NUMBER);
           
           casted_buffer[i]   = int_sample;
           casted_buffer[i+1] = int_sample;
           
           _count++;
       }
    
    
    
    mySample.data = [NSData dataWithBytes:buffer length:BUFFER_SIZE];

    *sample = mySample;
    
    DLog(@"Count=%ld", _count);
    if (_count>200000){
        usleep(1400000);
    }
    
    if (_count>500000){
        NSError *test_error=[NSError errorWithDomain:@"com.kuzalex" code:200 userInfo:@{@"Error reason": @"Test Error"}];
        *error = test_error;
        return KResult_ERROR;
    }
    
    return KResult_OK;
}

@end



