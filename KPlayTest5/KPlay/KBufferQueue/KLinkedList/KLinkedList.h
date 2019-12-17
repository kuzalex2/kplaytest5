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
@class ListNode;
@interface KLinkedListIterator : NSObject {
    @public KLinkedList *list;
    @public ListNode *cur;
    
    @public ListNode *next;
    @public ListNode *prev;
}

    
    -(BOOL)isEqualTo:(KLinkedListIterator *)it;
    -(KLinkedListIterator *)next;
    -(KLinkedListIterator *)prev;
    -(id)data;


   

@end


@interface KLinkedList : NSObject
    @property(nonatomic, assign, readonly) NSUInteger count;

    -(KLinkedListIterator *)begin;
    -(KLinkedListIterator *)end;

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
