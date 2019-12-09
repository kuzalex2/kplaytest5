//
//  KBufferQueue.m
//  KPlayTest5
//
//  Created by kuzalex on 12/9/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//


#define MYDEBUG
#define MYWARN
#include "myDebug.h"

#import "KBufferQueue.h"
#include <pthread.h>

@interface KQueue : NSObject

@end

@implementation KQueue {
    pthread_mutex_t queue_lock;
    pthread_cond_t queue_cond;
    NSMutableArray *samples;
    NSError *error;
    
    KFilterState _state;
    BOOL isRunning;
    
    int64_t lastTs;
    int64_t lastTsTimescale;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //TODO: free???
        pthread_mutex_init(&self->queue_lock, NULL);
        pthread_cond_init(&self->queue_cond, NULL);
        samples = [[NSMutableArray alloc]init];
        _state = KFilterState_STOPPED;
        isRunning = FALSE;
        error=nil;
    }
    return self;
}

-(void) onState:(KFilterState) state;
{
    pthread_mutex_lock(&queue_lock);
   
    _state = state;
    pthread_cond_signal(&queue_cond);
    
    pthread_mutex_unlock(&queue_lock);
}

#define MIN_SAMPLES 50

-(KResult)pushError:(NSError *)error
{
    pthread_mutex_lock(&queue_lock);
    DLog(@"queue add error");
    self->error = error;
    if (!isRunning) {
        DLog(@"queue NOT RUNNING");
        isRunning = TRUE;
        DLog(@"queue RUN");
        pthread_cond_signal(&queue_cond);
    }
    pthread_mutex_unlock(&queue_lock);
    return KResult_OK;
}

-(KResult)pushSample:(KMediaSample *)sample
{
    pthread_mutex_lock(&queue_lock);
    DLog(@"queue add ts=%lld", sample.ts);
    [samples addObject:sample];
    
    lastTs = sample.ts; // + duration
    lastTsTimescale = sample.timescale;
    
    if (!isRunning) {
        DLog(@"queue NOT RUNNING");
        if ([samples count]>MIN_SAMPLES){
            isRunning = TRUE;
            DLog(@"queue RUN");
            pthread_cond_signal(&queue_cond);
        }
    }
    pthread_mutex_unlock(&queue_lock);
    return KResult_OK;
}

-(KResult)popSample:(KMediaSample **)sample probe:(BOOL)probe
{
    pthread_mutex_lock(&queue_lock);
    while(1)
    {
        DLog(@"queue pop sample probe=%d", probe);
        
        switch (_state) {
            case KFilterState_STARTED:
                break;
            case KFilterState_STOPPING:
            case KFilterState_STOPPED:
                DLog(@"queue STOPPED");
                pthread_mutex_unlock(&queue_lock);
                return KResult_InvalidState;
            case KFilterState_PAUSING:
                break;
            case KFilterState_PAUSED:
                break;
        }
        
//        if (error) ...
        
        if ([samples count] == 0){
            DLog(@"queue NO SAMPLES");
            isRunning=FALSE;
            pthread_cond_wait(&queue_cond, &queue_lock);
            continue;
        }
        
        if (probe){
            DLog(@"queue PROBE OK");
            *sample = [samples objectAtIndex:0];
            pthread_mutex_unlock(&queue_lock);
            return KResult_OK;
        }
        if (_state==KFilterState_STARTED && !isRunning){
            DLog(@"queue WAIT");
            pthread_cond_wait(&queue_cond, &queue_lock);
            continue;
        }
        
        
        *sample = [samples objectAtIndex:0];
        [samples removeObjectAtIndex:0];
        DLog(@"queue OK ts=%lld", (*sample).ts);
        
        pthread_mutex_unlock(&queue_lock);
        return KResult_OK;
    }
}

-(void)flush
{
    pthread_mutex_lock(&queue_lock);
  
    DLog(@"queue FLUSH");
    [samples removeAllObjects];
    isRunning = FALSE;
    error=nil;
    lastTs=0;
    
    
    pthread_mutex_unlock(&queue_lock);
}

- (int64_t)endBufferedPosition {
    int64_t result;
    
    pthread_mutex_lock(&queue_lock);
    if ([samples count] == 0) {
        result = lastTs;
    } else {
        KMediaSample *s = [samples lastObject];
        result = s.ts;
    }
    pthread_mutex_unlock(&queue_lock);
    
    return result;
}

- (int64_t)startBufferedPosition {
    int64_t result;
    
    pthread_mutex_lock(&queue_lock);
    if ([samples count] == 0) {
        result = lastTs;
    } else {
        KMediaSample *s = [samples firstObject];
        result = s.ts;
    }
    pthread_mutex_unlock(&queue_lock);
    
    return result;
}

- (int64_t)timeScale {
    int64_t result;
    
    pthread_mutex_lock(&queue_lock);
    result = lastTsTimescale;
    pthread_mutex_unlock(&queue_lock);
    
    return result;
}

@end




@implementation KBufferQueue{
//    NSError *_error;
    KQueue *queue;
    KMediaType *type;
//    dispatch_semaphore_t _sem;
   
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        type = [[KMediaType alloc]initWithName:@"text"];
        [self.outputPins addObject:[ [KOutputPin alloc] initWithFilter:self] ];
        [self.inputPins addObject:[ [KInputPin alloc] initWithFilter:self] ];
        
        queue = [[KQueue alloc]init];
//
//        _error=nil;
    }
    return self;
}




- (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
{
    if (state == KFilterState_STOPPED)
        [queue flush];
   
    [queue onState:state];
}

-(KResult)seek:(float)sec
{
    [queue flush];
   
    return KResult_OK;
}


// any (with ts?) input type -> output type
-(BOOL)isInputMediaTypeSupported:(KMediaType *)type
{
    self->type=type;
    return TRUE;
}

-(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin
{
    return self->type;
}


-(KResult)onThreadTick:(NSError *__strong*)ppError
{
    KInputPin *pin = [self getInputPinAt:0];
    if (!pin){
        DErr(@"%@ no input pin", [self name]);
        return KResult_ERROR;
    }

    @autoreleasepool {

        KMediaSample *sample;
        NSError *err;
           
        KResult res = [pin pullSample:&sample probe:NO error:&err];


        if (res!=KResult_OK) {
            [queue pushError:err];
            return res;
        }
        
        [queue pushSample:sample];
    }
    return KResult_OK;
}


-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin;
{
    return [queue popSample:sample probe:probe];
}

- (int64_t)endBufferedPosition {
    return [queue endBufferedPosition];
}

- (int64_t)startBufferedPosition {
    return [queue startBufferedPosition];
}

- (int64_t)timeScale {
    return [queue timeScale];
}

@end

