////
////  KClock.m
////  kptest
////
////  Created by kuzalex on 4/17/19.
////  Copyright © 2019 kuzalex. All rights reserved.
////
//
//#import "KFilter.h"
//#import "KClock.h"
//#include <mach/mach.h>
//#include <mach/mach_time.h>
//#include <unistd.h>
//
//
//
//
//@implementation KClock{
//    @protected double _rate;
//}
//
//-(instancetype)init{
//    self = [super init];
//    if (self){
//        _rate=1.0;
//    }
//    return self;
//}
//    -(int64_t)getTimeMs
//    {
//        return 0;
//    }
//   
//    -(KFilterState)state{return KFilterState_STOPPED;}
//@end
//
//
//@implementation KSimpleClock {
//    KFilterState _state;
//    //   KFilterState _prev_state;
//    uint64_t      tmstart;
//   // uint64_t      tmpauseElapsedTimeBase;
//    uint64_t      tmstartElapsedTimeBase;
//    // double        rate;
//}
//-(instancetype)init{
//    self = [super init];
//    if (self){
//        _state = /*_prev_state =*/ KFilterState_STOPPED;
//        tmstartElapsedTimeBase=0;
//    }
//    return self;
//}
//-(int64_t) getTimeNano
//{
//    //assert @synchronized (self)
//    // assert KFilterState_STARTED
//    static mach_timebase_info_data_t    sTimebaseInfo;
//    
//    uint64_t end = mach_absolute_time();
//    uint64_t elapsed = end - tmstart;
//    
//    if ( sTimebaseInfo.denom == 0 ) {
//        (void) mach_timebase_info(&sTimebaseInfo);
//    }
//    uint64_t elapsedNano = elapsed * sTimebaseInfo.numer / sTimebaseInfo.denom;
//    
//    return elapsedNano*self.rate + ( tmstartElapsedTimeBase * sTimebaseInfo.numer / sTimebaseInfo.denom );
//    
//}
//-(int64_t)getTimeMs
//{
//    @synchronized (self)
//    {
//        switch (_state) {
//            case KFilterState_STOPPED:
//                return 0;
//            case KFilterState_PAUSED:
//            {
//                static mach_timebase_info_data_t    sTimebaseInfo;
//                if ( sTimebaseInfo.denom == 0 ) {
//                    (void) mach_timebase_info(&sTimebaseInfo);
//                }
//                return tmstartElapsedTimeBase * sTimebaseInfo.numer / sTimebaseInfo.denom / 1000000;
//            }
//            case KFilterState_STARTED:
//            {
//                return [self getTimeNano]/1000000;
//            }
//                
//        }
//    }
//}
//-(void)start{
//    KFilterState state0;
//    @synchronized (self)
//    {
//        if (_state == KFilterState_STARTED)
//            return ;
//        
//        if (_state == KFilterState_PAUSED){
//            tmstart = mach_absolute_time();// - tmpauseElapsedTimeBase;
//        } else {
//            tmstart = mach_absolute_time();
//        }
//       
//        state0=_state = KFilterState_STARTED;
//    }
//    if (super.onStateChanged)
//        [super.onStateChanged onStateChanged:state0];
//}
//-(void)pause{
//    KFilterState state0;
//    @synchronized (self)
//    {
//        if (_state == KFilterState_STOPPED)
//            return;
//        if (_state == KFilterState_PAUSED)
//            return;
//        
//        uint64_t end = mach_absolute_time();
//        uint64_t elapsed = end - tmstart;
//        tmstartElapsedTimeBase = tmstartElapsedTimeBase + elapsed*_rate ;
//        
//        
//        state0=_state = KFilterState_PAUSED;
//        
//    }
//    if (super.onStateChanged)
//        [super.onStateChanged onStateChanged:state0];
//}
//-(void)stop{
//    KFilterState state0;
//    @synchronized (self)
//    {
//        // _prev_state = _state;
//        state0=_state = KFilterState_STOPPED;
//        tmstartElapsedTimeBase=0;
//       
//    }
//    if (super.onStateChanged)
//        [super.onStateChanged onStateChanged:state0];
//}
//-(KFilterState)state
//{
//    @synchronized (self)
//    {
//        return _state;
//    }
//}
//-(void)setRate:(double)rate
//{
//    @synchronized (self)
//    {
//       
//        if (_state == KFilterState_STARTED){
//            
//            
//            
//            
//            uint64_t end = mach_absolute_time();
//            uint64_t elapsed = end - tmstart;
//            tmstartElapsedTimeBase = tmstartElapsedTimeBase + elapsed*_rate ;
//            
//            
//            
//            
//            tmstart = mach_absolute_time();
//            
//        }
//         _rate = rate;
//    }
//}
//@end
