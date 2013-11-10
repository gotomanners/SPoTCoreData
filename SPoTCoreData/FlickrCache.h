//
//  FlickrCache.h
//  SPoT
//
//  Created by Manners Oshafi on 27/10/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FLICKRCACHE_MAXSIZE_IPHONE 1024*1024*3
#define FLICKRCACHE_MAXSIZE_IPAD 1024*1024*10
#define FLICKRCACHE_FOLDER @"flickrPhotos"
@interface FlickrCache : NSObject

+ (NSURL *)cachedURLforURL:(NSURL *)url;
+ (void)cacheData:(NSData *)data forURL:(NSURL *)url;

@end
