//
//  Recent.h
//  SPoTCoreData
//
//  Created by Manners Oshafi on 05/11/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo;

@interface Recent : NSManagedObject

@property (nonatomic, retain) NSDate * lastViewed;
@property (nonatomic, retain) Photo *photo;

@end
