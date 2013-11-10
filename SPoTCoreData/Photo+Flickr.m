//
//  Photo+Flickr.m
//  SPoTCoreData
//
//  Created by Manners Oshafi on 02/11/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import "Photo+Flickr.h"
#import "FlickrFetcher.h"
#import "Tag+Flickr.h"
#import "Recent+Flickr.h"

@implementation Photo (Flickr)

+ (Photo *)photoWithFlickrInfo:(NSDictionary *)photoDictionary
        inManagedObjectContext:(NSManagedObjectContext *)context {
    Photo *photo = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"unique = %@",
                         [photoDictionary[FLICKR_PHOTO_ID] description]];
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    if (!matches || ([matches count] > 1) || error) {
        NSLog(@"Error in photoWithFlickrInfo: %@ %@", matches, error);
    } else if (![matches count]) {
        photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo"
                                              inManagedObjectContext:context];
        photo.unique = [photoDictionary[FLICKR_PHOTO_ID] description];
        NSString *photoTitle = [photoDictionary[FLICKR_PHOTO_TITLE] description];
        if ([photoTitle length] == 0) {
            photoTitle = @"None";
        }
        photo.title = photoTitle;
        photo.subtitle = [[photoDictionary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION] description];
        photo.imageURL = [[FlickrFetcher urlForPhoto:photoDictionary
                                         format:([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                           ? FlickrPhotoFormatOriginal : FlickrPhotoFormatLarge] absoluteString];
        photo.thumbnailURL = [[FlickrFetcher urlForPhoto:photoDictionary
                                                  format:FlickrPhotoFormatSquare] absoluteString];
        photo.sectionName = [photo.title substringToIndex:1];

        photo.tags = [Tag tagsFromFlickrInfo:photoDictionary
                      inManagedObjectContext:context];
        photo.expired = NO;
        
        NSArray *tags = [[photo.tags allObjects] sortedArrayUsingComparator:^NSComparisonResult(Tag *tag1, Tag *tag2) {
            return [tag1.name compare:tag2.name];
        }];
        photo.tagString = [((Tag *)tags[1]).name capitalizedString];
    } else {
        photo = [matches lastObject];
    }
    return photo;
}

- (void)deletePhoto {
    self.expired = [NSNumber numberWithBool:YES];
    for (Tag *tag in self.tags) {
        if ([tag.photos count] == 1) {
            [self.managedObjectContext deleteObject:tag];
        }
    }
    self.tags = nil;
    if (self.recent) {
        [self.managedObjectContext deleteObject:self.recent];
    }
}

@end
