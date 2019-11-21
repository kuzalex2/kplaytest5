////
////  KPlayGraph.h
////  KPlayer
////
////  Created by test name on 26.04.2019.
////  Copyright © 2019 Instreamatic. All rights reserved.
////
//
//#import <Foundation/Foundation.h>
//#import <GLKit/GLKit.h>
//
//#import <CoreMedia/CMSampleBuffer.h>
//
//#import "KMediaSample.h"
//#import "KPin.h"
//#import "KFilter.h"
//#import "KClock.h"
//#import "KFilter.h"
////#import "../Filters/KQueue/KQueueFilter.h" // for BufferInfo
//
//
//NS_ASSUME_NONNULL_BEGIN
//
//@protocol KBufferInfo
//    -(float) minTsSec;
//    -(float) maxTsSec;
//@end
//
//typedef enum
//{
//    KGraphBuildState_NO,
//    KGraphBuildState_STARTED,
//    KGraphBuildState_FINISHED
//} KGraphBuildState;
//
//
//@interface KPlayGraph : NSObject {
//    @protected BOOL _connected;
//}
//    - (KGraphBuildState) build_state;
//    @property BOOL connected;
//    @property (readonly) id<KBufferInfo> bufferInfo;
//    @property (readonly) KFilterState state;
//    @property float rate;
//    @property (readonly) BOOL isLive;
//    @property (readonly) KClock *clock;
//
//    @property void (^play_error_callback2)(KResult result, NSError *error);
//   // @property void (^build_error_callback2)(KResult result, NSError *error);
//
//
//
//    - (instancetype)init;
//    -(KResult)startBuild:(void (^)(void))success error:(void (^)(void))error;
//    -(KResult)stopBuild;
//    -(KResult) doGraphBuild;
//    - (void)start;
//    - (void)pause;
//    - (void)stop;
//    - (void)disconnect;
//
//
//    -(NSString *)name;
//
//    +(BOOL)Connect:(KFilter *)src :(size_t)src_pin_index :(KFilter *)dst :(size_t)dst_pin_index;
//@end
//
//
//NS_ASSUME_NONNULL_END
