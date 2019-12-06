//
//  KAudioDecoder.h
//  KPlayTest5
//
//  Created by kuzalex on 12/5/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KTestFilters.h"

NS_ASSUME_NONNULL_BEGIN

@interface KAudioDecoder : KTransformFilter
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin;
    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;
    -(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin;

@end

NS_ASSUME_NONNULL_END
