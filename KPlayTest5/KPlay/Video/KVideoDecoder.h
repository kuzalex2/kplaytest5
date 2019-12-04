//
//  KVideoDecoder.h
//  KPlayTest5
//
//  Created by kuzalex on 12/4/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KTestFilters.h"

NS_ASSUME_NONNULL_BEGIN

@interface KVideoDecoder : KTransformFilter
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin;
    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;
    -(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin;

@end

NS_ASSUME_NONNULL_END
