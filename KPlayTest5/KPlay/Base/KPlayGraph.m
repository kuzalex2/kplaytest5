////
////  KPlayGraph.m
////  KPlayer
////
////  Created by test name on 26.04.2019.
//  Copyright © 2019 kuzalex. All rights reserved.
////

#import <Foundation/Foundation.h>

#import "KTestFilters.h"
#import "KQueueFilter.h"
#import "KPlayGraph.h"

#define MYDEBUG
#include "myDebug.h"


@implementation KPlayGraphChainBuilder

    

   
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
        DLog(@"<%@> onStateChanged %@ ", [filter name], KFilterState2String(state) );
        
        
        if (_chain.count > 0 && filter == [_chain lastObject]){
            if (state == KFilterState_PAUSED && [self state]!=KGraphState_SEEKING){
                [self setStateAndNotify:KGraphState_PAUSED];
                ///FIXME:!!!!!!!! all others
                ///FIXME: mutex
            }
        }
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
            _state = KGraphState_NONE;
            _chain = [[NSMutableArray alloc]init];
        }
        return self;
    }


    - (void)seekSync:(float)sec prevState:(KGraphState)prevState
    {
        [self setStateAndNotify:KGraphState_SEEKING];
            
        KResult res;
            
        for (size_t i = 0; i< _chain.count; i++)
        {
            res = [_chain[i] pause:true];
            if (res!=KResult_OK) {
                DLog(@"<%@> pause failed", [_chain[i] name]);
                           
                [self notifyError: KResult2Error(res)];
                [self setStateAndNotify:KGraphState_NONE];
                return;
            }
        }
            
        for (size_t i = 0; i< _chain.count; i++)
        {
            KResult res = [_chain[i] seek:sec];
            if (res!=KResult_OK) {
                DLog(@"<%@> seek failed", [_chain[i] name]);
                           
                [self notifyError: KResult2Error(res)];
                [self setStateAndNotify:KGraphState_NONE];
                return;
            }
        }
        
        for (size_t i = 0; i< _chain.count; i++)
        {
            res = [_chain[i] pause:true];
            if (res!=KResult_OK) {
                DLog(@"<%@> pause failed", [_chain[i] name]);
                           
                [self notifyError: KResult2Error(res)];
                [self setStateAndNotify:KGraphState_NONE];
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
                [self setStateAndNotify:KGraphState_PAUSED];
                [self startPlaying];
                break;
            default:
                assert(false);
        }
    }
     

    - (void)buildGraphSync:(NSString * _Nonnull)url autoStart:(BOOL)autoStart
    {
        [self setStateAndNotify:KGraphState_BUILDING];
        
        KResult res;
        
        for (size_t i = 0; i< _chain.count; i++)
        {
            DLog(@"KTestGraphChainBuilder Prepare %@", [_chain[i] name]);
            if ( (res=[self prepareFilter:_chain[i]]) != KResult_OK ) {
                DLog(@"<%@> Prepare faileKPlayMediaInfod", [_chain[i] name]);
                
                [self notifyError: KResult2Error(res)];
                [self setStateAndNotify:KGraphState_NONE];
                return;
            }
            
            if ( i+1 < _chain.count ) {
                DLog(@"KPlayGraphChainBuilder Connecting %@ -> %@", [_chain[i] name], [_chain[i+1] name]);
                if (![KPlayGraphChainBuilder connectFilters:_chain[i] :0 :_chain[i+1] :0] ) {
                    DLog(@"Connect failed");
                    [self notifyError: KResult2Error(res)];
                    [self setStateAndNotify:KGraphState_NONE];
                    return;
                }
            }
        }
        
        
        for (size_t i = 0; i< _chain.count; i++) {
            if (self.mediaInfo == nil) {
                if ([_chain[i] conformsToProtocol:@protocol(KPlayMediaInfo) ]) {
                    self.mediaInfo = (id<KPlayMediaInfo> ) _chain[i];
                }
            }
            if (self.positionInfo == nil) {
                if ([_chain[i] conformsToProtocol:@protocol(KPlayPositionInfo) ]) {
                    self.positionInfo = (id<KPlayPositionInfo> ) _chain[i];
                }
            }
            if (self.bufferPositionInfo == nil) {
                if ([_chain[i] conformsToProtocol:@protocol(KPlayBufferPositionInfo) ]) {
                    self.bufferPositionInfo = (id<KPlayBufferPositionInfo> ) _chain[i];
                }
            }
        }
        
        
        [self setStateAndNotify:KGraphState_PAUSED];
        
        if (autoStart) {
            [self startPlaying];
           
        }
    }

    - (KResult)stopBuilding
    {
        for (size_t i = 0; i< _chain.count; i++)
        {
            DLog(@"KTestGraphChainBuilder Stop %@", [_chain[i] name]);
             [_chain[i] stop:true];
        }

        [self setStateAndNotify:KGraphState_NONE];
        return KResult_OK;
    }

    - (KResult)startPlaying
    {
        KResult res;
        
        for (size_t i = 0; i< _chain.count; i++)
        {
            DLog(@"KTestGraphChainBuilder startPlaying %@", [_chain[i] name]);
            if ((res = [_chain[i] start]) != KResult_OK){
                [self notifyError: KResult2Error(res)];
                return res;
            }
        }

        [self setStateAndNotify:KGraphState_STARTED];
        
        return KResult_OK;
    }

    - (KResult)startPlayingWithPause
    {
        KResult res;
        
        [self setStateAndNotify:KGraphState_PAUSING];
        
        for (size_t i = 0; i< _chain.count; i++)
        {
            DLog(@"KTestGraphChainBuilder pausing %@", [_chain[i] name]);
            if ((res = [_chain[i] pause:true]) != KResult_OK){
                [self notifyError: KResult2Error(res)];
                return res;
            }
        }
        
        [self setStateAndNotify:KGraphState_PAUSED];
        
        return [self startPlaying];
    }

    

    - (KResult)stopPlaying
    {
        KResult res;
        
        for (size_t i = 0; i< _chain.count; i++)
        {
            DLog(@"KTestGraphChainBuilder stopPlaying %@", [_chain[i] name]);
            if ((res = [_chain[i] stop:true]) != KResult_OK){
                [self notifyError: KResult2Error(res)];
                //return res;
            }
        }
        
        [self setStateAndNotify:KGraphState_STOPPED];
        
        return KResult_OK;
    }
    

    - (KResult)play:(NSString * _Nonnull)url autoStart:(BOOL)autoStart;
    {
        _suppress_error = false;
        
        
            switch ([self state]) {
                case KGraphState_PAUSED:
                    return [self startPlaying];
                case KGraphState_STOPPED:{
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self startPlayingWithPause];
                    });
                    return KResult_OK;
                    
                }
                    
                    
                case KGraphState_NONE:
                
                    break;
                    
                default:
                    return KResult_InvalidState;
            }
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self buildGraphSync:url autoStart:autoStart];
           });
        
        return KResult_OK;
    }
    - (KResult)pause
    {
        _suppress_error = false;
        @synchronized (_state_mutex) {
            switch (_state) {
                case KGraphState_NONE:
                case KGraphState_BUILDING:
                    return KResult_InvalidState;
                default:
                    break;
            }
        }
        
        KResult res;
        
        for (size_t i = 0; i< _chain.count; i++)
        {
            DLog(@"KTestGraphChainBuilder pausing %@", [_chain[i] name]);
            if ((res = [_chain[i] pause:false]) != KResult_OK){
                [self notifyError: KResult2Error(res)];
                return res;
            }
        }

        [self setStateAndNotify:KGraphState_PAUSING];
        
        return KResult_OK;
    }

    - (KResult)stop
    {
        _suppress_error = true;
        
            switch ([self state]) {
                case KGraphState_NONE:
                    return KResult_OK;
                case KGraphState_BUILDING:
                    // STOP BUILDING
                    return [self stopBuilding];
                default:
                    return [self stopPlaying];
                }
        
    }

    
    - (KResult)seek:(float)sec
    {
        _suppress_error = false;
        KGraphState prevState;
        @synchronized (_state_mutex) {
            switch (_state) {
                case KGraphState_STOPPED:
                case KGraphState_PAUSING:
                case KGraphState_PAUSED:
                case KGraphState_STARTED:
                    prevState = _state;
                    break;
                default:
                    return KResult_InvalidState;
                }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self seekSync:sec prevState:prevState];
           });
        
        return KResult_OK;
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
        
        if ((res = [f pause:true]) != KResult_OK ) {
            return res;
        }
        
        //FIXME:
        if ([f.outputPins count] > 0 ) {
            if ((res = [f pullSample:&sample probe:YES error:&error]) != KResult_OK) {
                return res;
            }
        }
              
        
        
        return KResult_OK;
    }





@end

