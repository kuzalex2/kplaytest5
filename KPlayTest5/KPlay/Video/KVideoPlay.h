//
//  KVideoPlay.h
//  KPlayTest5
//
//  Created by kuzalex on 12/4/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KFilter.h"
#import "KPlayGraph.h"
#import <UIKit/UIScreen.h>

NS_ASSUME_NONNULL_BEGIN

@interface KVideoPlay : KThreadFilter<KPlayPositionInfo>
    

    - (instancetype)initWithUIView:(UIView *)view;

    -(KResult)onThreadTick:(NSError *__strong*)ppError;
    -(KResult)seek:(float)sec;
    -(KResult)flush;
@end

NS_ASSUME_NONNULL_END
