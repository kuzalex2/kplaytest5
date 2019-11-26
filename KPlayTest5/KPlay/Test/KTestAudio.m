//
//  KTestAudio.m
//  KPlayTest5
//
//  Created by kuzalex on 11/26/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KTestAudio.h"
#define MYDEBUG
#define MYWARN
#import "myDebug.h"

#include <AudioToolbox/AudioToolbox.h>




#define BUFFER_SIZE 44100*2*2
#define SAMPLE_TYPE short
#define MAX_NUMBER 32767
#define SAMPLE_RATE 44100

@implementation KAudioSourceToneFilter{
   
    KMediaType *_type;
    long _count;
   // OutSampleQueue *out_queue;
    
    //size_t sample_count_before_error;
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _type = [[KMediaType alloc]initWithName:@"text"];
        
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
       // out_queue = [[OutSampleQueue alloc] initWithMinCount:5];
    }
    return self;
}

-(KMediaType *)getOutputMediaType
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


-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError **)error;
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
    return KResult_OK;
}

@end







typedef enum  {
    AudioQueueStopped,
    AudioQueuePaused,
    AudioQueueRunning
} AudioQueueStatus;


@interface AudioQueue : NSObject  {
    AudioQueueStatus _status;
    
}

    -(void)stop;
    -(void)pause;
    -(BOOL)isFull;
    +(BOOL)isInputMediaTypeSupported:(KMediaType *)type;

@end



#define NUM_BUFFERS 3
void audioQueueCallback(void *custom_data, AudioQueueRef queue, AudioQueueBufferRef buffer);

@implementation AudioQueue {
    AudioQueueRef _queue;
    AudioQueueBufferRef _buffers[NUM_BUFFERS];
    uint32_t _buffer_size;
    //@public int _consumed_samples;
}
    - (instancetype)initWithSample:(KMediaSample *) sample
    {
        if (sample==nil || sample.type == nil || ! [AudioQueue isInputMediaTypeSupported:sample.type]) {
            DErr(@"invalid sample or type");
            return nil;
            
        }
        
        if (sample.data.length < 1024) {
            DErr(@"too small sample");
            return nil;
        }
       
        self = [super init];
        if (self) {
            self->_status = AudioQueueStopped;
            AudioQueueNewOutput(CMAudioFormatDescriptionGetStreamBasicDescription(sample.type.format), audioQueueCallback, (__bridge void *)self, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &_queue);
            
            self->_buffer_size = (uint32_t)sample.data.length;
            
            for (int i = 0; i < NUM_BUFFERS; i++)
            {
                AudioQueueAllocateBuffer(_queue, self->_buffer_size, &_buffers[i]);
                        
                _buffers[i]->mAudioDataByteSize = self->_buffer_size;
               
                //callback(NULL, queue, buffers[i]);
            }
            
            self->_status = AudioQueuePaused;
            AudioQueuePause(_queue);
//            [self pushSample:sample];
        }
        return self;
    }






    - (KResult)pushSample:(KMediaSample *) sample
    {
        if (sample==nil)
            return KResult_ERROR;
        if (sample.data.length != _buffer_size) {
            DLog(@"sample.data.length != _buffer_size %lu %d",(unsigned long)sample.data.length,_buffer_size);
            return KResult_ERROR;
        }
         ///FIXME: impl
        // real push
        // state and size and play
        return KResult_OK;
    }

    -(void) audioQueueCallback:(AudioQueueRef)queue buffer:(AudioQueueBufferRef) buffer
    {
        DErr(@"Here");
    }
 

    -(void)stop
    {
        ///FIXME: impl
    }
    -(void)pause
    {
        ///FIXME: impl
    }
    -(BOOL)isFull
    {
        ///FIXME: impl
        return FALSE;
    }





    +(BOOL)isInputMediaTypeSupported:(KMediaType *)type
    {
        if ([type.name isEqualToString:@"audio/pcm"]){
            // CMAudioFormatDescriptionRef format = type.format;
            
            const AudioStreamBasicDescription  * _Nullable pformat  = CMAudioFormatDescriptionGetStreamBasicDescription(type.format);
            if (pformat==nil)
                return FALSE;
            //_format = AudioStreamBasicDescription
            AudioStreamBasicDescription format = *pformat;
            NSLog(@"%d", format.mBitsPerChannel);
            
            
            
            return TRUE;
        }
        return FALSE;
    }


@end

void audioQueueCallback(void *custom_data, AudioQueueRef queue, AudioQueueBufferRef buffer)
{
    AudioQueue *q = (__bridge AudioQueue *)custom_data;
    [q audioQueueCallback:queue buffer:buffer];
}




@implementation KAudioPlayFilter {
    const AudioStreamBasicDescription * _Nullable _format ;
    AudioQueue *_queue;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self.inputPins addObject:[[KInputPin alloc] initWithFilter:self]];
        _queue = nil;
    }
    return self;
}

-(BOOL)isInputMediaTypeSupported:(KMediaType *)type
{
    return [AudioQueue isInputMediaTypeSupported:type];
}


- (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
{
    switch (_state) {
        case KFilterState_STOPPED:
            if (_queue!=nil){
                [_queue stop];
                _queue = nil;
            }
            break;
        case KFilterState_STOPPING:
            break;
        case KFilterState_PAUSING:
            if (_queue!=nil){
                [_queue pause];
            }
            break;
        case KFilterState_STARTED:
            break;
        case KFilterState_PAUSED:
            break;
    }
}





-(KResult) onThreadTick
{
    @autoreleasepool {
        KMediaSample *sample;
        NSError *error;
        KResult res;
        
        if (_queue!=nil && [_queue isFull])
        {
            usleep(100000);
            return KResult_OK;
        }

        
        KInputPin *pin = [self getInputPinAt:0];
        res = [pin pullSample:&sample probe:NO error:&error];
        
        if (res != KResult_OK) {
            if (error!=nil){
                DErr(@"%@ %@", [self name], error);
            }
            return res;
        }
        
        DLog(@"%@ <%@> got sample type=%@ %ld bytes, ts=%lld/%d", self, [self name], sample.type.name, [sample.data length], sample.ts, sample.timescale);
        
        
        if (_queue==nil) {
            _queue = [[AudioQueue alloc] initWithSample:sample];
            if (_queue == nil) {
                return KResult_ERROR;
            }
        }
        
        return [_queue pushSample:sample];
    }
}




@end

