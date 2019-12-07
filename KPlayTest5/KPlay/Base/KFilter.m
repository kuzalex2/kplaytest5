////
//  KFilter.m
//  KPlayer
//
//  Created by test name on 15.04.2019.
//  Copyright © 2019 kuzalex. All rights reserved.
//


#define MYDEBUG
#include "myDebug.h"

#import "KFilter.h"
#import "KPin.h"

NSString *KFilterState2String(KFilterState state)
{
    switch (state) {
       // case KFilterState_NONE:
         //   return @"KFilterState_NONE";
        case KFilterState_STARTED:
            return @"KFilterState_STARTED";
        case KFilterState_STOPPING:
            return @"KFilterState_STOPPING";
        case KFilterState_PAUSING:
            return @"KFilterState_PAUSING";
        case KFilterState_PAUSED:
            return @"KFilterState_PAUSED";
        case KFilterState_STOPPED:
            return @"KFilterState_STOPPED";
    }
}

@interface KFilter()
{
    
}
@end


@implementation KFilter

- (instancetype)init
{
    self = [super init];
    if (self) {
        _inputPins =  [NSMutableArray new];
        _outputPins =  [NSMutableArray new];
        _state_mutex = [NSObject new];
        _pull_lock = [NSObject new];
        
        _state = KFilterState_STOPPED;
        //if ([self respondsToSelector:@selector(onStateChanged:state:)]){
          //  [self onStateChanged:self state:_state];
        //}
        
        
    }
    return self;
}

- (KFilterState) state
{
    @synchronized(_state_mutex) {
        return _state;
    }
}



- (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
{

}

-(KResult)waitSemaphoreOrState:(dispatch_semaphore_t)sem
{
    while (1)
    {
        @synchronized(_state_mutex) {
            switch (_state) {
                case KFilterState_STARTED:
                    break;
                case KFilterState_STOPPING:
                    return KResult_InvalidState;
                case KFilterState_PAUSING:
                    break;
                case KFilterState_PAUSED:
                    break;
                case KFilterState_STOPPED:
                    return KResult_InvalidState;
            }
        }
        if (dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC))==0)
            return KResult_OK;
    }
}

-(KResult)pullSampleInternal:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(KOutputPin*)pin
{
    @synchronized(_state_mutex) {
        switch (_state) {
            case KFilterState_STOPPING:
            case KFilterState_STOPPED:
                return KResult_InvalidState;
            case KFilterState_PAUSING:
            case KFilterState_STARTED:
            case KFilterState_PAUSED:
                break;
        }
    }
    
    @synchronized(_pull_lock) {
        return [self pullSample:sample probe:probe error:error fromPin:pin];
    }
}

-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(KOutputPin*)pin
{
    DErr(@"pullSample at %@ not implemented", [self name]);
    return KResult_ERROR;
}

-(BOOL)isInputMediaTypeSupported:(KMediaType *)type
{
    DErr(@"isInputMediaTypeSupported at %@ not implemented", [self name]);
    return FALSE;
}

-(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin
{
    DErr(@"getOutputMediaType at %@ not implemented", [self name]);
    return nil;
}

-(NSString *)name
{
    return NSStringFromClass([self class]);
}

- (KOutputPin *) getOutputPinAt:(size_t)i
{
    if (i<[_outputPins count])
        return _outputPins[i];
    
    return nil;
}

- (KInputPin *) getInputPinAt:(size_t)i
{
    if (i<[_inputPins count])
        return _inputPins[i];
    
    return nil;
}




-(void)setStateAndNotify:(KFilterState)state
{
    KFilterState prevState;
    @synchronized(_state_mutex) {
        prevState = _state;
        _state = state;
        NSLog(@"<%@> setStateAndNotify %@", [self name], KFilterState2String(state));
    }
    if (prevState!=state && [self respondsToSelector:@selector(onStateChanged:state:)]){
        [self onStateChanged:self state:state];
    }
    if (prevState!=state && [self.events respondsToSelector:@selector(onStateChanged:state:)]) {
        [self.events onStateChanged:self state:state];
    }
}

-(KResult)start
{
    [self setStateAndNotify:KFilterState_STARTED];
    

    return KResult_OK;
}
-(KResult)pause;//:(BOOL)waitUntilPaused
{
    [self setStateAndNotify:KFilterState_PAUSED];
    return KResult_OK;
}
-(KResult)stop;//:(BOOL)waitUntilStopped
{
    while (1)
    {
        @synchronized(_state_mutex) {
            switch (_state) {
                case KFilterState_STOPPED:
                    return KResult_OK;
                    
                case KFilterState_PAUSING:
                    
                    goto sleep;
                    //                    return KResult_InvalidState;
                    
                case KFilterState_PAUSED:
                case KFilterState_STARTED:
                    [self setStateAndNotify:KFilterState_STOPPING];
                    //_stopping_sem = dispatch_semaphore_create(0);
                    break;
                    
                case KFilterState_STOPPING:
                    break;
            }
        }
        
      //  if (!waitUntilStopped)
//            return KResult_OK;
        
         @synchronized(_pull_lock) {
             [self setStateAndNotify:KFilterState_STOPPED];
         }

        continue;
    sleep:
        //wait until paused
        usleep(10000);
        
    }
}
-(KResult)seek:(float)sec
{
    return KResult_OK;
}

@end











@implementation KThreadFilter {
    dispatch_semaphore_t _stopping_sem;
    dispatch_semaphore_t _pausing_sem;
    KResult _thread_error;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->_thread_error = KResult_OK;
    }
    return self;
}

-(KResult) onThreadTick:(NSError *__strong*)ppError
{
    return KResult_OK;
}






-(KResult)start
{
    @synchronized(_state_mutex) {
        switch (_state) {
            case KFilterState_STARTED:
                return KResult_OK;
            case KFilterState_STOPPING:
            case KFilterState_PAUSING:
                return KResult_InvalidState;
            case KFilterState_PAUSED:
                [self setStateAndNotify:KFilterState_STARTED];
                return KResult_OK;
            case KFilterState_STOPPED:
                [self setStateAndNotify:KFilterState_STARTED];
                [self StartThread];
                return KResult_OK;
        }
    }
}

-(KResult)stop;//:(BOOL)waitUntilStopped
{
    while (1)
    {
        @synchronized(_state_mutex) {
            switch (_state) {
                case KFilterState_STOPPED:
                    return KResult_OK;
                
                case KFilterState_PAUSING:
                    
                    goto sleep;
//                    return KResult_InvalidState;
                    
                case KFilterState_PAUSED:
                case KFilterState_STARTED:
                    [self setStateAndNotify:KFilterState_STOPPING];
                    _stopping_sem = dispatch_semaphore_create(0);
                    break;
                    
                case KFilterState_STOPPING:
                    break;
            }
        }
        
//        if (!waitUntilStopped)
//            return KResult_OK;
        
        //dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC)
        dispatch_semaphore_wait(_stopping_sem, DISPATCH_TIME_FOREVER);
        continue;
    sleep:
        //wait until paused
        usleep(10000);
        
    }
}

-(void)StartThread
{
    _thread_error = KResult_OK;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self threadProc];
    });
}

-(KResult)pause;//:(BOOL)waitUntilPaused
{
    BOOL first=TRUE;
    while (1)
    {
        @synchronized(_state_mutex) {
            NSLog(@"<%@>State is %@", [self name], KFilterState2String(_state));
            switch (_state) {
                case KFilterState_PAUSED:
                    if (!first)
                        return _thread_error;
                    
                    [self setStateAndNotify:KFilterState_PAUSING];
                    _pausing_sem = dispatch_semaphore_create(0);
                    break;
                    
                    
                
                case KFilterState_STOPPING:
                    return KResult_InvalidState;
                    
                case KFilterState_STOPPED:
                    [self setStateAndNotify:KFilterState_PAUSING];
                    _pausing_sem = dispatch_semaphore_create(0);
                    [self StartThread];
                   
                    break;
                case KFilterState_STARTED:
                    [self setStateAndNotify:KFilterState_PAUSING];
                    _pausing_sem = dispatch_semaphore_create(0);
                    break;
                    
                case KFilterState_PAUSING:
                    break;
            }
        }
        
//        if (!waitUntilPaused)
//            return _thread_error;
        
        first=FALSE;
        //dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC)
       // NSLog(@"Here 1");
        dispatch_semaphore_wait(_pausing_sem, DISPATCH_TIME_FOREVER);
      //  NSLog(@"Here 2");
    }
}



-(void)threadProc {
    
   // BOOL error = FALSE;
    NSError *pError=nil;
    
    while(1)
    {
        BOOL doThreadTick = FALSE;
        
        @synchronized(_state_mutex) {
            switch (_state) {
                case KFilterState_STOPPED:
                    assert(0);
                    break;
                case KFilterState_PAUSING:
                case KFilterState_STARTED:
                    doThreadTick = TRUE;
                    break;
                default:
                    doThreadTick = FALSE;
                    break;
            }
        }
            
            
        if (_thread_error!=KResult_OK || !doThreadTick) {
           // DLog(@"Here...");
            usleep(10000);
            
        } else {
            KResult res = [self onThreadTick:&pError];
            if (res != KResult_OK) {
                if ([self.events respondsToSelector:@selector(onError:result:error:)]) {
                    [self.events onError:self result:res error:pError];
                }
                _thread_error = res;
            }
        }
            
        @synchronized(_state_mutex) {
            switch (_state) {
                case KFilterState_PAUSING:
                    if (doThreadTick || _thread_error!=KResult_OK){
                        [self setStateAndNotify:KFilterState_PAUSED];
                        // NSLog(@"Here 3");
                        dispatch_semaphore_signal(_pausing_sem);
                        // NSLog(@"Here 4");
                    }
                    break;
                    
                case KFilterState_STOPPING:
                    goto stopping;
                    
                case KFilterState_STOPPED:
                case KFilterState_STARTED:
                case KFilterState_PAUSED:
                    break;
            }
        }
    }
    
stopping:
    @synchronized(_state_mutex) {
        assert(_state == KFilterState_STOPPING);
    }
    DLog(@"<%@> threadProc stopping", [self name]);
    @synchronized(_pull_lock) {
        [self setStateAndNotify:KFilterState_STOPPED];
    }
  //  [self setStateAndNotify:KFilterState_STOPPED];
    dispatch_semaphore_signal(_stopping_sem);
    
    
}



@end






@implementation KTransformFilter

- (instancetype)init
{
    self = [super init];
    if (self) {
        KOutputPin *output = [[KOutputPin alloc] initWithFilter:self ];
        [self.outputPins addObject:output];

        KInputPin *input = [[KInputPin alloc] initWithFilter:self];
        [self.inputPins addObject:input];
    }
    return self;
}

-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin;
{

    if ([self.inputPins count] < 1 )
        return KResult_ERROR;

    KResult res = [self.inputPins[0] pullSample:sample probe:probe error:error];

    if (res != KResult_OK)
        return res;

    return [self onTransformSample:sample error:error];
}

-(KResult)onTransformSample:(KMediaSample **)sample error:(NSError *__strong*)error
{
    return KResult_OK;
}

-(BOOL)isInputMediaTypeSupported:(KMediaType *)type
{
    return FALSE;
}

-(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin
{
    return nil;
}


@end
