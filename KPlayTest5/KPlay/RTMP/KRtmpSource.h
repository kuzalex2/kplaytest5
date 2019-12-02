//
//  KRtmpSource.h
//  KPlayTest5
//
//  Created by kuzalex on 12/2/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFilter.h"
#import "KPlayGraph.h"

NS_ASSUME_NONNULL_BEGIN

@interface KRtmpSource : KFilter<KPlayMediaInfo>
    -(instancetype)initWithUrl:(NSString *)url;
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error;
    -(KResult)seek:(float)sec;
   
@end

NS_ASSUME_NONNULL_END
