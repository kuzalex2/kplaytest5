//
//  KAudioPlayFilter.m
//  KPlayTest5
//
//  Created by kuzalex on 11/27/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KAudioPlayFilter.h"
#define MYDEBUG
#define MYWARN
#import "myDebug.h"

#include <AudioToolbox/AudioToolbox.h>

typedef enum  {
    AudioQueueStopped,
    AudioQueuePaused,
    AudioQueueRunning
} AudioQueueState;

@interface AudioQueueBase : NSObject

@end

@implementation AudioQueueBase{
    AudioQueueState _state;
    @protected AudioQueueRef _queue;
    NSObject *_lock;
}
    - (instancetype)init
    {
        self = [super init];
        if (self) {
            self->_state = AudioQueueStopped;
            self->_queue = nil;
            self->_lock = [[NSObject alloc]init];
        }
        return self;
    }

    -(AudioQueueState) state
    {
        return _state;
    }

    -(void)start
    {
        @synchronized (_lock) {
            if (_queue == nil)
                return;
            if (_state == AudioQueueRunning)
                return;
            
            _state = AudioQueueRunning;
        }
        
        DLog(@"AudioQueueStart");
        
        if ( AudioQueueStart(_queue, NULL) != noErr ){
            DErr(@"AudioQueueStart failed");
        }
    }

    -(void)pause
    {
        @synchronized (_lock) {
            if (_queue == nil)
                return;
            if (_state == AudioQueuePaused)
                return;
            
            _state = AudioQueuePaused;
        }
        
        DLog(@"AudioQueuePause");
        
        if ( AudioQueuePause(_queue) != noErr ){
            DErr(@"AudioQueuePause failed");
        }
    }


    -(void)stop
    {
        @synchronized (_lock) {
            if (_queue == nil)
                return;
            if (_state == AudioQueueStopped)
                return;
            
            _state = AudioQueueStopped;
        }
        
        DLog(@"AudioQueueStop");
        
        
        if ( AudioQueueStop(_queue, true) != noErr ){
            DErr(@"AudioQueueStop failed");
        }
    }
@end




@interface AudioQueue : AudioQueueBase
    -(BOOL)isFull;
    +(BOOL)isInputMediaTypeSupported:(KMediaType *)type;
@end



#define NUM_BUFFERS 3
#define MAX_SAMPLES 10

void audioQueueCallback0(void *custom_data, AudioQueueRef queue, AudioQueueBufferRef buffer);

@implementation AudioQueue {
    AudioQueueBufferRef _buffers[NUM_BUFFERS];
    NSMutableArray *_samples;
    uint32_t _buffer_size;
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

            if (AudioQueueNewOutput(CMAudioFormatDescriptionGetStreamBasicDescription(sample.type.format), audioQueueCallback0, (__bridge void *)self, nil, nil, 0, &_queue)!=noErr){
                DErr(@"AudioQueueNewOutput failed");
                return nil;
            }
            
              
            self->_buffer_size = (uint32_t)sample.data.length;
            self->_samples = [[NSMutableArray alloc] init];
        }
        return self;
    }


    -(BOOL)isFull
     {
         @synchronized (self->_samples) {
             return _samples.count > MAX_SAMPLES;
         }
     }



    - (KResult)pushSample:(KMediaSample *) sample
    {
        if (sample==nil)
            return KResult_ERROR;
        
        if (sample.data.length != _buffer_size) {
            DErr(@"sample.data.length != _buffer_size %lu %d",(unsigned long)sample.data.length,_buffer_size);
            return KResult_ERROR;
        }
                
        int nSamples = 0;
        
        @synchronized (self->_samples) {
            [self->_samples addObject:sample];
            nSamples = _samples.count;
        }
        
        if (nSamples > 3 && [self state] != AudioQueueRunning)
        {
            [self start];
        
            for (int i = 0; i < NUM_BUFFERS; i++)
            {
                if ( AudioQueueAllocateBuffer(_queue, self->_buffer_size, &_buffers[i]) != noErr ){
                    DErr(@"AudioQueueAllocateBuffer failed");
                }
                        
                _buffers[i]->mAudioDataByteSize = self->_buffer_size;
                
                [self audioQueueCallback:_queue buffer:_buffers[i]];
         
            }
        }
        
        return KResult_OK;
    }

    -(void) audioQueueCallback:(AudioQueueRef)queue buffer:(AudioQueueBufferRef) buffer
    {
     
        KMediaSample *sample = nil;
        
        
        @synchronized (self->_samples) {
            if (_samples.count > 0){
                sample = [_samples objectAtIndex:0];
                [_samples removeObjectAtIndex:0];
            }
        }
        
        if (sample!=nil){
            assert( buffer->mAudioDataByteSize == sample.data.length);
            
            memcpy(buffer->mAudioData, sample.data.bytes, sample.data.length);
            
            DErr(@"audioQueueCallback enqueue");
            if ( AudioQueueEnqueueBuffer(_queue, buffer, 0, NULL) != noErr ){
                DErr(@"AudioQueueEnqueueBuffer failed");
            }
        } else {
            
            if ([self state] != AudioQueueStopped){
                [self pause];
            }
        }
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

void audioQueueCallback0(void *custom_data, AudioQueueRef queue, AudioQueueBufferRef buffer)
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





-(KResult) onThreadTick:(NSError *__strong*)ppError
{
  @autoreleasepool
    {
        KMediaSample *sample;
       // NSError *error;
        KResult res;
        
        if (_queue!=nil && [_queue isFull])
        {
            if ([_queue state] == AudioQueueRunning )
            {
                usleep(100000);
                return KResult_OK;
            }
        }
   
        
        KInputPin *pin = [self getInputPinAt:0];
        res = [pin pullSample:&sample probe:NO error:ppError];
        
        if (res != KResult_OK) {
            if (*ppError!=nil){
                DErr(@"%@ %@", [self name], *ppError);
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
   // }
}




@end

