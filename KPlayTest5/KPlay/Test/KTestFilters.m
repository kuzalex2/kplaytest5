//
//  KTestFilters.m
//  KPlayer
//
//  Created by test name on 16.04.2019.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#define MYDEBUG
#include "myDebug.h"

#import "KTestFilters.h"



//@interface OutSampleQueue : NSObject
////    -(instancetype)init;
////    -(instancetype)initWithMinCount:(size_t)minCount;
////    -(void)removeAllObjects;
////    -(void) queueSample:(KMediaSample *)sample;
////    -(void) queueError:(NSError *)error;
////    -(BOOL)pullSample:(KMediaSample **)sample probe:(BOOL)probe error:(NSError **)error;
////    -(BOOL)checkSample:(KMediaSample **)sample probe:(BOOL)probe error:(NSError **)error;
//@end
//
//
//@implementation OutSampleQueue {
//    NSMutableArray *_samples;
//    NSError *_error;
//    dispatch_semaphore_t _sem;
//    size_t _min_count;
//}
//
//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//        _min_count=0;
//        _samples = [[NSMutableArray alloc]init];
//        _sem = dispatch_semaphore_create(0);
//        _error=nil;
//
//    }
//    return self;
//}
//
//- (instancetype)initWithMinCount:(size_t)minCount
//{
//    self = [super init];
//    if (self) {
//        _min_count=minCount;
//        _samples = [[NSMutableArray alloc]init];
//        _sem = dispatch_semaphore_create(0);
//        _error=nil;
//
//    }
//    return self;
//}
//
//-(void)removeAllObjects
//{
//    @synchronized (self) {
//        [_samples removeAllObjects];
//        _error = nil;
//        dispatch_semaphore_signal(_sem);
//    }
//}
//
//
//-(void) putSample:(KMediaSample *)sample
//{
//    @synchronized (self) {
//        [_samples addObject:sample];
//        dispatch_semaphore_signal(_sem);
//    }
//}
//
//-(void) putError:(NSError *)error
//{
//    @synchronized (self) {
//        _error = error;
//        dispatch_semaphore_signal(_sem);
//    }
//}
//
//
//-(BOOL)getSample:(KMediaSample **)sample probe:(BOOL)probe error:(NSError **)error
//{
//    while (1)
//    {
//        @synchronized (self) {
//            if ([_samples count]>0){
//                *sample = [_samples objectAtIndex:0];
//                if (!probe)
//                    [_samples removeObjectAtIndex:0];
//                else
//                    dispatch_semaphore_signal(_sem);
//                return TRUE;
//            } else if (_error!=nil) {
//                *error = _error;
//                _error=nil;
//                return TRUE;
//            } else {
//                dispatch_semaphore_wait(_sem, DISPATCH_TIME_FOREVER);
//            }
//        }
//    }
//}
//@end

/*
 *   KTestSourceFilter
 *
 *
 */

@implementation KTestSourceFilter{
   
    KMediaType *type;
   // OutSampleQueue *out_queue;
    
    //size_t sample_count_before_error;
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //DLog(@"<%@> init",[self name]);
        type = [[KMediaType alloc]initWithName:@"text"];
        [self.outputPins addObject:[
                                    [KOutputPin alloc] initWithFilter:self]
         ];
       // out_queue = [[OutSampleQueue alloc] initWithMinCount:5];
    }
    return self;
}

//- (instancetype)initWithNumberOutputPins:(size_t)nPins
//{
//    self = [self init];
//    if (self) {
//        for (size_t i=0;i<nPins-1;i++)
//            [self.outputPins addObject:[
//                                    [KOutputPin alloc] initWithFilter:self]
//            ];
//    }
//    return self;
//}

-(KMediaType *)getOutputMediaType
{
    return type;
}

//-(KResult)onThreadTick:(NSError *__strong*)ppError
//{
//   
//    KMediaSample *sample= [[KMediaSample alloc]init];
//    sample.type = type;
//    sample.data =  [[NSData alloc]initWithBytes:"abc" length:3];
//    sample.ts = 0;
//    
// 
//    
//    if (sample_count_before_error++==20){
//        NSError *test_error=[NSError errorWithDomain:@"com.kuzalex" code:200 userInfo:@{@"Error reason": @"Test Error"}];
//        [out_queue queueError:test_error];
//    }else {
//        
//        [out_queue queueSample:sample];
//    }
//    usleep(100000);
//    return KResult_OK;
//}
//
//// on stopped/paused -> dispatch_semaphore_signal(_sem);
//
//
-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error;
{
    KMediaSample *mySample= [[KMediaSample alloc]init];
    mySample.type = type;
    mySample.data =  [[NSData alloc]initWithBytes:"abc" length:3];
    mySample.ts = 0;
    
    *sample = mySample;
    return KResult_OK;
    
}


@end


/*
 *   KTestUrlSourceFilter
 *
 *
 */

@implementation KTestUrlSourceFilter{
   
    NSURL *_url;
    KMediaType *_type;
    NSURLSessionDownloadTask *_download_task;
    dispatch_semaphore_t _sem;
    KMediaSample *_outSample;
    NSError *_error;
}


-(instancetype)initWithUrl:(NSString *)url
{
    self = [super init];
    if (self) {
        self->_type = nil;
        //self->outSample = nil;
        self->_url = [[NSURL alloc] initWithString:url];
        
        if (!self->_url)
            return nil;
        
        KOutputPin *output = [[KOutputPin alloc] initWithFilter:self ];
        [self.outputPins addObject:output];
        [self onStateChanged:self state:_state];
    }
    return self;
}



-(KMediaType *)getOutputMediaType
{
    return _type;
}

- (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
{
    if (state==KFilterState_STOPPING || state==KFilterState_STOPPED){
        if (_download_task) {
            [_download_task cancel];
        }
    }
}


-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error;
{
    if (_outSample==nil)
    {
        _sem = dispatch_semaphore_create(0);
        _outSample = nil;
        _error = nil;
        DLog(@"<%@> Downloading %@", [self name], self->_url.host);
        _download_task = [[NSURLSession sharedSession] downloadTaskWithURL:_url
                                                         completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error)
                          {
            if (error==nil){
                DLog(@"<%@> Downloaded %@", [self name], self->_url.host);
                ///FIXME
                self->_type = [[KMediaType alloc]initWithName:@"video/mp2t"];
                
                self->_outSample = [[KMediaSample alloc] init];
                self->_outSample.type = self->_type;
                self->_outSample.data =  [NSData dataWithContentsOfURL:location];
                //sample.discontinuity = insample.discontinuity;
                
                self->_download_task=nil;
                
            } else {
                DLog(@"<%@> Error: %@", [self name], error);
                self->_outSample = nil;
                self->_error = error;
                self->_download_task=nil;
            }
            dispatch_semaphore_signal(self->_sem);
        }];
        // 4
        [_download_task resume];
        
        KResult res;
        if ( (res = [self waitSemaphoreOrState:_sem]) != KResult_OK ){
            if (_download_task) {
                [_download_task cancel];
            }
            //*error = res;
            return res;
        }
    }
    
    if (_outSample == nil) {
        *error = _error;
        return KResult_ERROR;
    }
    
    *sample = _outSample;
    if (!probe)
        _outSample = nil;
    return KResult_OK;
    
}


@end





/*
 *   KTestSinkFilter
 *
 *
 */


@implementation KTestSinkFilter{
    int64_t _last_sample_ts;
    int64_t _last_sample_timescale;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self.inputPins addObject:[[KInputPin alloc] initWithFilter:self]];
        self->_last_sample_ts=0;
        self->_last_sample_timescale=1000;
    }
    return self;
}

-(BOOL)isInputMediaTypeSupported:(KMediaType *)type
{
    // any type
    return TRUE;
}

//-(void)onStateChanged:(KFilterState)state
//{
//    if (state==KFilterState_STARTED)
//        _consumed_samples = 0;
//}

-(KResult) onThreadTick:(NSError *__strong*)ppError
{
    @autoreleasepool {
        KMediaSample *sample;
       // NSError *error;
        KResult res;
        
        KInputPin *pin = [self getInputPinAt:0];
        res = [pin pullSample:&sample probe:NO error:ppError];
        
        if (res != KResult_OK) {
            return res;
        }
        
        DLog(@"%@ <%@> got sample type=%@ %ld bytes, ts=%lld/%d", self, [self name], sample.type.name, [sample.data length], sample.ts, sample.timescale);
        
        _last_sample_ts = sample.ts;
        _last_sample_timescale = sample.timescale;
        _consumed_samples++;
        usleep(10000);

        return KResult_OK;
    }
}

///
///  KPlayPositionInfo
///

-(int64_t)position
{
   
    return _last_sample_ts;
}

-(int64_t)timeScale
{
  
    return _last_sample_timescale;
}

- (BOOL)isRunning {
    return TRUE;
}

@end






/*
 *   KTestTransformFilter
 *
 *
 */

// audio-stream/adts

@implementation KTestTransformFilter {
    KMediaType *mytype;
}


-(BOOL)isInputMediaTypeSupported:(KMediaType *)type
{
    mytype = type;
    return TRUE;
}

-(KMediaType *)getOutputMediaType
{
    return mytype;
}

-(KResult)onTransformSample:(KMediaSample *__strong*)sample
{
    return KResult_OK;
}

@end







