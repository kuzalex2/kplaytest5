//
//  KQueueFilter.h
//  kptest
//
//  Created by kuzalex on 4/18/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KFilter.h"
#import "KClock.h"

NS_ASSUME_NONNULL_BEGIN

//@protocol KBufferInfo
//    -(float) minTsSec;
//    -(float) maxTsSec;
//@end

@interface KQueueFilter : KThreadFilter // <KBufferInfo>
    -(KResult)onThreadTick:(NSError *__strong*)ppError;
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin;

    -(KResult)seek:(float)sec;

    @property size_t max_samples_queue;
    @property BOOL sorted;
@end

NS_ASSUME_NONNULL_END
