//
//  KFilter.h
//  KPlayer
//
//  Created by test name on 15.04.2019.
//  Copyright © 2019 Instreamatic. All rights reserved.
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

@interface KFilter : NSObject<KPlayEvents>
{
    @protected KFilterState _state;
    @protected NSObject *_state_mutex;
}
    @property (weak, nonatomic) id<KPlayEvents> events;
    @property (readonly, nonatomic, retain) NSMutableArray<KInputPin *> *inputPins;
    @property (readonly, nonatomic, retain) NSMutableArray<KOutputPin *> *outputPins;

    
    - (KFilterState) state;

    -(KResult)waitSemaphoreOrState:(dispatch_semaphore_t)sem;

    -(KResult)start;
    -(KResult)pause:(BOOL)waitUntilPaused;
    -(KResult)stop:(BOOL)waitUntilStopped;

    - (KOutputPin *) getOutputPinAt:(size_t)i;
    - (KInputPin *) getInputPinAt:(size_t)i;

    - (void)onStateChanged:(KFilter *)filter state:(KFilterState)state;
   

    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *_Nonnull*_Nullable)error;


   // -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError **)error;
    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;
    -(KMediaType *)getOutputMediaType;
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

    -(KResult)onThreadTick;
@end

@interface KTransformFilter : KFilter
    //-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError **)error;


    -(KResult)onTransformSample:(KMediaSample *_Nonnull*_Nullable)sample error:(NSError **)error;
    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;
    -(KMediaType *)getOutputMediaType;
@end

NS_ASSUME_NONNULL_END