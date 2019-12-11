//
//  KBufferQueue.h
//  KPlayTest5
//
//  Created by kuzalex on 12/9/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KFilter.h"
#import "KClock.h"
#import "KPlayGraph.h"

NS_ASSUME_NONNULL_BEGIN


@interface KBufferQueue : KThreadFilter<KPlayBufferPositionInfo> // <KBufferInfo>
    @property BOOL  orderByTimestamp;
    @property float firstStartBufferSec;
    @property float secondStartBufferSec;

    - (instancetype)initWithFirstStartBufferSec:(float)firstStartBufferSec andSecondStartBufferSec:(float)secondStartBufferSec;

    -(KResult)onThreadTick:(NSError *__strong*)ppError;
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin;

    -(KResult)seek:(float)sec;

@end

NS_ASSUME_NONNULL_END
