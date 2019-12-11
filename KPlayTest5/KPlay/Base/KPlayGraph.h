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
    - (KResult)seek:(float)sec;
@end

typedef enum
{
    KGraphState_NONE,
    KGraphState_BUILDING,
    KGraphState_STOPPED,
    KGraphState_STOPPING,
    KGraphState_PAUSING,
    KGraphState_PAUSED,
    KGraphState_STARTED,
    KGraphState_SEEKING
} KGraphState;

@protocol KPlayerEvents<NSObject>
@optional
    - (void)onError:( NSError * _Nullable )error;
    - (void)onStateChanged:(KGraphState)state;
@end

@protocol KPlayMediaInfo<NSObject>
    -(CMTime)duration;
   
@end



@protocol KPlayBufferPositionInfo<NSObject>
    -(CMTime)startBufferedPosition;
    -(CMTime)endBufferedPosition;
@end

@interface KPlayGraphChainBuilder : NSObject<KPlayEvents, KPlayer>
    @property (weak, nonatomic) id<KPlayerEvents> _Nullable events;
    @property (weak, nonatomic) id<KPlayMediaInfo> _Nullable mediaInfo;
    @property (weak, nonatomic) id<KPlayPositionInfo> _Nullable positionInfo;
    @property (weak, nonatomic) id<KPlayBufferPositionInfo> _Nullable bufferPositionInfo;

    @property KGraphState state;
    @property NSObject * _Nonnull state_mutex;
    @property NSMutableArray<KFilter*> * _Nonnull flowchain;
    @property NSMutableArray< NSMutableArray<KFilter*> * > * _Nonnull connectchain;
@end



//@protocol KBufferInfo
//    -(float) minTsSec;
//    -(float) maxTsSec;
//@end
//
