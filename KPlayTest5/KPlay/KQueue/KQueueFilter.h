//
//  KQueueFilter.h
//  kptest
//
//  Created by kuzalex on 4/18/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KFilter.h"
#import "KClock.h"


//@protocol KBufferInfo
//    -(float) minTsSec;
//    -(float) maxTsSec;
//@end

@interface KQueueFilter : KThreadFilter //<KBufferInfo>
//    - (instancetype)init;
    -(KResult)onThreadTick;
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *_Nonnull*_Nullable)error;

//    -(void)onStateChanged:(KFilterState)state;
//    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;
//    -(KMediaType *)getOutputMediaType;
//
//    -(KClock *)clock;
    @property size_t min_samples_queue;
    @property size_t max_samples_queue;
    @property BOOL sorted;
@end

