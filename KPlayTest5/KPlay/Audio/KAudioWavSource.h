//
//  KAudioSourceWavReaderFilter.h
//  KPlayTest5
//
//  Created by kuzalex on 12/1/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFilter.h"
#import "KPlayGraph.h"

NS_ASSUME_NONNULL_BEGIN



@interface KAudioWavSource : KFilter<KPlayMediaInfo>
    -(instancetype)initWithUrl:(NSString *)url;
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin;
    -(BOOL)canSeekTo:(float)sec;
    -(KResult)seekTo:(float)sec;
    -(KResult)flush;
   
@end

NS_ASSUME_NONNULL_END
