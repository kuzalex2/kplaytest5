//
//  KLinkedList.h
//  KPlayTest5
//
//  Created by kuzalex on 12/11/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KLinkedList;
@class KLinkedListNode;

/**
 Represents a single node in a doubly linked list.
 */
@interface KLinkedListNode : NSObject

    @property(nonatomic, strong) KLinkedListNode *next;
    @property(nonatomic, strong) KLinkedListNode *previous;
    @property(nonatomic, strong) id data;

    -(id) initWithData:(id) data;
@end

@interface KLinkedList : NSObject{
    @public KLinkedListNode *_head;
    @public KLinkedListNode *_tail;
}

    @property(nonatomic, assign, readonly) NSUInteger count;

   
    

    -(BOOL) isEmpty;
 
    /// --------------------------------
    /// @name Adding objects to the list
    /// --------------------------------
     
    
    //-(void) addObjectToHead:(id) object;
    -(void) addObjectToTail:(id)object;
    -(void) addOrdered:(id)object withCompare:(NSComparator)compare;



    /// -----------------------------------
    /// @name Getting objects from the list
    /// -----------------------------------
    -(id) objectAtTail;
    -(id) objectAtHead ;


    /// ------------------------------------
    /// @name Removing objects from the list
    /// ------------------------------------
    -(void) removeObjectFromHead;
    -(void) removeAllObjects;


    /// ------------------------------------
    /// @name
    /// ------------------------------------
    -(NSString *) description;

@end

NS_ASSUME_NONNULL_END
