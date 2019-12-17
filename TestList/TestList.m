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



- (void)testExample {
    
    KLinkedList *list = [[KLinkedList alloc]init];
    NSComparator comparator = ^(id cur, id new) {
        NSNumber *CUR = cur;
        NSNumber *NEW = new;
        NSComparisonResult ret = (int)[NEW compare:CUR];
        return ret;
    };
    
    [list addOrdered:[NSNumber numberWithInt:1] withCompare:comparator];
    NSLog(@"%@", list);
    [list addOrdered:[NSNumber numberWithInt:2] withCompare:comparator];
    NSLog(@"%@", list);
    [list addOrdered:[NSNumber numberWithInt:3] withCompare:comparator];
    NSLog(@"%@", list);
    [list addOrdered:[NSNumber numberWithInt:4] withCompare:comparator];
    NSLog(@"%@", list);
    [list addOrdered:[NSNumber numberWithInt:5] withCompare:comparator];
    NSLog(@"%@", list);
    
//    for(int i=0, b=1.0;i<10;i++){
//        NSLog(@"%d %d", i, b);
//    }
    
    
    KLinkedListNode *cur = list->_head;
    while (cur){
        NSLog(@"%@", [cur data]);
        cur=cur.next;
    }
    
    
  
     
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}



@end
