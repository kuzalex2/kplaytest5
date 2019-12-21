//
//  KAudioPlayFilter.h
//  KPlayTest5
//
//  Created by kuzalex on 11/27/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KFilter.h"
#import "KPlayGraph.h"

NS_ASSUME_NONNULL_BEGIN

@interface KAudioPlay : KThreadFilter<KPlayPositionInfo, KPlayBufferPositionInfo> {
    
}
    -(KResult)onThreadTick:(NSError *__strong*)ppError;
    -(KResult)flush;
@end

NS_ASSUME_NONNULL_END
