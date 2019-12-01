//
//  KAudioPlayFilter.m
//  KPlayTest5
//
//  Created by kuzalex on 11/27/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KAudioPlayFilter.h"
#import "KPlayGraph.h"
#define MYDEBUG
#define MYWARN
#import "myDebug.h"

#include <AudioToolbox/AudioToolbox.h>

typedef enum  {
    AudioQueueStopped_,
    AudioQueueWaitForRun_,
    AudioQueueRunning_,
    AudioQueuePaused_
} AudioQueueState;

@interface AudioQueueBase : NSObject<KPlayPositionInfo>

@end

void audioQueueCallback2(void *custom_data, AudioQueueRef queue, AudioQueueBufferRef buffer);

#define NUM_BUFFERS 3

@implementation AudioQueueBase{
    AudioQueueState _state;
    AudioQueueRef _avqueue;
    NSObject *_lock;
    int64_t _sample_rate;
    AudioQueueBufferRef _buffers[NUM_BUFFERS];
    @protected uint32_t _buffer_size;
    int64_t _firstTs;
    BOOL _firstTsValid;
}
    - (instancetype)init
    {
        self = [super init];
        if (self) {
            self->_state = AudioQueueStopped_;
            self->_avqueue = nil;
            self->_lock = [[NSObject alloc]init];
            self->_sample_rate = 1000;
            self->_firstTsValid=false;
        }
        return self;
    }

    -(AudioQueueState) state
    {
        return _state;
    }

    -(BOOL)isRunning
    {
        @synchronized (_lock) {
            if (_avqueue == nil)
                return FALSE;
            return _state == AudioQueueRunning_;
        }
    }

    -(void)waitForRun_
    {
       @synchronized (_lock) {
        if (_avqueue == nil)
            return;
            
            _state = AudioQueueWaitForRun_;
        }///FIXME!!!!!!!!!!
        ///FIXME!!!!!!!!!!
        ///FIXME!!!!!!!!!!
        ///FIXME!!!!!!!!!!
        ///FIXME!!!!!!!!!! lock to all!!!!
        
        DLog(@"AudioQueueWaitForRun_");
        
        if ( AudioQueuePause(_avqueue) != noErr ){
            DErr(@"AudioQueuePause failed");
        }
    }

    -(void)start_
    {
        @synchronized (_lock) {
            if (_avqueue == nil)
                return;
            if (_state != AudioQueueWaitForRun_)
                return;
            
            _state = AudioQueueRunning_;
        }
        
        DLog(@"AudioQueueRunning_");
        
        if ( AudioQueueStart(_avqueue, NULL) != noErr ){
            DErr(@"AudioQueueStart failed");
        }
    }


    -(void)pause_
    {
        @synchronized (_lock) {
            if (_avqueue == nil)
                return;
            if (_state == AudioQueuePaused_)
                return;
            
            _state = AudioQueuePaused_;
        }
        
        DLog(@"AudioQueuePaused_");
        
        if ( AudioQueuePause(_avqueue) != noErr ){
            DErr(@"AudioQueuePause failed");
        }
    }


    -(void)stop_
    {
        @synchronized (_lock) {
            if (_avqueue == nil)
                return;
            if (_state == AudioQueueStopped_)
                return;
            
            _state = AudioQueueStopped_;
        }
        
        DLog(@"AudioQueueStopped_");
        
        
        if ( AudioQueueStop(_avqueue, true) != noErr ){
            DErr(@"AudioQueueStop failed");
        }
    }
            
          

    -(KResult)initOutput:(KMediaSample * _Nonnull)sample
    {
        const AudioStreamBasicDescription *fmt = CMAudioFormatDescriptionGetStreamBasicDescription(sample.type.format);
        @synchronized (_lock) {
             if (fmt == nil || AudioQueueNewOutput(fmt, audioQueueCallback2, (__bridge void *)self, nil, nil, 0, &_avqueue)!=noErr){
                DErr(@"AudioQueueNewOutput failed");
                return KResult_ERROR;
            }
        }
        _sample_rate = fmt->mSampleRate;
        _buffer_size = (uint32_t)sample.data.length;
        
        return KResult_OK;
    }

     -(KResult)allocBuffers
    {
               
        for (int i = 0; i < NUM_BUFFERS; i++)
        {
            @synchronized (_lock) {

                if ( AudioQueueAllocateBuffer(_avqueue, _buffer_size, &_buffers[i]) != noErr ){
                    DErr(@"AudioQueueAllocateBuffer failed");
                    return KResult_ERROR;
                }
            }
            
            _buffers[i]->mAudioDataByteSize = self->_buffer_size;
            
            [self audioQueueCallback:_avqueue buffer:_buffers[i]];
            
        }
        return KResult_OK;
    }

    -(KMediaSample *)getNextSample
    {
        return nil;
    }

    -(void) audioQueueCallback:(AudioQueueRef)queue buffer:(AudioQueueBufferRef) buffer
    {
 
        KMediaSample *sample = [self getNextSample];
        
       
        if (sample!=nil){
            assert( buffer->mAudioDataByteSize == sample.data.length);
            
            memcpy(buffer->mAudioData, sample.data.bytes, sample.data.length);
            
            @synchronized (_lock) {

                DErr(@"audioQueueCallback enqueue");
                if ( AudioQueueEnqueueBuffer(_avqueue, buffer, 0, NULL) != noErr ){
                    DErr(@"AudioQueueEnqueueBuffer failed");
                }
            }
        } else {
            
            if ([self state] != AudioQueueStopped_){///FIXME
                [self waitForRun_];
            }
        }
    }

    ///
    ///  KPlayPositionInfo
    ///

    -(int64_t)position
    {
        @synchronized (_lock) {
            if (_avqueue == nil)
                return 0;
            AudioTimeStamp timeStamp;
            Boolean disc;
            OSStatus status2 = AudioQueueGetCurrentTime(_avqueue, NULL, &timeStamp, &disc);
            if( status2 != noErr )
                return (_firstTsValid?_firstTs:0);
            return timeStamp.mSampleTime + (_firstTsValid?_firstTs:0);
        }
    }

    -(int64_t)timeScale
    {
        return _sample_rate;
    }


    

    
@end

void audioQueueCallback2(void *custom_data, AudioQueueRef queue, AudioQueueBufferRef buffer)
{
    AudioQueueBase *q = (__bridge AudioQueueBase *)custom_data;
    [q audioQueueCallback:queue buffer:buffer];
}


@interface AudioQueue : AudioQueueBase
    -(BOOL)isFull;
    +(BOOL)isInputMediaTypeSupported:(KMediaType *)type;
@end




#define MAX_SAMPLES 100



@implementation AudioQueue {
    NSMutableArray *_samples;
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

            if ([super initOutput:sample]!=KResult_OK) {
                return nil;
            }
            
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

    -(void)flushSamples
    {
        @synchronized (self->_samples) {
            [_samples removeAllObjects];
            _firstTsValid=false;
        }
    }



    - (KResult)pushSample:(KMediaSample *) sample
    {
        if (sample==nil)
            return KResult_ERROR;
        
        if (sample.data.length != self->_buffer_size) {
            DErr(@"sample.data.length != _buffer_size %lu %d",(unsigned long)sample.data.length,_buffer_size);
            return KResult_ERROR;
        }
                
        NSUInteger nSamples = 0;
        
        @synchronized (self->_samples) {
            [self->_samples addObject:sample];
            nSamples = _samples.count;
            if (!_firstTsValid){
                _firstTsValid=true;
                _firstTs=sample.ts;
            }
        }
        
        if (nSamples > 3 && [self state] == AudioQueueWaitForRun_)
        {
            [self start_];
            
            [super allocBuffers];
        
            
        }
        
        return KResult_OK;
    }

    -(KMediaSample *)getNextSample
    {
        KMediaSample *sample = nil;
        @synchronized (self->_samples) {
            if (_samples.count > 0){
                sample = [_samples objectAtIndex:0];
                [_samples removeObjectAtIndex:0];
            }
        }
        return sample;
    }


    - (int64_t)endBufferedPosition {
        @synchronized (self->_samples) {
            if (_samples.count > 0){
                KMediaSample *sample = [_samples lastObject];
                return sample.ts; ///FIXME + duration
            }
        }
        return 0;
        
    }


    - (int64_t)startBufferedPosition {
       
        @synchronized (self->_samples) {
            if (_samples.count > 0){
                KMediaSample *sample = [_samples firstObject];
                return sample.ts;
               
            }
        }
        return 0;
    }

   

    +(BOOL)isInputMediaTypeSupported:(KMediaType *)type
    {
        if ([type.name isEqualToString:@"audio/pcm"]){
            // CMAudioFormatDescriptionRef format = type.format;
            
            const AudioStreamBasicDescription  * _Nullable pformat  = CMAudioFormatDescriptionGetStreamBasicDescription(type.format);
            if (pformat==nil)
                return FALSE;
            //_format = AudioStream
          //  _format = *pformat;
           
            
            
            
            return TRUE;
        }
        return FALSE;
    }


@end






@implementation KAudioPlayFilter {
   // const AudioStreamBasicDescription * _Nullable _format ;
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
                [_queue stop_];
                [_queue flushSamples];
               
               // _queue = nil;
            }
            break;
        case KFilterState_STOPPING:
            break;
        case KFilterState_PAUSING:
            if (_queue!=nil){
                [_queue pause_];
            }
            break;
        case KFilterState_STARTED:
            if (_queue!=nil){
                [_queue waitForRun_];
               // _queue = nil;
            }
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
            if ([_queue state] == AudioQueueRunning_ )
            {
                usleep(10000);
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

-(KResult)seek:(float)sec
{
    [_queue stop_];
    [_queue flushSamples];
    return KResult_OK;
}

///
///  KPlayPositionInfo
///

-(int64_t)position
{
    if (_queue!=nil)
        return [_queue position];
    return 0;
}

-(int64_t)timeScale
{
    if (_queue!=nil)
        return [_queue timeScale];
   
    return 0;
}


///
///  KPlayBufferPositionInfo
///

- (int64_t)endBufferedPosition {
    if (_queue!=nil)
         return [_queue endBufferedPosition];
    
     return 0;
}


- (int64_t)startBufferedPosition {
    if (_queue!=nil)
         return [_queue startBufferedPosition];
    
     return 0;
}


- (BOOL)isRunning {
    if (_queue!=nil)
        return [_queue isRunning];
    return FALSE;
}





@end

