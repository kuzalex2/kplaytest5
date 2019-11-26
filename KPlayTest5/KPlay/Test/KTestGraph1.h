//
//  KTestGraph1.h
//  KPlayTest3
//
//  Created by kuzalex on 11/17/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#ifndef KTestGraph1_h
#define KTestGraph1_h

#import "KFilter.h"
#import "KFilter.h"

@protocol KPlayer<NSObject>
@optional
    - (KResult)play:(NSString * _Nonnull)url autoStart:(BOOL)autoStart;
    - (KResult)pause;
    - (KResult)stop;
    //- (void)seek:
@end

typedef enum
{
    KGraphState_NONE,
    KGraphState_BUILDING,
    KGraphState_STOPPED,
    KGraphState_STOPPING,
    KGraphState_PAUSING,
    KGraphState_PAUSED,
    KGraphState_STARTED
} KGraphState;

@protocol KPlayerEvents<NSObject>
@optional
    - (void)onError:( NSError * _Nonnull )error;
    - (void)onStateChanged:(KGraphState)state;
@end



@interface KTestGraphChainBuilder : NSObject<KPlayEvents, KPlayer>
    @property (weak, nonatomic) id<KPlayerEvents> _Nullable events;
    @property KGraphState state;
    @property NSObject * _Nullable state_mutex;
    @property NSMutableArray<KFilter*> * _Nullable chain;
@end




#endif /* KTestGraph1_h */
