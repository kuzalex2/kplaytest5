////
////  KPlayGraph.h
////  KPlayer
////
////  Created by test name on 26.04.2019.
////
//

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
    - (void)onError:( NSError * _Nullable )error;
    - (void)onStateChanged:(KGraphState)state;
@end



@interface KPlayGraphChainBuilder : NSObject<KPlayEvents, KPlayer>
    @property (weak, nonatomic) id<KPlayerEvents> _Nullable events;
    @property KGraphState state;
    @property NSObject * _Nonnull state_mutex;
    @property NSMutableArray<KFilter*> * _Nullable chain;
@end



//@protocol KBufferInfo
//    -(float) minTsSec;
//    -(float) maxTsSec;
//@end
//
