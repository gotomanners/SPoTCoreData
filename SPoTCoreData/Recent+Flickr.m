//
//  Recent+Flickr.m
//  SPoTCoreData
//
//  Created by Manners Oshafi on 02/11/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import "Recent+Flickr.h"
#import "Photo.h"

@implementation Recent (Flickr)

#define RECENT_FLICKR_PHOTOS_NUMBER 10
+ (Recent *)recentPhoto:(Photo *)photo
{
    Recent *recent = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Recent"];
    request.predicate = [NSPredicate predicateWithFormat:@"photo = %@", photo];
    NSError *error = nil;
    NSArray *matches = [photo.managedObjectContext executeFetchRequest:request
                                                                 error:&error];
    if (!matches || ([matches count] > 1)) {
        // handle error
    } else if (![matches count]) {
        recent = [NSEntityDescription insertNewObjectForEntityForName:@"Recent"
                                               inManagedObjectContext:photo.managedObjectContext];
        recent.photo = photo;
        recent.lastViewed = [NSDate date];
        request.predicate = nil;
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"lastViewed"
                                                                  ascending:NO]];
        matches = [photo.managedObjectContext executeFetchRequest:request
                                                            error:&error];
        if ([matches count] > RECENT_FLICKR_PHOTOS_NUMBER) {
            [photo.managedObjectContext deleteObject:[matches lastObject]];
        }
    } else {
        recent = [matches lastObject];
        recent.lastViewed = [NSDate date];
    }
    return recent;
}

@end
