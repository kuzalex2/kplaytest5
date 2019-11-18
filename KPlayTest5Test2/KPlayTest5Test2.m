//
//  KPlayTest5Test2.m
//  KPlayTest5Test2
//
//  Created by kuzalex on 11/18/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KTestFilters.h"
#import "KPlayGraph.h"
#define MYDEBUG
#define MYWARN
#import "myDebug.h"

@interface KPlayTest5Test2  : XCTestCase<KPlayEvents>

@end

@implementation KPlayTest5Test2

    KFilter *src;
    KFilter *dec;
    KTestSinkFilter *sink;

   - (void)onError:(KFilter *)filter result:(KResult)result error:( NSError * _Nullable )error
   {
       DLog(@"onError %@ %d %@", [filter name], result, error);
   }
   - (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
   {
      // if ([filter.events respondsToSelector:@selector(onStateChanged:state:)])
        //   [filter.events onStateChanged:filter state:state];
       DLog(@"onStateChanged %@ %@ ", [filter name], KFilterState2String(state) );
   }

   - (void)start
   {
       [src start];
       [dec start];
       [sink start];
   }
   - (void)pause:(BOOL)waitUntilPaused
   {
       [src pause:waitUntilPaused];
       [dec pause:waitUntilPaused];
       [sink pause:waitUntilPaused];
   }
   -(void)stop:(BOOL)waitUntilStopped
   {
       [src stop:waitUntilStopped];
       [dec stop:waitUntilStopped];
       [sink stop:waitUntilStopped];
   }

   +(BOOL)Connect:(KFilter *)src :(size_t)src_pin_index :(KFilter *)dst :(size_t)dst_pin_index
   {
       KPin *pout = [src getOutputPinAt:src_pin_index];
       KPin *pin  = [dst getInputPinAt:dst_pin_index];
   
       if (pout==nil){
           DErr(@"No outpin %ld at %@",src_pin_index,src);
           return FALSE;
       }
   
       if (pin==nil){
           DErr(@"No inpin %ld at %@",dst_pin_index,dst);
           return FALSE;
       }
   
       if (! [pout connectTo:pin] ) {
           DErr(@"failed to connect (%@)%ld->(%@)%ld", [src name], src_pin_index, [dst name], dst_pin_index);
           return FALSE;
       }
   
       return TRUE;
   }

   - (void)setUp {
       // Put setup code here. This method is called before the invocation of each test method in the class.
   }

   - (void)tearDown {
       // Put teardown code here. This method is called after the invocation of each test method in the class.
   }

   - (void)testSimpleGraphStartPauseStop {
       
       src = [[KTestSourceFilter alloc] init];
       dec = [[KTestTransformFilter alloc] init];
       sink = [[KTestSinkFilter alloc] init];
       
       src.events = dec.events = sink.events = self;
       
       XCTAssert([KPlayTest5Test2 Connect:src :0 :dec :0]);
       XCTAssert([KPlayTest5Test2 Connect:dec :0 :sink :0]);
     
       [self pause:true];
       
       sleep(1);
       
       XCTAssert(sink->_consumed_samples>0);
       
       [self pause:true];
       [self stop:true];
   }

   - (void)testSimpleGraphUrlStartPauseStop {
       KMediaSample *sample;
       NSError *error;
       KResult res;
       
       
       src = [[KTestUrlSourceFilter alloc] initWithUrl:@"https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/v9/fileSequence97.ts"];
       [src pause:true];
       
       XCTAssert ( (res = [src pullSample:&sample probe:YES error:&error]) == KResult_OK );
         
       dec = [[KTestTransformFilter alloc] init];
       
       sink = [[KTestSinkFilter alloc] init];
       
       
       src.events = dec.events = sink.events = self;
       
       XCTAssert([KPlayTest5Test2 Connect:src :0 :dec :0]);
       XCTAssert([KPlayTest5Test2 Connect:dec :0 :sink :0]);
     
       [self pause:true];
       
       sleep(1);
       
       [self start];
       
       sleep(3);
       
       XCTAssert(sink->_consumed_samples>0);
       
       [self pause:true];
       [self stop:true];
   }



@end
