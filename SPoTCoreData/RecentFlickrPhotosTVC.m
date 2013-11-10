//
//  RecentFlickrPhotosTVC.m
//  SPoT
//
//  Created by Manners Oshafi on 21/10/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import "RecentFlickrPhotosTVC.h"
#import "RecentFlickrPhotos.h"
#import "SharedDocumentHandler.h"

@interface RecentFlickrPhotosTVC ()
@property (nonatomic, strong) SharedDocumentHandler *sh;
@end

@implementation RecentFlickrPhotosTVC

- (SharedDocumentHandler *)sh {
    if (!_sh) {
        _sh = [SharedDocumentHandler sharedDocumentHandler];
    }
    return _sh;
}

- (void)setupFetchedResultsController
{
    if (self.sh.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"recent.lastViewed"
                                                                  ascending:NO]];
        request.predicate = [NSPredicate predicateWithFormat:@"recent != nil AND expired == %@", NO];
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:self.sh.managedObjectContext
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:nil];
    } else {
        self.fetchedResultsController = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[self.sh useDocumentWithOperation:^(BOOL success) {
        [self setupFetchedResultsController];
    }];
}

@end
