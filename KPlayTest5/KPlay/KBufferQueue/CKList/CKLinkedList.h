//
//  CKLinkedList.h
//  CKLinkedList
//
//  Created by Igor Rastvorov on 11/27/14.
//  Copyright (c) 2014 Igor Rastvorov. All rights reserved.
//  ARC compatibe.

#import <Foundation/Foundation.h>
#include "CKList.h"

@class CKListNode;

/**
 Represents a linked list of objects.
 */
@interface CKLinkedList : NSObject <CKList> {
    CKListNode *_head;
    CKListNode *_tail;
}

@end
