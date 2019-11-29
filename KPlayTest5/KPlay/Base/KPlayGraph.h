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

@protocol KPlayMediaInfo<NSObject>
-(int64_t)duration;
-(int64_t)timeScale;
    //-(NSInteger)durationSec;
    //@property int32_t duration;
    //@property int32_t timeScale;
@end

@protocol KPlayPositionInfo<NSObject>
    //-(NSInteger)durationSec;
    @property int32_t position;
    @property int32_t timeScale;
@end


@interface KPlayGraphChainBuilder : NSObject<KPlayEvents, KPlayer>
    @property (weak, nonatomic) id<KPlayerEvents> _Nullable events;
    @property (weak, nonatomic) id<KPlayMediaInfo> _Nullable mediaInfo;
    @property (weak, nonatomic) id<KPlayPositionInfo> _Nullable positionInfo;

    @property KGraphState state;
    @property NSObject * _Nonnull state_mutex;
    @property NSMutableArray<KFilter*> * _Nullable chain;
@end



//@protocol KBufferInfo
//    -(float) minTsSec;
//    -(float) maxTsSec;
//@end
//
