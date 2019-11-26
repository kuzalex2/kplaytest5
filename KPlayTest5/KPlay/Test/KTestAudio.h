//
//  KTestAudio.h
//  KPlayTest5
//
//  Created by kuzalex on 11/26/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface KAudioSourceToneFilter : KFilter
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError **)error;
@end

@interface KAudioPlayFilter : KThreadFilter {
    //@public int _consumed_samples;
}
    -(KResult)onThreadTick;
@end

NS_ASSUME_NONNULL_END
