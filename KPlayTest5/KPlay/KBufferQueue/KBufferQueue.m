//
//  KBufferQueue.m
//  KPlayTest5
//
//  Created by kuzalex on 12/9/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//


//#define MYDEBUG
//#define MYDEBUG3
//#define MYWARN
#include "myDebug.h"

#import "KBufferQueue.h"
#include <pthread.h>
#include "KLinkedList.h"

@interface KQueue : NSObject

@end

@implementation KQueue {
    pthread_mutex_t queue_lock;
    pthread_cond_t queue_cond;
    KLinkedList *samples2;
    KLinkedListNode *lastConsumedSample;
    NSError *error; ///FIXME: error processing
    
    KFilterState _state;
    BOOL isRunning;
    
    CMTime lastTs;
    @public float startBufferSec[2];
    @public size_t curStartBufferSecIndex;
    @public float maxBufferSec;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //TODO: free???
        pthread_mutex_init(&self->queue_lock, NULL);
        pthread_cond_init(&self->queue_cond, NULL);
        samples2 = [[KLinkedList alloc]init];
        lastConsumedSample = nil;
        _state = KFilterState_STOPPED;
        isRunning = FALSE;
        error=nil;
        startBufferSec[0] = 0.3;
        startBufferSec[1] = 3.0;
        curStartBufferSecIndex = 0;
        maxBufferSec = MAX(startBufferSec[0],startBufferSec[1])*1.2;
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


-(KResult)pushError:(NSError *)error withOrderByTimestamp:(BOOL)orderByTimestamp ///FIXME: orderByTimestamp
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

-(double)secondsInQueue3
{
    if ([samples2 isEmpty])
        return 0.0;
    
    KMediaSample *firstSample = [samples2 objectAtHead];
    KMediaSample *lastSample = [samples2 objectAtTail];
    
    assert(firstSample!=nil);
    assert(lastSample!=nil);
    
    return (double)(lastSample.ts.value) / lastSample.ts.timescale - (double)(firstSample.ts.value) / firstSample.ts.timescale;
}

-(double)secondsInQueueAfterCursor3
{
    if ([samples2 isEmpty])
        return 0.0;
    
    KMediaSample *firstSample = lastConsumedSample ? [lastConsumedSample data] : [samples2 objectAtHead];
    KMediaSample *lastSample = [samples2 objectAtTail];
    
    assert(firstSample!=nil);
    assert(lastSample!=nil);
    
    return (double)(lastSample.ts.value) / lastSample.ts.timescale - (double)(firstSample.ts.value) / firstSample.ts.timescale;
}


-(BOOL) checkIsFullAndIsRunning
{
    BOOL result;
    pthread_mutex_lock(&queue_lock);
    
    result = ([self secondsInQueueAfterCursor3] > MAX(self->maxBufferSec/3, MAX(self->startBufferSec[0], self->startBufferSec[1])*2) && isRunning);
        
    pthread_mutex_unlock(&queue_lock);
    return result;
}

-(KResult)pushSample:(KMediaSample *)sample withOrderByTimestamp:(BOOL)orderByTimestamp
{
    pthread_mutex_lock(&queue_lock);
    DLog3(@"queue pushSample %@",sample);
    
    if (orderByTimestamp) {
        [samples2 addOrdered:sample withCompare: ^NSComparisonResult(id a, id b){
            KMediaSample *A = a;
            KMediaSample *B = b;
            
            int32_t res = CMTimeCompare(A.ts, B.ts);
            return res;
        }];
        
    } else {
        [samples2 addObjectToTail:sample];
    }
    
//    if (samplesCur==nil)
//        samplesCur = samples2->_head;
    
    lastTs = sample.ts; // + duration
    
    if (!isRunning) {
        DLog(@"queue NOT RUNNING");
        if ([self secondsInQueueAfterCursor3] > startBufferSec[curStartBufferSecIndex] || sample.eos){
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
//        DLog(@"queue popSample probe=%d", probe);
        
        switch (_state) {
            case KFilterState_STARTED:
                break;
            case KFilterState_STOPPING:
            case KFilterState_STOPPED:
//                DLog(@"queue STOPPED");
                pthread_mutex_unlock(&queue_lock);
                return KResult_InvalidState;
            case KFilterState_PAUSING:
                break;
            case KFilterState_PAUSED:
                break;
        }
        
//        if (error) ...
        
        if (samples2.count==0 || (lastConsumedSample!=nil && lastConsumedSample.next==nil) ){
            DLog3(@"queue popSample NO SAMPLES");
            if (isRunning){
                curStartBufferSecIndex = 1;
            }
            isRunning=FALSE;
            pthread_cond_wait(&queue_cond, &queue_lock);
            continue;
        }
        
        
        if (probe){
            if (lastConsumedSample==nil){
                *sample = [samples2 objectAtHead];
                DLog3(@"queue popSample OK (probe) %@",(*sample));
                pthread_mutex_unlock(&queue_lock);
                return KResult_OK;
            } else if (lastConsumedSample.next!=nil){
                *sample = lastConsumedSample.next.data;
                DLog3(@"queue popSample OK (probe) %@",(*sample));
                pthread_mutex_unlock(&queue_lock);
                return KResult_OK;
            } else {
                assert(0);
            }
        }
        if (_state==KFilterState_STARTED && !isRunning){
//            DLog(@"queue WAIT");
            pthread_cond_wait(&queue_cond, &queue_lock);
            continue;
        }
        
        if (lastConsumedSample==nil){
            *sample = [samples2 objectAtHead];
            DLog3(@"queue popSample OK %@",(*sample));
            lastConsumedSample = samples2->_head;
           
        } else if (lastConsumedSample.next!=nil){
             *sample = lastConsumedSample.next.data;
            DLog3(@"queue popSample OK %@",(*sample));
            lastConsumedSample = lastConsumedSample.next;
        } else {
            assert(0);
        }
        
        while([self secondsInQueue3]>maxBufferSec)
        {
            if (samples2->_head==lastConsumedSample){
                //lastConsumedSample=nil;
                break;
            }
            [samples2 removeObjectFromHead];
        }
        
        pthread_mutex_unlock(&queue_lock);
        return KResult_OK;
    }
}

-(void)flush
{
    pthread_mutex_lock(&queue_lock);
  
    DLog(@"queue FLUSH");
    [samples2 removeAllObjects];
    lastConsumedSample=nil;
    isRunning = FALSE;
    error=nil;
    lastTs=CMTimeMake(0, 1000);
    curStartBufferSecIndex = 0;
    
    
    pthread_mutex_unlock(&queue_lock);
}

///FIXME: key frames! and
-(KLinkedListNode *)findNodeToRewind:(float)sec
{
    CMTime secTo = CMTimeMake(sec*1000, 1000);
  
    
    KLinkedListNode *frameToShow = samples2->_head;
    
    while(frameToShow) {
        KMediaSample *s = [frameToShow data];
        
        int32_t cmp = CMTimeCompare(s.ts, secTo);
        if (cmp==0)
            break;
        
        if (cmp>0){
            if (frameToShow.previous)
                frameToShow = frameToShow.previous;
            else
                frameToShow = nil;
            break;
        }
        
        
        frameToShow=frameToShow.next;
    }
    
    KLinkedListNode *frameToDecode = frameToShow;
    
    while(frameToDecode){
        KMediaSample *s = [frameToDecode data];
        if (s.key)
            break;
        frameToDecode=frameToDecode.previous;
    }
    
    pthread_mutex_unlock(&queue_lock);
    return frameToDecode;
}

-(KResult)canRewindTo:(float)sec
{
    BOOL result = FALSE;
    
    pthread_mutex_lock(&queue_lock);
    KLinkedListNode *found = [self findNodeToRewind:sec];
    if (found!=nil){
        result=TRUE;
    }
    pthread_mutex_unlock(&queue_lock);
    
    return result;
}
-(KResult)rewindTo:(float)sec
{
    KResult result = KResult_ERROR;
    
    pthread_mutex_lock(&queue_lock);
    KLinkedListNode *found = [self findNodeToRewind:sec];
    if (found!=nil){
        if (found.previous)
            lastConsumedSample = found.previous;
        else
            lastConsumedSample = nil;
        
        result = KResult_OK;
        
    }
    
    pthread_mutex_unlock(&queue_lock);
    return result;
}

- (CMTime)endBufferedPosition {
    CMTime result;
    
    pthread_mutex_lock(&queue_lock);
    if ([samples2 isEmpty]) {
        result = lastTs;
    } else {
        KMediaSample *s = [samples2 objectAtTail];
        result = s.ts;
    }
    pthread_mutex_unlock(&queue_lock);
    
    return result;
}

- (CMTime)startBufferedPosition {
    CMTime result;
    
    pthread_mutex_lock(&queue_lock);
    if ([samples2 isEmpty]) {
        result = lastTs;
    } else {
        KMediaSample *s = [samples2 objectAtHead];
        result = s.ts;
    }
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

//-(float)firstStartBufferSec
//{
//    return queue->startBufferSec[0];
//}
//-(void)setFirstStartBufferSec:(float)firstStartBufferSec
//{
//    queue->startBufferSec[0] = firstStartBufferSec;
//}
//-(float)secondStartBufferSec
//{
//    return queue->startBufferSec[1];
//}
//-(void)setSecondStartBufferSec:(float)secondStartBufferSec
//{
//   queue->startBufferSec[1] = secondStartBufferSec;
//}
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

- (instancetype)initWithFirstStartBufferSec:(float)firstStartBufferSec andSecondStartBufferSec:(float)secondStartBufferSec andMaxBufferSec:(float)maxBufferSec
{
    self = [self init];
    if (self) {
        queue->startBufferSec[0] =firstStartBufferSec;
        queue->startBufferSec[1] =secondStartBufferSec;
        queue->maxBufferSec = maxBufferSec;
//        self->_orderByTimestamp = true;
        
        if (queue->maxBufferSec < MAX(queue->startBufferSec[0], queue->startBufferSec[1])*1.2){
            DErr(@"KBufferQueue maxBufferSec too small");
            queue->maxBufferSec = MAX(queue->startBufferSec[0], queue->startBufferSec[1])*1.2;
        }
        
//        self.firstStartBufferSec = firstStartBufferSec;
//        self.secondStartBufferSec = secondStartBufferSec;
    }
    return self;
}




- (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
{
    if (state == KFilterState_STOPPED)
        [queue flush];
   
    [queue onState:state];
}

-(KResult)canSeekTo:(float)sec
{
    return FALSE;
}
-(KResult)seekTo:(float)sec
{
    return KResult_ERROR;
}
-(KResult)canRewindTo:(float)sec
{
    return [queue canRewindTo:sec];
}
-(KResult)rewindTo:(float)sec
{
    return [queue rewindTo:sec];
}

-(KResult)flush
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
    
    if ([queue checkIsFullAndIsRunning]){
        WLog(@"KBufferQueue is full");
        usleep(10000);
        return KResult_OK;
    }

    @autoreleasepool {

        KMediaSample *sample;
        NSError *err;
           
        KResult res = [pin pullSample:&sample probe:NO error:&err];


        if (res!=KResult_OK) {
            [queue pushError:err withOrderByTimestamp:_orderByTimestamp];
            return res;
        }
        
        [queue pushSample:sample withOrderByTimestamp:_orderByTimestamp];
    }
    return KResult_OK;
}


-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin;
{
    return [queue popSample:sample probe:probe];
}

- (CMTime)endBufferedPosition {
    return [queue endBufferedPosition];
}

- (CMTime)startBufferedPosition {
    return [queue startBufferedPosition];
}



@end

