//
//  KFilter.h
//  KPlayer
//
//  Created by test name on 15.04.2019.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPin.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum
{
   // KFilterState_NONE,
    KFilterState_STOPPED,
    KFilterState_STOPPING,
    KFilterState_PAUSING,
    KFilterState_PAUSED,
    KFilterState_STARTED
} KFilterState;

NSString *KFilterState2String(KFilterState state);

@protocol KPlayEvents<NSObject>
@optional
- (void)onError:(KFilter *)filter result:(KResult)result error:( NSError * _Nullable )error;
- (void)onStateChanged:(KFilter *)filter state:(KFilterState)state;
@end

@protocol KPullFilter <NSObject>

    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong _Nonnull*_Nullable)error fromPin:(KOutputPin*)pin;
    -(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin;


@end

@protocol KPlayPositionInfo<NSObject>
    -(int64_t)position;
    -(int64_t)timeScale;
    -(BOOL)isRunning;
@end

@interface KFilter : NSObject<KPlayEvents, KPullFilter>
{
    @protected KFilterState _state;
    @protected NSObject *_state_mutex;
   // @protected NSObject *_pull_lock;
}
    @property (weak, nonatomic) id<KPlayEvents> events;
    @property (readonly, nonatomic, retain) NSMutableArray<KInputPin *> *inputPins;
    @property (readonly, nonatomic, retain) NSMutableArray<KOutputPin *> *outputPins;
    @property (weak) id<KPlayPositionInfo> clock;

    
    - (KFilterState) state;

    -(KResult)waitSemaphoreOrState:(dispatch_semaphore_t)sem;

    -(KResult)start;
    -(KResult)pause;//:(BOOL)waitUntilPaused;
    -(KResult)stop;//:(BOOL)waitUntilStopped;
    -(KResult)seek:(float)sec;

    - (KOutputPin *) getOutputPinAt:(size_t)i;
    - (KInputPin *) getInputPinAt:(size_t)i;

    - (void)onStateChanged:(KFilter *)filter state:(KFilterState)state;
   

    -(KResult)pullSampleInternal:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong _Nonnull*_Nullable)error fromPin:(KOutputPin*)pin;
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong _Nonnull*_Nullable)error fromPin:(KOutputPin*)pin;
    -(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin;


   // -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError **)error;
    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;
    
    -(NSString *)name;
@end






@interface KThreadFilter : KFilter
//{
//    @protected BOOL processInPause;
//}
    //@property void (^error_callback2)(KResult result, NSError *error);
   // -(KResult)start;
   // -(KResult)pause;
   // -(KResult)stop;

    -(KResult)onThreadTick:(NSError *__strong*)ppError;
@end

@interface KTransformFilter : KFilter
    //-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError **)error;


    -(KResult)onTransformSample:(KMediaSample *_Nonnull*_Nullable)sample error:(NSError *__strong*)error;
    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;
-(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin;
@end

NS_ASSUME_NONNULL_END
