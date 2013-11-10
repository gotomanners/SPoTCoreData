//
//  Tag+Flickr.h
//  SPoTCoreData
//
//  Created by Manners Oshafi on 02/11/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import "Tag.h"

@interface Tag (Flickr)
#define ALL_TAGS_VALUE @"0000"
#define ALL_TAGS_STRING @"All"
+ (NSSet *)tagsFromFlickrInfo:(NSDictionary *)photoDictionary
       inManagedObjectContext:(NSManagedObjectContext *)context;

@end
