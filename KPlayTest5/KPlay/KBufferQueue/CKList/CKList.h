//
//  CKList.h
//  CollectionsKit
//
//  Created by Igor Rastvorov on 11/30/14.
//  Copyright (c) 2014 Igor Rastvorov. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "CKCollection.h"
//#import "CKQueue.h"

/**
 `CKList` is a formal protocol for all the adopters that represent a heterogenous list of objects.
 */
@protocol CKList // <CKCollection, CKQueue>

    @property(nonatomic, assign, readonly) NSUInteger size;


    -(void) removeAllObjects;
    -(NSString *) description;

    -(BOOL) isEmpty;
    -(void) addOrdered:(id)object withCompare:(int (^)(id a, id b))compare;
    
    /// --------------------------------
    /// @name Adding objects to the list
    /// --------------------------------
    
    /**
     Adds object to the head of the list.
     @param object An object to add to head.
     */
   // -(void) addObjectToHead:(id) object;

    -(void) addObjectToTail:(id)object;
    
    /// -----------------------------------
    /// @name Getting objects from the list
    /// -----------------------------------
    
    /**
     Retrieves object at the tail of the list.
     @throws `NSRangeException` if the list is empty.
     */
    -(id) objectAtTail;
    -(id) objectAtHead ;
    
    /**
     Retrieves object at the specified position in the list.
     @param index Specifies the position to remove object from.
     @throws `NSRangeException` if the list is empty.
     */
  //  -(id) objectAtIndex:(NSUInteger) index;
    
    /// ------------------------------------
    /// @name Removing objects from the list
    /// ------------------------------------
    
    /**
     Removes object from the head.
     
     @throws `NSRangeException` if the list is empty.
     */
    -(void) removeObjectFromHead;
    
    /**
     Removes object from the tail.
     
     @throws `NSRangeException` if the list is empty.
     */
   // -(void) removeObjectFromTail;
    
    /**
     Removes object from the specified position in the list.
     
     @param index Specifies the position to remove object from.
     @throws `NSRangeException` if the list is empty.
     */
   // -(void) removeObjectAtIndex:(NSUInteger) index;
    
    /**
     Constructs a new list within a range of the original list.
     
     @param range Range of objects within the original list. Objects within the specified range will be added to a sublist.
     */
    //-(id <CKList>) sublistWithRange:(NSRange) range;
    
    /**
     Finds and returns an index of the first occurence of the specified object.
     
     @param object Object first occurence of which is to be found.
     */
  //  -(NSUInteger) indexOfObject:(id) object;
    
    /**
     Finds and returns an index of the last occurence of the specified object.
     
     @param object Object last occurence of which is to be found.
     */
  //  -(NSUInteger) lastIndexOfObject:(id) object;

@end
