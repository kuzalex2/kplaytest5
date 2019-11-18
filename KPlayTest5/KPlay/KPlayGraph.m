////
////  KPlayGraph.m
////  KPlayer
////
////  Created by test name on 26.04.2019.
////  Copyright © 2019 Instreamatic. All rights reserved.
////
//
//#define MYDEBUG
//#include "myDebug.h"
//#import "KPlayGraph.h"
//
//
//@implementation KPlayGraph{
//
//
//    @protected NSObject *_build_state_mutex;
//    @protected KGraphBuildState _build_state;
//    int _build_done;
//    dispatch_semaphore_t _build_done_sem;
//
//}
//- (instancetype)init
//{
//    self = [super init];
//    if (self){
//        self->_connected = FALSE;
//        self->_build_state_mutex = [NSObject new];
//        self->_build_state = KGraphBuildState_NO;
//    }
//    return self;
//}
//
//-(NSString *)name
//{
//    return NSStringFromClass([self class]);
//}
//
//- (KGraphBuildState) build_state
//{
//    @synchronized(_build_state_mutex) {
//        return _build_state;
//    }
//}
//-(KResult)startBuild:(void (^)(void))success error:(void (^)(void))error;
//{
//    @synchronized(_build_state_mutex) {
//        switch (_build_state) {
//            case KGraphBuildState_STARTED:
//                return KResult_OK;
//
//            default:
//                _build_state = KGraphBuildState_STARTED;
//                _build_done = 0;
//                _build_done_sem = dispatch_semaphore_create(0);
//
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                    [self buildThreadProc:success error:error];
//                });
//                return KResult_OK;
//        }
//    }
//}
//
//-(KResult)stopBuild
//{
//    @synchronized(_build_state_mutex) {
//        if (_build_state!=KGraphBuildState_STARTED)
//            return KResult_OK;
//
//        if (_build_done==0)
//            _build_done=1;
//    }
//    [self stop];
//    while(1) {
//        @synchronized(_build_state_mutex) {
//            if (_build_state==KGraphBuildState_FINISHED)
//                return KResult_OK;
//            if (_build_done==2){
//                _build_state = KGraphBuildState_FINISHED;
//                //_build_done_sem=nil;
//                DLog(@"%@ Stopped building",[self name]);
//                return KResult_OK;
//            }
//        }
//        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC);
//        dispatch_semaphore_wait(_build_done_sem, timeout);
//     }
//}
//
//-(KResult) doGraphBuild
//{ return KResult_ERROR; }
//
//-(void)buildThreadProc:(void (^)(void))success error:(void (^)(void))error;
//{
//    KResult res = KResult_ERROR;
//
//
//    do {
//        @synchronized(_build_state_mutex) {
//            if (_build_done != 0){
//                break;
//            }
//        }
//
//        DLog(@"%@ BuildThreadProc tick", [self name]);
//
//        res = [self doGraphBuild];
//    } while(0);
//
//    BOOL interrupted = FALSE;
//    @synchronized(_build_state_mutex) {
//        if (_build_done != 0){
//            interrupted=YES;
//        }
//    }
//
//    if (res==KResult_OK && !interrupted)
//        success();
//
//    ///FIXME: error callback!
//
//    DLog(@"%@ buildThreadProc finishing", [self name]);
//    @synchronized(_build_state_mutex) {
//        _build_done=2;
//        _build_state = KGraphBuildState_FINISHED;
//        dispatch_semaphore_signal(_build_done_sem);
//    }
//    DLog(@"%@ BuildThreadProc done", [self name]);
//}
//
//- (void)disconnect
//{
//    if ([self build_state] == KGraphBuildState_STARTED){
//        [self stopBuild];
//    }
//    [self stop];
//    _connected=FALSE;
//}
//
//
//- (void)start
//{}
//- (void)pause
//{}
//- (void)stop
//{}
//
//
//
//
//
//// settern / getters
//- (id<KBufferInfo>) bufferInfo
//{
//    return nil;
//}
//- (KFilterState) state
//{
//    return KFilterState_STOPPED;
//}
//-(float) rate
//{
//    return 1.0;
//}
//-(void) setRate:(float)newRate
//{
//}
//- (BOOL)  isLive
//{
//    return FALSE;
//}
//-(KClock*) clock
//{
//    return nil;
//}
//
//
//+(BOOL)Connect:(KFilter *)src :(size_t)src_pin_index :(KFilter *)dst :(size_t)dst_pin_index
//{
//    KPin *pout = [src getOutputPinAt:src_pin_index];
//    KPin *pin  = [dst getInputPinAt:dst_pin_index];
//
//    if (pout==nil){
//        DErr(@"No outpin %ld at %@",src_pin_index,src);
//        return FALSE;
//    }
//
//    if (pin==nil){
//        DErr(@"No inpin %ld at %@",dst_pin_index,dst);
//        return FALSE;
//    }
//
//    if (! [pout connectTo:pin] ) {
//        DErr(@"failed to connect (%@)%ld->(%@)%ld", [src name], src_pin_index, [dst name], dst_pin_index);
//        return FALSE;
//    }
//
//    return TRUE;
//}
//@end
//
