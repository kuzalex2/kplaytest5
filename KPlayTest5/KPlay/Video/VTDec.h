//
//  VTDec.h
//  KPlayTest5
//
//  Created by kuzalex on 12/4/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTestFilters.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^OnMediaSampleCallback)(KMediaSample *sample);

@interface VTDec : NSObject
    -(KResult)decodeSample:(KMediaSample *)s andCallback:(OnMediaSampleCallback)onSuccess;
    -(void) flush;
    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;

@end

NS_ASSUME_NONNULL_END
