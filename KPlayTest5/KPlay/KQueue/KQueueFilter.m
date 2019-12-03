//
//  KQueueFilter.m
//  kptest
//
//  Created by kuzalex on 4/18/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//
#define MYDEBUG
#include "myDebug.h"

#import "KQueueFilter.h"
//#import "../../Base/KClock.h"

#define MAX_SAMPLES_QUEUE 250
//#define MIN_SAMPLES_QUEUE 25


@implementation KQueueFilter{
    NSMutableArray *samples;
    NSError *_error;
    KMediaType *type;
    dispatch_semaphore_t _sem;
   // KSimpleClock *myclock;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        type = [[KMediaType alloc]initWithName:@"text"];
        [self.outputPins addObject:[ [KOutputPin alloc] initWithFilter:self] ];
        [self.inputPins addObject:[ [KInputPin alloc] initWithFilter:self] ];
//        myclock = [[KSimpleClock alloc] init];
//        [myclock start];
//        [myclock pause];
//
 
        samples = [[NSMutableArray alloc]init];
        _error=nil;
        _sem = dispatch_semaphore_create(0);
        // we want to work in PAUSED state
       // processInPause = TRUE;
        //FIXME: _min_samples_queue NOT WORKS!
        //FIXME: _min_samples_queue NOT WORKS!
        //FIXME: _min_samples_queue NOT WORKS!
        //_min_samples_queue = MIN_SAMPLES_QUEUE;
        _max_samples_queue = MAX_SAMPLES_QUEUE;
        
    }
    return self;
}
//-(KClock *)clock
//{
//    return myclock;
//}
//-(void)onStateChanged:(KFilterState)state
//{
//    @synchronized (self) {
//        switch (state) {
//            case KFilterState_STOPPED:
//                @synchronized (self) {
//                    [samples removeAllObjects];
//                    _error=nil;
//                }
//                [myclock stop];
//                break;
//            case KFilterState_PAUSED:
//                [myclock pause];
//                break;
//            case KFilterState_STARTED:
//                [myclock start];
//                [myclock pause];
//                break;
//
//            default:
//                break;
//        }
//    }
//
//}

- (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
{
    switch (_state) {
        case KFilterState_STOPPED:
            @synchronized (self) {
                [samples removeAllObjects];
                _error=nil;
            }
            break;
        case KFilterState_STOPPING:
            break;
        case KFilterState_PAUSING:
            break;
        case KFilterState_STARTED:
            break;
        case KFilterState_PAUSED:
            break;
    }
}

-(KResult)seek:(float)sec
{
    @synchronized (self) {
        [samples removeAllObjects];
    }
    return KResult_OK;
}



-(void) insertSample:(KMediaSample *)sample
{
  //  DLog(@"%@ ADD ts=%lld", self, sample.ts);
    
    if (_sorted){
        NSComparator comparator = ^(id obj1, id obj2) {
            KMediaSample *a = (KMediaSample *)obj1;
            KMediaSample *b = (KMediaSample *)obj2;
            
            if (a.ts > b.ts) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            
            if (a.ts < b.ts) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedSame;
        };
        
        NSUInteger newIndex = [samples indexOfObject:sample
                                       inSortedRange:(NSRange){0, [samples count]}
                                             options:NSBinarySearchingInsertionIndex
                                     usingComparator:comparator];
        
        [samples insertObject:sample atIndex:newIndex];
        // DLog(@"%@ insert ts=%ld",[self name], sample.ts);
        
    } else {
        [samples addObject:sample];
        //DLog(@"%@ insert ts=%ld",[self name], sample.ts);
    }
}



//@protocol KBufferInfo
//-(float) minTsSec
//{
//     @synchronized (self) {
//         if (_state==KFilterState_STOPPED || samples==nil || [samples count]==0)
//             return 0;
//         KMediaSample *s =samples.firstObject;
//
//         return 1.0*s.ts/s.timescale;
//     }
//}
//-(float) maxTsSec
//{
//    @synchronized (self) {
//        if (_state==KFilterState_STOPPED || samples==nil || [samples count]==0)
//            return 0;
//        KMediaSample *s =samples.lastObject;
//
//        return 1.0*s.ts/s.timescale;
//    }
//
//}

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

    NSUInteger scount;





    @autoreleasepool {

        BOOL queue_is_full = FALSE;

        @synchronized (self) { queue_is_full =  ([samples count]>=_max_samples_queue); }

        if (!queue_is_full)
        {
            KMediaSample *sample;
            NSError *err;
           
            KResult res = [pin pullSample:&sample probe:NO error:&err];


            if (res!=KResult_OK) {
                 @synchronized (self) {
                    _error = err;
                }
                dispatch_semaphore_signal(_sem);
                //[myclock start];
                return res;
            }

            @synchronized (self) {
                [self insertSample:sample];
            }
            dispatch_semaphore_signal(_sem);

        }

        @synchronized (self) {
            scount=[samples count];
        }

//        if (scount>=_min_samples_queue && myclock.state == KFilterState_PAUSED && self.state == KFilterState_STARTED){
//                [myclock start];
//                // dispatch_semaphore_signal(_sem);
//                DLog(@"%@ START clock. count = %d", self, (int)scount);
//            }




        if (queue_is_full){
            // DLog(@"%@ QUEUE IS FULL", [self name]);
            usleep(10000);
            //next tick or stop/pause...
            return KResult_OK;
        }

        return KResult_OK;
    }
}


-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin;
{
    while(1)
    {
        @synchronized (self) {
            
            if (_error){
                *error = _error;
                _error = nil;
                return KResult_ERROR;
           // } else if ([samples count]>_min_samples_queue || (>0 && probe)){
            } else if ([samples count]>0){
                *sample = [samples objectAtIndex:0];
                if (!probe)
                    [samples removeObjectAtIndex:0];
                return KResult_OK;
            } //else if (myclock.state == KFilterState_STARTED){
//                [myclock pause];
//                //dispatch_semaphore_signal(_sem);
//                DLog(@"%@ PAUSE clock", self);
//            }
        }
        
        KResult res;
        if ( (res = [self waitSemaphoreOrState:_sem]) != KResult_OK ){
            
            return res;
        }
    }
    //return KResult_ERROR;
}





@end
