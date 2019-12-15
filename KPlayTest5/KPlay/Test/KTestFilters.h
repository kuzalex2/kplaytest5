//
//  KTestFilters.h
//  KPlayer
//
//  Created by test name on 16.04.2019.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KFilter.h"
#import "KPlayGraph.h"


NS_ASSUME_NONNULL_BEGIN
//
//@interface KTestSourceFilter : KFilter
//    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin;
//@end
//
//@interface KTestUrlSourceFilter : KFilter
//    -(instancetype)initWithUrl:(NSString *)url;
//    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin;
//@end
//
@interface KNullSink : KThreadFilter<KPlayPositionInfo> {
    @public int _consumed_samples;
}
    -(KResult)onThreadTick:(NSError *__strong*)ppError;
@end
//
//@interface KTestTransformFilter : KTransformFilter
//    -(KResult)onTransformSample:(KMediaSample *_Nonnull*_Nullable)sample error:(NSError *__strong*)error;
//    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;
//    -(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin;
//@end


NS_ASSUME_NONNULL_END
