//
//  CKLinkedList.m
//  CKLinkedList
//
//  Created by Igor Rastvorov on 11/27/14.
//  Copyright (c) 2014 Igor Rastvorov. All rights reserved.

#import "CKLinkedList.h"

//#define MYDEBUG
#include "myDebug.h"

/**
 Represents a single node in a doubly linked list.
 */
@interface CKListNode : NSObject

    @property(nonatomic, strong) CKListNode *next;
    @property(nonatomic, strong) CKListNode *previous;
    @property(nonatomic, strong) id data;

    -(id) initWithData:(id) data;
  //  -(BOOL) isEqual:(id)object;

@end

@implementation CKListNode

    @synthesize next = _next;
    @synthesize data = _data;

    -(id) initWithData:(id)data {
        self = [super init];
        if (self) {
            [self setData:data];
        }
        
        return self;
    }
//    -(BOOL) isEqual:(id)object {
//        if (object != nil && [object isKindOfClass:[CKListNode class]]) {
//            return [[self data] isEqual:[object data]];
//        }
//
//        return NO;
//    }
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

@interface CKLinkedList ()

    @property(nonatomic, readwrite) NSUInteger size;

    -(CKListNode *) listNodeAtIndex:(NSUInteger) index;
   // -(BOOL) removeNodeAtIndex:(NSUInteger) index;
@end

@implementation CKLinkedList

    @synthesize size = _size;

    #pragma mark - Initializing

//    -(instancetype) init {
//        return [self initWithArray: nil];
//    }

    - (instancetype)init
    {
        self = [super init];
        if (self) {
            
        }
        return self;
    }

//    -(id) initWithArray:(NSArray *)array {
//        self = [super init];
//        if (self) {
//            if (array != nil) {
//                for (id object in array) {
//                    [self addObjectToTail:object];
//                }
//            }
//        }
//
//        return self;
//    }

    #pragma mark - Adding objects

    -(void) addOrdered:(id)object withCompare:(int (^)(id a, id b))compare
    {
        CKListNode *cur = _head;
        BOOL added = FALSE;
        while(cur!=nil){
            if (compare(cur.data,object)<=0) {
                cur = cur.next;
            } else {
                CKListNode *listNode = [[CKListNode alloc] initWithData:object];
                listNode.next =  listNode.previous = nil;
                listNode.data = object;
                
                
                
                
                listNode.next = cur;
                listNode.previous = cur.previous;
                
                if (cur.previous)
                    cur.previous.next = listNode;
                cur.previous = listNode;
                
                if (cur == _head)
                    _head = listNode;
                
                
                
                DLog(@"");
                added = TRUE;
                ++self.size;
                break;
            }
        }
        if (!added)
            [self addObjectToTail:object];
      //  DLog(@"%@", [self description]);
    }

//    -(void) addObjectToHead:(id)object {
//        CKListNode *listNode = [[CKListNode alloc] initWithData:object];
//
//        listNode.data = object;
//        listNode.previous = nil;
//        listNode.next = _head;
//        _head.previous = listNode;
//
//        _head = listNode;
//
//        if ([self isEmpty]) {
//            _tail = _head;
//        }
//
//        ++self.size;
//    }

    #pragma mark - CKQueue

    -(void) addObjectToTail:(id)object {
        CKListNode *listNode = [[CKListNode alloc] initWithData:object];
        listNode.next =  listNode.previous = nil;
        listNode.data = object;
        
        
        if ([self isEmpty]) {
            _tail = _head = listNode;
            
        } else {
            listNode.previous = _tail;
            
            _tail.next = listNode;
            _tail = listNode;
            
            
        }
        
       ++self.size;

        
        
        
       
    }

    #pragma mark - Retrieving objects

    -(id) objectAtTail {
        if (_tail==nil)
            return nil;
        return _tail.data;
    }
//    -(id) objectAtIndex:(NSUInteger) index {
//        return [[self listNodeAtIndex:index] data];
//    }

//    -(id <CKList>) sublistWithRange:(NSRange) range {
//        id <CKList> sublist = [[CKLinkedList alloc] init];
//        
//        NSUInteger endIndex = range.location + range.length;
//        for (NSUInteger startIndex = range.location; startIndex <= endIndex; ++startIndex) {
//            CKListNode *currentNode = [self listNodeAtIndex:startIndex];
//            [sublist addObjectToTail: currentNode];
//        }
//        
//        return sublist;
//    }

//    -(NSUInteger) indexOfObject:(id) object {
//        NSUInteger size = [self size];
//        for (NSUInteger index = 0; index <= size; ++index) {
//            if ([[self objectAtIndex:index] isEqual:object]) {
//                return index;
//            }
//        }
//
//        return NSNotFound;
//    }

//    -(NSUInteger) lastIndexOfObject:(id) object {
//        for (NSUInteger index = [self size] - 1; index != 0; --index) {
//            if ([[self objectAtIndex:index] isEqual:object]) {
//                return index;
//            }
//        }
//
//        return NSNotFound;
//    }

    #pragma mark - CKQueue
    -(id) objectAtHead {
        if (_head==nil)
            return nil;
        return _head.data;
    }

    #pragma mark - Removing objects

    -(void) removeObjectFromTail {
        if ([self removeNode:_tail]){
            --self.size;
        }
    }
//    -(void) removeObjectAtIndex:(NSUInteger) index {
//        if ([self removeNodeAtIndex:index]){
//            --self.size;
//        }
//    }

    #pragma mark - CKQueue
    -(void) removeObjectFromHead {
        if ([self removeNode:_head]){
            --self.size;
        }
    }

    #pragma mark - CKCollection

    -(void) removeAllObjects {
        NSInteger size = [self size];
        for (NSUInteger listNodeIndex = 0; listNodeIndex < size; ++listNodeIndex) {
            [self removeObjectFromHead];
        }
    }

    #pragma mark - List state

    #pragma mark - CKCollection

//    -(BOOL) containsObject:(id) object {
//        NSUInteger size = [self size];
//        for (NSUInteger i = 0; i < size; ++i) {
//            if ([[self objectAtIndex:i] isEqual:object]) {
//                return YES;
//            }
//        }
//
//        return NO;
//    }

    -(NSString *) description {
        if ([self isEmpty]) {
            return @"(empty)";
        }
        
        NSString *contents = [NSMutableString stringWithString:@"(\n"];
        
        NSUInteger listNodeIndex;
        for (listNodeIndex = 0; listNodeIndex < [self size] - 1; ++listNodeIndex) {
            
            contents = [contents stringByAppendingString:[NSString stringWithFormat:@"\t%@,\n", [self listNodeAtIndex:listNodeIndex]]];
        }
        contents = [contents stringByAppendingString:[NSString stringWithFormat:@"\t%@\n)", [self listNodeAtIndex:listNodeIndex]]];
        
        return contents;
    }

    -(BOOL) isEmpty {
        return self.size == 0;
    }

//    -(BOOL) isEqual:(id) object {
//        if (object != nil && [object isKindOfClass:[CKLinkedList class]]) {
//            if ([self size] != [object size]) {
//                return NO;
//            }
//
//            CKListNode *listNode = nil;
//            CKListNode *comparedListNode = nil;
//
//            for (NSUInteger listNodeIndex = 0; listNodeIndex < [self size]; ++listNodeIndex) {
//                listNode = [self listNodeAtIndex:listNodeIndex];
//                comparedListNode = [object listNodeAtIndex:listNodeIndex];
//
//                if (![listNode isEqual:comparedListNode]) {
//                    return NO;
//                }
//            }
//        }
//
//        return YES;
//    }

//    -(NSUInteger) hash {
//        if ([self isEmpty]) {
//            return [super hash];
//        }
//
//        NSUInteger hashCode = [[self objectAtIndex:0] hash];;
//        for (NSUInteger i = 1; i < [self size]; ++i) {
//            hashCode ^= [[self objectAtIndex:i] hash];
//        }
//
//        return hashCode;
//    }

//    -(NSArray *) toArray {
//        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self size]];
//
//        for (NSUInteger index = 0; index < [self size]; ++index) {
//            [array addObject:[self objectAtIndex:index]];
//        }
//
//        return array;
//    }

    -(void)dealloc
    {
        DLog(@"dealloc LinkedList");
        [self removeAllObjects];
    }

    

// ---------------------------------
// Private interface
// ---------------------------------

-(CKListNode *) listNodeAtIndex:(NSUInteger) index {
    if (index >= [self size] ) {
        return nil;
    }

    CKListNode *listNode = _head;
    for (NSUInteger listNodeIndex = 0; listNodeIndex < index; ++listNodeIndex) {
        listNode = [listNode next];
    }

    return listNode;
}

-(BOOL) removeNode:(CKListNode *) deallocationTarget {

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
