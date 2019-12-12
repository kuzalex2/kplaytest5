//
//  KDecoder.h
//  KPlayTest5
//
//  Created by kuzalex on 12/12/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#ifndef KDecoder_h
#define KDecoder_h

#import <Foundation/Foundation.h>
#import "KTestFilters.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDecoder : KTransformFilter
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin;
    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;
    -(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin;


    -(id)createDecoder;

@end

NS_ASSUME_NONNULL_END
#endif /* KDecoder_h */
