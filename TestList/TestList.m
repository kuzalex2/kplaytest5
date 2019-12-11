//
//  TestList.m
//  TestList
//
//  Created by kuzalex on 12/11/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KLinkedList.h"

@interface TestList : XCTestCase

@end

@implementation TestList

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

int compare(id a, id b){
    NSNumber *A = a;
    NSNumber *B = b;
    if (A == B)
        return 0;
    return A < B
        ? -1 : 1;
}

-(void)addOrdered:(KLinkedList *)list object:(id)object{
    [list addOrdered:object withCompare:^int (id cur, id new){
        NSNumber *CUR = cur;
        NSNumber *NEW = new;
        int ret = (int)[NEW compare:CUR];
        return ret;
    }];
}

- (void)testExample {
    
    KLinkedList *list = [[KLinkedList alloc]init];
    
    [self addOrdered:list object:[NSNumber numberWithInt:1]];
    NSLog(@"%@", list);
    [self addOrdered:list object:[NSNumber numberWithInt:2]];
    NSLog(@"%@", list);
    [self addOrdered:list object:[NSNumber numberWithInt:3]];
    NSLog(@"%@", list);
    [self addOrdered:list object:[NSNumber numberWithInt:4]];
    NSLog(@"%@", list);
    [self addOrdered:list object:[NSNumber numberWithInt:5]];
    NSLog(@"%@", list);
  
     
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}



@end
