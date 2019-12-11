//
//  KAudioPlayFilter.m
//  KPlayTest5
//
//  Created by kuzalex on 11/27/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KAudioPlay.h"
#import "KPlayGraph.h"
#define MYDEBUG
//#define MYWARN
#import "myDebug.h"

#include <AudioToolbox/AudioToolbox.h>
#include "KLinkedList.h"

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
    @protected int32_t _sample_rate;
    AudioQueueBufferRef _buffers[NUM_BUFFERS];
    @protected uint32_t _buffer_size;
    CMTime _firstTs;
    BOOL _firstTsValid;
//    BOOL _buffersAllocated ;
    size_t _eosCount;
}
    - (instancetype)init
    {
        self = [super init];
        if (self) {
            self->_state = AudioQueueStopped_;
            self->_avqueue = nil;
            self->_lock = [[NSObject alloc]init];
            self->_sample_rate = 1;
            self->_firstTsValid=false;
//            self->_buffersAllocated=false;
            for (int i = 0; i < NUM_BUFFERS; i++){
                _buffers[i]=nil;
            }
            self->_eosCount=0;
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


    -(KMediaSample *)getNextSample
    {
        return nil;
    }

    -(void)eos
    {
        
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


    -(void)stop_withEOS:(BOOL)isEOS
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
        if (isEOS){
            [self eos];
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
                    
                    if (_buffers[i]==nil)
                    {
                        if ( AudioQueueAllocateBuffer(_avqueue, _buffer_size, &_buffers[i]) != noErr ){
                            DErr(@"AudioQueueAllocateBuffer failed");
                            return KResult_ERROR;
                        }
                        _buffers[i]->mAudioDataByteSize = self->_buffer_size;
                        
                        [self audioQueueCallback:_avqueue buffer:_buffers[i]];
                    }
                }
                
                
                
            }
        
        return KResult_OK;
    }

    

#define MYMIN(a,b) ( (a)<(b) ? (a) : (b) )
    -(void) audioQueueCallback:(AudioQueueRef)queue buffer:(AudioQueueBufferRef) buffer
    {
 
        KMediaSample *sample = [self getNextSample];
        
       
        if (sample!=nil){
            
            if (sample.eos){
                _eosCount++;
                if (_eosCount>=NUM_BUFFERS)
                    [self stop_withEOS:TRUE];
                return;
            }
            
            buffer->mAudioDataByteSize = MYMIN((uint32_t)sample.data.length, self->_buffer_size);
            
            if (buffer->mAudioDataByteSize == 0 && [self state] == AudioQueueRunning_) {
                //EOS!!
                //[self stop_];
            }
           
            
            memcpy(buffer->mAudioData, sample.data.bytes, buffer->mAudioDataByteSize);
            
            @synchronized (_lock) {

                DLog(@"audioQueueCallback enqueue");
                if ( AudioQueueEnqueueBuffer(_avqueue, buffer, 0, NULL) != noErr ){
                    DErr(@"AudioQueueEnqueueBuffer failed");
                }
            }
        } else {
            
            if ([self state] != AudioQueueStopped_){///FIXME
                [self waitForRun_];
            }
            
            @synchronized (_lock) {
                for (int i = 0; i < NUM_BUFFERS; i++)
                {
                    if (_buffers[i] == buffer)
                    {
                        AudioQueueFreeBuffer(_avqueue, _buffers[i]);
                        _buffers[i]=nil;
                    }
                }
            }
        }
    }

    -(void)flushBuffers
    {
        @synchronized (_lock) {
            for (int i = 0; i < NUM_BUFFERS; i++)
            {
                AudioQueueFreeBuffer(_avqueue, _buffers[i]);
                _buffers[i]=nil;
            }
        }
    }

    ///
    ///  KPlayPositionInfo
    ///

    -(CMTime)position
    {
        @synchronized (_lock) {
            if (_avqueue == nil)
                return CMTimeMake(0, 1);
            AudioTimeStamp timeStamp;
            Boolean disc;
            OSStatus status2 = AudioQueueGetCurrentTime(_avqueue, NULL, &timeStamp, &disc);
            if( status2 == noErr ){
                CMTime res = CMTimeMake(timeStamp.mSampleTime, _sample_rate);
                if (_firstTsValid){
                    res = CMTimeAdd(res, _firstTs);
                }
                return res;
            } else {
                return (_firstTsValid?_firstTs:CMTimeMake(0, 1));
            }
        }
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




#define MAX_SAMPLES 10



@implementation AudioQueue {
    KFilter __weak *filter;
    KLinkedList *_samples;
}
    - (instancetype)initWithSample:(KMediaSample *) sample andFilter:(KFilter *)f
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
            
            self->_samples = [[KLinkedList alloc]init];
            self->filter = f;
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
            [super flushBuffers];
            _eosCount=0;
        }
    }



    - (KResult)pushSample:(KMediaSample *) sample
    {
        if (sample==nil)
            return KResult_ERROR;
        
        if (sample.data.length != self->_buffer_size) {
            DErr(@"sample.data.length != _buffer_size %lu %d",(unsigned long)sample.data.length,_buffer_size);
           // return KResult_ERROR;
        }
                
        NSUInteger nSamples = 0;
        
        @synchronized (self->_samples) {
            [self->_samples addObjectToTail:sample];
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
                sample = [_samples objectAtHead];
                DLog(@"AudioQueue getNextSample ts=%lld/%d EOS=%d", sample.ts.value, sample.ts.timescale, sample.eos);
                [_samples removeObjectFromHead];
            }
        }
        return sample;
    }

    -(void)eos
    {
        if (filter)
        {
            if ([filter.events respondsToSelector:@selector(onEOS:)]) {
                [filter.events onEOS:filter];
            }
        }
    }


    - (CMTime)endBufferedPosition {
        @synchronized (self->_samples) {
            if (_samples.count > 0){
                KMediaSample *sample = [_samples objectAtTail];
                return sample.ts; ///FIXME + duration
            }
        }
        return CMTimeMake(0, 1);
        
    }


//    - (CMTime)startBufferedPosition {
//
//        @synchronized (self->_samples) {
//            if (_samples.count > 0){
//                KMediaSample *sample = [_samples objectAtHead];
//                return sample.ts;
//
//            }
//        }
//        return CMTimeMake(0, 1);
//    }

   

    +(BOOL)isInputMediaTypeSupported:(KMediaType *)type
    {
        if ([type.name compare:@"audio"]>=0){
            // CMAudioFormatDescriptionRef format = type.format;
            
            const AudioStreamBasicDescription  * _Nullable pformat  = CMAudioFormatDescriptionGetStreamBasicDescription(type.format);
            if (pformat==nil)
                return FALSE;
            return pformat->mFormatID == kAudioFormatLinearPCM;
            //_format = AudioStream
          //  _format = *pformat;
        }
        return FALSE;
    }


@end






@implementation KAudioPlay {
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
                [_queue stop_withEOS:FALSE];
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
        
        if (_queue!=nil && [_queue isFull])///FIXME: only for...
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
        
        DLog(@"%@ <%@> got sample type=%@ %ld bytes, ts=%lld/%d", self, [self name], sample.type.name, [sample.data length], sample.ts.value, sample.ts.timescale);
        
        
        if (_queue==nil) {
            _queue = [[AudioQueue alloc] initWithSample:sample andFilter:self];
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
    [_queue stop_withEOS:FALSE];
    [_queue flushSamples];
    return KResult_OK;
}

///
///  KPlayPositionInfo
///

-(CMTime)position
{
    if (_queue!=nil)
        return [_queue position];
    return CMTimeMake(0, 1);
}




///
///  KPlayBufferPositionInfo
///

- (CMTime)endBufferedPosition {
    if (_queue!=nil)
         return [_queue endBufferedPosition];
    
     return CMTimeMake(0, 1);
}


- (CMTime)startBufferedPosition {
    return [self position];
//    if (_queue!=nil)
//         return [_queue startBufferedPosition];
//
//     return CMTimeMake(0, 1);
}


- (BOOL)isRunning {
    if (_queue!=nil)
        return [_queue isRunning];
    return FALSE;
}





@end

