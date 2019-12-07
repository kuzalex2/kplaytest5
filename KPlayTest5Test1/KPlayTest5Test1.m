//
//  KPlayTest5Test1.m
//  KPlayTest5Test1
//
//  Created by kuzalex on 11/18/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <XCTest/XCTest.h>
//#define MYDEBUG
//#define MYWARN
#import "myDebug.h"
#import "KFilter.h"

@interface KPlayTest5Test1 : XCTestCase<KPlayEvents>

@end

@implementation KPlayTest5Test1

- (void)testExample {
    KFilter *k = [[KFilter alloc]init];
    k.events = self;
    [k start];
}



@end
