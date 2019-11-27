//
//  KTestFilters.h
//  KPlayer
//
//  Created by test name on 16.04.2019.
//  Copyright © 2019 Instreamatic. All rights reserved.
//

#import "KFilter.h"
#import "KFilter.h"


NS_ASSUME_NONNULL_BEGIN

@interface KTestSourceFilter : KFilter
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error;
@end

@interface KTestUrlSourceFilter : KFilter
    -(instancetype)initWithUrl:(NSString *)url;
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error;
@end

@interface KTestSinkFilter : KThreadFilter {
    @public int _consumed_samples;
}
    -(KResult)onThreadTick:(NSError *__strong*)ppError;
@end

@interface KTestTransformFilter : KTransformFilter
    -(KResult)onTransformSample:(KMediaSample *__strong _Nonnull*_Nullable)sample;
    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;
    -(KMediaType *)getOutputMediaType;
@end


NS_ASSUME_NONNULL_END
