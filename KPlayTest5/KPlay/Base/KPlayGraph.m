////
////  KPlayGraph.m
////  KPlayer
////
////  Created by test name on 26.04.2019.
//  Copyright © 2019 kuzalex. All rights reserved.
////
// FIXME: stopfail on other sync_mutex states!

#import <Foundation/Foundation.h>

#import "KTestFilters.h"
#import "KPlayGraph.h"

//#define MYWARN
#define MYDEBUG
#include "myDebug.h"


@implementation KPlayGraphChainBuilder {
    NSObject * _Nonnull _async_mutex;
}

    

   
    bool _suppress_error = false;

    -(void) setEvents: (id<KPlayerEvents>)e
    {
        _events = e;
        if ([self.events respondsToSelector:@selector(onStateChanged:)]) {
            [self.events onStateChanged:_state];
        }
    }
    

    - (void)onError:(KFilter *)filter result:(KResult)result error:( NSError * _Nullable )error
    {
        //FIXME: process filter errors here and push to next
        DLog(@"<%@> onError %d %@", [filter name], result, error);
        if (_suppress_error)
            return;
        if ([self.events respondsToSelector:@selector(onError:)]) {
            [self.events onError:error];
        }
    }
    


    - (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
    {
        //FIXME: process filter's change of state here and push to next
       // if ([filter.events respondsToSelector:@selector(onStateChanged:state:)])
         //   [filter.events onStateChanged:filter state:state];
       // DLog(@"<%@> onStateChanged %@ ", [filter name], KFilterState2String(state) );
        
        
//        if (_chain.count > 0 && filter == [_chain lastObject]){
//            if (state == KFilterState_PAUSED && [self state]!=KGraphState_SEEKING){
//                [self setStateAndNotify:KGraphState_PAUSED];
//                ///FIXME:!!!!!!!! all others
//                ///FIXME: mutex
//            }
//        }
    }


    -(void)setStateAndNotify:(KGraphState)state
    {
        KGraphState prevState;
        @synchronized(_state_mutex) {
            prevState = _state;
            _state = state;
        }
    
        if (prevState!=state && [self.events respondsToSelector:@selector(onStateChanged:)]) {
            [self.events onStateChanged:state];
        }
    }
    
    -(void)notifyError:(NSError *)error
    {
        if (_suppress_error)
            return;
        if ([self.events respondsToSelector:@selector(onError:)]) {
            [self.events onError:error];
        }
    }

    
    - (instancetype)init
    {
        self = [super init];
        if (self) {
            _state_mutex = [NSObject new];
            _async_mutex = [NSObject new];
            _state = KGraphState_NONE;
            _flowchain = [[NSMutableArray alloc]init];
            _connectchain= [[NSMutableArray alloc]init];
        }
        return self;
    }

    +(BOOL)connectFilters:(KFilter *)src :(KFilter *)dst :(size_t)dst_pin_index
    {
        KPin *pin  = [dst getInputPinAt:dst_pin_index];
        if (pin==nil){
            DErr(@"No inpin %ld at %@",dst_pin_index,dst);
            return FALSE;
        }
        
        for (KPin *pout in src.outputPins)
        {
            if ([pout connectTo:pin] )
                return TRUE;
            
              
        }
        
        DErr(@"failed to connect (%@)->(%@)%ld", [src name], [dst name], dst_pin_index);
        return FALSE;
    }
   
   

    +(BOOL)connectFilters:(KFilter *)src :(size_t)src_pin_index :(KFilter *)dst :(size_t)dst_pin_index
    {
        KPin *pout = [src getOutputPinAt:src_pin_index];
        KPin *pin  = [dst getInputPinAt:dst_pin_index];
        
        
        if (pout==nil){
            DErr(@"No outpin %ld at %@",src_pin_index,src);
            return FALSE;
        }
        
        if (pin==nil){
            DErr(@"No inpin %ld at %@",dst_pin_index,dst);
            return FALSE;
        }
        
        if (! [pout connectTo:pin] ) {
            DErr(@"failed to connect (%@)%ld->(%@)%ld", [src name], src_pin_index, [dst name], dst_pin_index);
            return FALSE;
        }
        
        return TRUE;
    }

    -(KResult)prepareFilter:(KFilter *)f
    {
        KMediaSample *sample;//FIXME: autorelease?
        NSError *error;
        KResult res;
        
        f.events = self;
        
        DLog(@"<%@> pausing", [f name]);
        if ((res = [f pause]) != KResult_OK ) {
            return res;
        }
        
        for (KOutputPin* p in f.outputPins) {
            if ((res = [f pullSample:&sample probe:YES error:&error fromPin:p]) != KResult_OK) {
                return res;
            }
        }
        
        return KResult_OK;
    }





    - (void)seekSync:(float)sec prevState:(KGraphState)prevState
    {
        @synchronized (_async_mutex) {
            
            KResult res;

            switch (prevState) {
                case KGraphState_PAUSED:
                case KGraphState_EOF:
                    break;
                case KGraphState_STARTED:
                    {
                        for (KFilter* filter in  [_flowchain reverseObjectEnumerator] ) {
                            DLog(@"<%@> pausing", [filter name]);
                            res = [filter pause];
                            if (res!=KResult_OK) {
                                DLog(@"<%@> pause failed", [filter name]);
                                
                                [self notifyError: KResult2Error(res)];
                                [self stop];
                                return;
                                
                            }
                        }
                        
                        DLog(@"ALL PAUSED. start seeking");
                    }
                    break;
                default:
                    assert(0);
                    return;
            }
            
            int I;
            for (I=((int)_flowchain.count)-1;I>=0;I--)
            {
                KFilter* filter = _flowchain[I];
                
                DLog(@"<%@> try rewind to %f", [filter name], sec);
                res = [filter rewindTo:sec];
                if (1 && res==KResult_OK){
                    break;
                }
            }
            
            for (int j=I+1;j<(int)_flowchain.count;j++){
                KFilter* filter = _flowchain[j];
                DLog(@"<%@> flushing", [filter name]);
                res = [filter flush];
                if (res!=KResult_OK) {
                    DLog(@"<%@> flush failed", [filter name]);
                    
                    [self notifyError: KResult2Error(res)];
                    [self stop];
                    return;
                }
                
                DLog(@"<%@> seeking", [filter name]);
                res = [filter seek:sec];
                if (res!=KResult_OK) {
                    DLog(@"<%@> seek failed", [filter name]);
                    
                    [self notifyError: KResult2Error(res)];
                    [self stop];
                    return;
                }
            }
            
            for (KFilter* filter in _flowchain)
            {
                DLog(@"<%@> pausing", [filter name]);
                res = [filter pause];
                if (res!=KResult_OK) {
                    DLog(@"<%@> pause failed", [filter name]);
                    
                    [self notifyError: KResult2Error(res)];
                    [self stop];
                    return;
                }
            }
            
            switch (prevState) {
                case KGraphState_STOPPED:
                    [self setStateAndNotify:KGraphState_STOPPED];
                    break;
                case KGraphState_PAUSING:
                case KGraphState_PAUSED:
                
                    [self setStateAndNotify:KGraphState_PAUSED];
                    break;
                case KGraphState_STARTED:
                case KGraphState_EOF:
                
                    [self setStateAndNotify:KGraphState_PAUSED];
                    [self startPlaying];
                    break;
                default:
                    assert(false);
            }
            
        }
        return;

    }
     

    - (void)buildGraphSync:(NSString * _Nonnull)url autoStart:(BOOL)autoStart
    {
        @synchronized (_async_mutex) {
            KResult res;
            
            for (NSMutableArray<KFilter*> *chain in _connectchain){

                for (size_t i = 0; i< chain.count; i++)
                {
                    DLog(@"KTestGraphChainBuilder Prepare %@", [chain[i] name]);
                    if ( (res=[self prepareFilter:chain[i]]) != KResult_OK ) {
                        DLog(@"<%@> Prepare failed ", [chain[i] name]);
                        
                        [self notifyError: KResult2Error(res)];
                        [self setStateAndNotify:KGraphState_NONE];
                        return;
                    }
                    
                    if ( i+1 < chain.count ) {
                        DLog(@"KPlayGraphChainBuilder Connecting %@ -> %@", [chain[i] name], [chain[i+1] name]);
                        if (![KPlayGraphChainBuilder connectFilters:chain[i] :chain[i+1] :0] ) {
                            DLog(@"Connect failed");
                            [self notifyError: KResult2Error(res)];
                            [self setStateAndNotify:KGraphState_NONE];
                            return;
                        }
                    }
                }
            }
            
            
            for (size_t i = 0; i< _flowchain.count; i++) {
                if (self.mediaInfo == nil) {
                    if ([_flowchain[i] conformsToProtocol:@protocol(KPlayMediaInfo) ]) {
                        self.mediaInfo = (id<KPlayMediaInfo> ) _flowchain[i];
                    }
                }
                if (self.positionInfo == nil) {
                    if ([_flowchain[i] conformsToProtocol:@protocol(KPlayPositionInfo) ]) {
                        self.positionInfo = (id<KPlayPositionInfo> ) _flowchain[i];
                    }
                }
//                if (self.bufferPositionInfo == nil) {
//                    if (self.bufferPositionInfo == nil && [_flowchain[i] conformsToProtocol:@protocol(KPlayBufferPositionInfo) ]) {
//                        self.bufferPositionInfo = (id<KPlayBufferPositionInfo> ) _flowchain[i];
//                    }
//                }
            }
            
            if (self.positionInfo!=nil){
                for (KFilter *f in _flowchain){
                    f.clock = self.positionInfo;
                }
            }
            
            
            [self setStateAndNotify:KGraphState_PAUSED];
            
            if (autoStart) {
                [self startPlaying];
                
            }
        }
    }






    //
    //


    

    - (KResult)startPlaying
    {
        KResult res;
        
        for (size_t i = 0; i< _flowchain.count; i++)
        {
            DLog(@"KTestGraphChainBuilder startPlaying %@", [_flowchain[i] name]);
            if ((res = [_flowchain[i] start]) != KResult_OK){
                [self notifyError: KResult2Error(res)];
                [self stop];
                return res;
            }
        }

        [self setStateAndNotify:KGraphState_STARTED];
        
        return KResult_OK;
    }

    - (KResult)startPlayingWithPauseSync
    {
        @synchronized (_async_mutex) {
            KResult res;
            
            
            
            for (size_t i = 0; i< _flowchain.count; i++)
            {
                DLog(@"KTestGraphChainBuilder pausing %@", [_flowchain[i] name]);
                if ((res = [_flowchain[i] pause]) != KResult_OK){
                    [self notifyError: KResult2Error(res)];
                    [self stop];
                    return res;
                }
            }
            
            [self setStateAndNotify:KGraphState_PAUSED];
            
            return [self startPlaying];
        }
    }

    

    
    

    




    - (KResult)pause
    {
        _suppress_error = false;
        BOOL forward;
        @synchronized (_state_mutex) {
            switch (_state) {
                case KGraphState_NONE:
                case KGraphState_BUILDING:
                case KGraphState_STOPPING:
                case KGraphState_PAUSING:
                case KGraphState_SEEKING:
                case KGraphState_EOF:
                    DErr(@"Invalid State");
                    return KResult_InvalidState;
                case KGraphState_STOPPED:
                case KGraphState_PAUSED:
                    forward=TRUE;
                    [self setStateAndNotify:KGraphState_PAUSING];
                    break;
                case KGraphState_STARTED:
                    forward=FALSE;
                    [self setStateAndNotify:KGraphState_PAUSING];
                    break;
        
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            {
                @synchronized (self->_async_mutex) {
                    KResult res;
                    for (KFilter* filter in forward ? self->_flowchain : [self->_flowchain reverseObjectEnumerator]) {
                        DLog(@"<%@> pausing", [filter name]);
                        res = [filter pause];
                        if (res!=KResult_OK) {
                            DLog(@"<%@> pause failed", [filter name]);
                            
                            [self notifyError: KResult2Error(res)];
                            [self stop];
                            
                            return ;
                        }
                    }
                    
                    
                   
                    DErr(@"Here paused");
#ifdef MYDEBUG
                    for (KFilter* filter in self->_flowchain) {
                        DLog(@"<%@> state is %@", [filter name], KFilterState2String([filter state]));
                    }
#endif
                    
                    [self setStateAndNotify:KGraphState_PAUSED];
                }
            }
        });
        
        return KResult_OK;
    }

    - (KResult)seek:(float)sec
    {
        _suppress_error = false;
        
        WLog(@"Seeking to %f", sec);
        
        KGraphState prevState;
        @synchronized (_state_mutex) {
            switch (_state) {
                case KGraphState_NONE:
                case KGraphState_BUILDING:
                case KGraphState_STOPPING:
                case KGraphState_PAUSING:
                case KGraphState_SEEKING:
                case KGraphState_STOPPED:
                    DErr(@"Invalid State");
                    return KResult_InvalidState;
                case KGraphState_PAUSED:
                case KGraphState_STARTED:
                case KGraphState_EOF:
                    prevState = _state;
                    [self setStateAndNotify:KGraphState_SEEKING];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self seekSync:sec prevState:prevState];
                    });
                    
                    return KResult_OK;
            }
        }
    }
   

    - (KResult)play:(NSString * _Nonnull)url autoStart:(BOOL)autoStart
    {
        _suppress_error = false;
        
        @synchronized (_state_mutex) {
            switch (_state) {
                    
                    
                case KGraphState_EOF: {
                    KGraphState prevState = _state;
                    [self setStateAndNotify:KGraphState_SEEKING];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self seekSync:0 prevState:prevState];
                    });
                    
                    return KResult_OK;
                }
                case KGraphState_PAUSED:
                    return [self startPlaying];
                    
                case KGraphState_STOPPED:{
                    [self setStateAndNotify:KGraphState_PAUSING];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self startPlayingWithPauseSync];
                    });
                    return KResult_OK;
                    
                }
                    
                    
                case KGraphState_NONE:{
                    [self setStateAndNotify:KGraphState_BUILDING];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self buildGraphSync:url autoStart:autoStart];
                    });
                    
                    return KResult_OK;
                }
                 
                case KGraphState_BUILDING:
                case KGraphState_STOPPING:
                case KGraphState_PAUSING:
                case KGraphState_STARTED:
                case KGraphState_SEEKING:
                
                    return KResult_InvalidState;
            }
        }
    }

    - (KResult)stop
    {
        _suppress_error = true;
        KGraphState prevState;
        @synchronized (_state_mutex) {
            switch (_state) {
                case KGraphState_NONE:
                case KGraphState_STOPPED:
                case KGraphState_STOPPING:
                    return KResult_OK;
                
                case KGraphState_BUILDING:
                case KGraphState_PAUSING:
                case KGraphState_PAUSED:
                case KGraphState_STARTED:
                case KGraphState_SEEKING:
                case KGraphState_EOF:
                    [self setStateAndNotify:KGraphState_STOPPING];
                    prevState = _state;
                    break;
            }
        }
        
        
        
       
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        {
        
            // STOPPING
            KResult res;
            
            for (KFilter* filter in self->_flowchain  ) {
                DLog(@"KTestGraphChainBuilder interrupting %@", [filter name]);
                if ((res = [filter stop]) != KResult_OK){
                    DLog(@"<%@> stop failed", [filter name]);
                    
                    [self notifyError: KResult2Error(res)];
                }
            }
            
            
            @synchronized (self->_async_mutex) {
                for (KFilter* filter in self->_flowchain  ) {
                    DLog(@"KTestGraphChainBuilder stopping %@", [filter name]);
                    if ((res = [filter stop]) != KResult_OK){
                        DLog(@"<%@> stop failed", [filter name]);
                        
                        [self notifyError: KResult2Error(res)];
                    }
                }
                [self setStateAndNotify: prevState == KGraphState_BUILDING ? KGraphState_NONE :KGraphState_STOPPED];
                DErr(@"Here stopped");
#ifdef MYDEBUG
                for (KFilter* filter in self->_flowchain) {
                    DLog(@"STOP <%@> state is %@", [filter name], KFilterState2String([filter state]));
                }
#endif
            }
            
            [self setStateAndNotify:KGraphState_STOPPED];
        
        }});
        
        return KResult_OK;
    }


    - (void)onEOS:(KFilter *)filter
    {
        _suppress_error = false;
        @synchronized (_state_mutex) {
            switch (_state) {
                case KGraphState_NONE:
                case KGraphState_BUILDING:
                case KGraphState_STOPPING:
                case KGraphState_PAUSING:
                case KGraphState_SEEKING:
                case KGraphState_EOF:
                case KGraphState_STOPPED:
                case KGraphState_PAUSED:
                    return;
                case KGraphState_STARTED:
                    [self setStateAndNotify:KGraphState_PAUSING];
                    break;
                    
            }
        }
                   
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            {
                @synchronized (self->_async_mutex) {
                    KResult res;
                    for (KFilter* filter in  [self->_flowchain reverseObjectEnumerator]) {
                        DLog(@"<%@> pausing", [filter name]);
                        res = [filter pause];
                        if (res!=KResult_OK) {
                            DLog(@"<%@> pause failed", [filter name]);
                            
                            [self notifyError: KResult2Error(res)];
                            [self stop];
                            
                            return ;
                        }
                        DLog(@"<%@> EOS flushing", [filter name]);
                        res = [filter flushEOS];
                        if (res!=KResult_OK) {
                            DLog(@"<%@> flush failed", [filter name]);
                            
                            [self notifyError: KResult2Error(res)];
                            [self stop];
                            
                            return ;
                        }
                    }
                    DErr(@"Here paused");
#ifdef MYDEBUG
                    for (KFilter* filter in self->_flowchain) {
                        DLog(@"<%@> state is %@", [filter name], KFilterState2String([filter state]));
                    }
#endif
                    [self setStateAndNotify:KGraphState_EOF];
                }
            }
        });
    }


    





- (CMTime)endBufferedPosition
{
    CMTime maxTm = CMTimeMake(0, 1);
    
    for (KFilter *f in _flowchain)
    {
        if ([f conformsToProtocol:@protocol(KPlayBufferPositionInfo) ]) {
            id<KPlayBufferPositionInfo> bufferPositionInfo = (id<KPlayBufferPositionInfo> )f;
            CMTime tm = bufferPositionInfo.endBufferedPosition;
            if (CMTimeCompare(tm, maxTm) > 0 )
                maxTm = tm;
        }
    }
    return maxTm;
}

- (CMTime)startBufferedPosition {
    BOOL hasMin=FALSE;
    CMTime minTm = CMTimeMake(0, 1);
    
    for (KFilter *f in _flowchain)
    {
        if ([f conformsToProtocol:@protocol(KPlayBufferPositionInfo) ]) {
            id<KPlayBufferPositionInfo> bufferPositionInfo = (id<KPlayBufferPositionInfo> )f;
            CMTime tm = bufferPositionInfo.startBufferedPosition;
            if (!hasMin || CMTimeCompare(tm, minTm) < 0 ){
                hasMin=TRUE;
                minTm = tm;
            }
        }
    }
    return hasMin ? minTm : CMTimeMake(0, 1);
}

@end

