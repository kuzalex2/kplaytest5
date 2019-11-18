//
//  KTestGraph1.m
//  KPlayTest3
//
//  Created by kuzalex on 11/17/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTestGraph1.h"
#import "KTestFilters.h"

#define MYDEBUG
#include "myDebug.h"



@implementation KTestGraph1

    KFilter *_src;
    KFilter *_dec;
    KTestSinkFilter *_sink;
    
    KGraphState _state;
    NSObject *_state_mutex;

    
    

    - (void)onError:(KFilter *)filter result:(KResult)result error:( NSError * _Nullable )error
    {
        //FIXME: process filter errors here and push to next
        DLog(@"<%@> onError %d %@", [filter name], result, error);
    }
    - (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
    {
        //FIXME: process filter's change of state here and push to next
       // if ([filter.events respondsToSelector:@selector(onStateChanged:state:)])
         //   [filter.events onStateChanged:filter state:state];
        DLog(@"<%@> onStateChanged %@ ", [filter name], KFilterState2String(state) );
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
        }
        return self;
    }

    - (void)buildGraph:(NSString * _Nonnull)url autoStart:(BOOL)autoStart
    {
        [self setStateAndNotify:KGraphState_BUILDING];
               
        /// Build graph
        KResult res;
        
        _src = [[KTestUrlSourceFilter alloc] initWithUrl:url];
        _dec = [[KTestTransformFilter alloc] init];
        _sink = [[KTestSinkFilter alloc] init];
        
        
        ///FIXME: disconneting
               
        if ((res=[self prepareFilter:_src]) != KResult_OK) {
            DLog(@"<%@> Prepare failed", [_src name]);
            
            [self notifyError: KResult2Error(res)];
            [self setStateAndNotify:KGraphState_NONE];
            return;
        }
        
        if (![KTestGraph1 connectFilters:_src :0 :_dec :0] ) {
            DLog(@"Connec failed");
            [self notifyError: KResult2Error(res)];
            [self setStateAndNotify:KGraphState_NONE];
            return;
        }
        
        if ((res=[self prepareFilter:_dec]) != KResult_OK) {
            DLog(@"<%@> Prepare failed", [_dec name]);
            [self notifyError: KResult2Error(res)];
            [self setStateAndNotify:KGraphState_NONE];
            return;
        }
        
        if (![KTestGraph1 connectFilters:_dec :0 :_sink :0] ) {
            DLog(@"Connec failed");
            [self notifyError: KResult2Error(res)];
            [self setStateAndNotify:KGraphState_NONE];
            return;
        }
        
        if ((res=[self prepareFilter:_sink]) != KResult_OK) {
            DLog(@"<%@> Prepare failed", [_sink name]);
            [self notifyError: KResult2Error(res)];
            [self setStateAndNotify:KGraphState_NONE];
            return;
        }
        
        [self setStateAndNotify:KGraphState_PAUSED];
        
        if (autoStart) {
            [self startPlaying];
           
        }
    }

    - (KResult)stopBuilding
    {
        //??????
        //FIXME: ??????
        return KResult_OK;
    }

    - (KResult)startPlaying
    {
        KResult res;

        if ((res = [_src start]) != KResult_OK){
            [self notifyError: KResult2Error(res)];
            return res;
        }
        if ((res = [_dec start]) != KResult_OK){
            [self notifyError: KResult2Error(res)];
            return res;
        }
        if ((res = [_sink start]) != KResult_OK){
            [self notifyError: KResult2Error(res)];
            return res;
        }
        [self setStateAndNotify:KGraphState_STARTED];
        
        return KResult_OK;
    }

    - (KResult)stopPlaying
    {
        KResult res;
        if ((res = [_src stop:true]) != KResult_OK){
            [self notifyError: KResult2Error(res)];
            return res;
        }
        if ((res = [_dec stop:true]) != KResult_OK){
            [self notifyError: KResult2Error(res)];
            return res;
        }
        if ((res = [_sink stop:true]) != KResult_OK){
            [self notifyError: KResult2Error(res)];
            return res;
        }
        [self setStateAndNotify:KGraphState_STOPPED];
        
        return KResult_OK;
    }
    

    - (KResult)play:(NSString * _Nonnull)url autoStart:(BOOL)autoStart;
    {
        @synchronized (_state_mutex) {
            switch (_state) {
                case KGraphState_PAUSED:
                    return [self startPlaying];
                    
                case KGraphState_NONE:
                case KGraphState_STOPPED:
                    break;
                    
                default:
                    return KResult_InvalidState;
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self buildGraph:url autoStart:autoStart];
           });
        
        return KResult_OK;
    }
    - (KResult)pause
    {
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
        if ((res = [_src pause:true]) != KResult_OK){
            [self notifyError: KResult2Error(res)];
            return res;
        }
        if ((res = [_dec pause:true]) != KResult_OK){
            [self notifyError: KResult2Error(res)];
            return res;
        }
        if ((res = [_sink pause:true]) != KResult_OK){
            [self notifyError: KResult2Error(res)];
            return res;
        }
        [self setStateAndNotify:KGraphState_PAUSED];
        
        return KResult_OK;
    }

    - (KResult)stop
    {
        @synchronized (_state_mutex) {
            switch (_state) {
                case KGraphState_NONE:
                    return KResult_OK;
                case KGraphState_BUILDING:
                    // STOP BUILDING
                    return [self stopBuilding];
                default:
                    return [self stopPlaying];
                }
        }
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

        if ((res = [f pause:true]) != KResult_OK ) {
            return res;
        }
        
        //FIXME:
        if ([f.outputPins count] > 0 ) {
            if ((res = [f pullSample:&sample probe:YES error:&error]) != KResult_OK) {
                return res;
            }
        }
              
        f.events = self;
        
        return KResult_OK;
    }





@end

