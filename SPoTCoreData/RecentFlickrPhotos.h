//
//  RecentPhotos.h
//  SPoT
//
//  Created by Manners Oshafi on 21/10/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecentFlickrPhotos : NSObject

+ (NSArray *)allPhotos;
+ (void) addPhoto:(NSDictionary *)photo;

@end
