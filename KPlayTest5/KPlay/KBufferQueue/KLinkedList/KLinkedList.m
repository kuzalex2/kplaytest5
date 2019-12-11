//
//  KLinkedList.m
//  KPlayTest5
//
//  Created by kuzalex on 12/11/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KLinkedList.h"

//#define MYDEBUG
#include "myDebug.h"

/**
 Represents a single node in a doubly linked list.
 */
@interface ListNode : NSObject

    @property(nonatomic, strong) ListNode *next;
    @property(nonatomic, strong) ListNode *previous;
    @property(nonatomic, strong) id data;

    -(id) initWithData:(id) data;
@end


@implementation ListNode

    @synthesize next = _next;
    @synthesize previous = _previous;
    @synthesize data = _data;

    -(id) initWithData:(id)data {
        self = [super init];
        if (self) {
            self->_next = nil;
            self->_previous = nil;
            [self setData:data];
        }
        
        return self;
    }

    -(NSString *) description {
        return [[self data] description];
    }

    - (void)dealloc
    {
        _next=nil;
        _previous=nil;
        //_data=nil;
        DLog(@"dealloc LinkedListNode");
    }

@end


@implementation KLinkedList {
    ListNode *_head;
    ListNode *_tail;
}

    @synthesize count = _size;


    - (instancetype)init
    {
        self = [super init];
        if (self) {
            
        }
        return self;
    }

    -(void) addObjectToTail:(id)object {
        ListNode *listNode = [[ListNode alloc] initWithData:object];
        
        
        
        if ([self isEmpty]) {
            _tail = _head = listNode;
            
        } else {
            listNode.previous = _tail;
            
            _tail.next = listNode;
            _tail = listNode;
            
            
        }
        
        ++self->_size;
    }

    -(void) addOrdered:(id)object withCompare:(int (^)(id a, id b))compare
    {
        ListNode *cur = _head;
        BOOL added = FALSE;
        
        while(cur!=nil)
        {
            if (compare(cur.data,object)<=0) {
                cur = cur.next;
            } else {
                ListNode *listNode = [[ListNode alloc] initWithData:object];
                
                listNode.next = cur;
                listNode.previous = cur.previous;
                
                if (cur.previous)
                    cur.previous.next = listNode;
                cur.previous = listNode;
                
                if (cur == _head)
                    _head = listNode;
                
                
                
                DLog(@"");
                added = TRUE;
                ++self->_size;
                break;
            }
        }
        
        
        if (!added) {
            [self addObjectToTail:object];
        }
    }

    -(id) objectAtTail {
        if (_tail==nil)
            return nil;
        return _tail.data;
    }

    -(id) objectAtHead {
        if (_head==nil)
            return nil;
        return _head.data;
    }


    -(void) removeObjectFromTail {
        if ([self removeNode:_tail]){
            --self->_size;
        }
    }

    -(void) removeObjectFromHead {
        if ([self removeNode:_head]){
            --self->_size;
        }
    }


    -(void) removeAllObjects {
        NSInteger size = self.count;
        for (NSUInteger listNodeIndex = 0; listNodeIndex < size; ++listNodeIndex) {
            [self removeObjectFromHead];
        }
    }


    -(NSString *) description {
        if ([self isEmpty]) {
            return @"(empty)";
        }
        
        NSString *contents = [NSMutableString stringWithString:@"(\n"];
        
        NSUInteger listNodeIndex;
        for (listNodeIndex = 0; listNodeIndex < self.count - 1; ++listNodeIndex) {
            
            contents = [contents stringByAppendingString:[NSString stringWithFormat:@"\t%@,\n", [self listNodeAtIndex:listNodeIndex]]];
        }
        contents = [contents stringByAppendingString:[NSString stringWithFormat:@"\t%@\n)", [self listNodeAtIndex:listNodeIndex]]];
        
        return contents;
    }

    -(BOOL) isEmpty {
        return self.count == 0;
    }



    -(void)dealloc
    {
        DLog(@"dealloc LinkedList");
        [self removeAllObjects];
    }

    

// ---------------------------------
// Private interface
// ---------------------------------

-(ListNode *) listNodeAtIndex:(NSUInteger) index {
    if (index >= self.count ) {
        return nil;
    }

    ListNode *listNode = _head;
    for (NSUInteger listNodeIndex = 0; listNodeIndex < index; ++listNodeIndex) {
        listNode = [listNode next];
    }

    return listNode;
}

-(BOOL) removeNode:(ListNode *) deallocationTarget {

    if (deallocationTarget == nil){
//        assert(false);
        return FALSE;
    }

    if (deallocationTarget == _head) {
        _head = deallocationTarget.next;
    }
    if (deallocationTarget == _tail) {
        _tail = deallocationTarget.previous;
    }
    
    if (deallocationTarget.previous){
        deallocationTarget.previous.next = deallocationTarget.next;
    }
    
    if (deallocationTarget.next){
        deallocationTarget.next.previous = deallocationTarget.previous;
    }
   // deallocationTarget.data=nil;
    deallocationTarget.next=nil;
    deallocationTarget.previous=nil;

    deallocationTarget = nil;
    return TRUE;
}

-(BOOL) removeNodeAtIndex:(NSUInteger) index {
    return [self removeNode:[self listNodeAtIndex:index]];
}

@end

