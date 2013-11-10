//
//  FlickrPhotoTVC.m
//  SPoT
//
//  Created by Manners Oshafi on 20/10/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import "FlickrPhotoTVC.h"
#import "FlickrFetcher.h"
#import "RecentFlickrPhotos.h"
#import "Tag+Flickr.h"
#import "Photo+Flickr.h"
#import "Recent+Flickr.h"
#import "SharedDocumentHandler.h"

@interface FlickrPhotoTVC () <UISearchBarDelegate>
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIBarButtonItem *searchButton;
@property (nonatomic, strong) NSPredicate *searchPredicate;
@end

@implementation FlickrPhotoTVC

- (UISearchBar *)searchBar {
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] initWithFrame:self.navigationController.navigationBar.frame];
        _searchBar.delegate = self;
    }
    return _searchBar;
}

- (UIBarButtonItem *)searchButton {
    if (!_searchButton) {
        _searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonPressed:)];
    }
    return _searchButton;
}

- (IBAction)searchButtonPressed:(id)sender {
    if (self.tableView.tableHeaderView) {
        self.tableView.tableHeaderView =  nil;
    } else {
        self.tableView.tableHeaderView = self.searchBar;
        if (self.searchPredicate) {
            self.searchPredicate = nil;
            [self setupFetchedResultsController];
        }
        [self.searchBar becomeFirstResponder];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText length]) {
        self.searchPredicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@ OR subtitle contains %@ OR sectionName contains %@", searchText, searchText, searchText];
    } else {
        self.searchPredicate = nil;
    }
    [self setupFetchedResultsController];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.tableView.tableHeaderView = nil;
}

- (void)setTag:(Tag *)tag {
    _tag = tag;
    self.title = [tag.name capitalizedString];
    if ([tag.name isEqualToString:ALL_TAGS_VALUE]) {
        self.title = ALL_TAGS_STRING;
    }
    [self setupFetchedResultsController];
}

- (void)setupFetchedResultsController
{
    if (self.tag.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
        
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title"
                                                                  ascending:YES
                                                                   selector:@selector(localizedCaseInsensitiveCompare:)]];
        NSString *sectionNameKeyPath = @"sectionName";
        if ([self.tag.name isEqualToString:ALL_TAGS_VALUE]) {
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tagString" ascending:YES],
                                        [request.sortDescriptors lastObject]];
            sectionNameKeyPath = @"tagString";
        }
        
        request.predicate = [NSPredicate predicateWithFormat:@"(%@ IN tags) AND (expired == %@)", self.tag, NO];
        
        if (self.searchPredicate) {
            request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[request.predicate, self.searchPredicate]];
        }
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:self.tag.managedObjectContext
                                                                              sectionNameKeyPath:sectionNameKeyPath
                                                                                       cacheName:nil];
    } else {
        self.fetchedResultsController = nil;
    }
}

#pragma mark - segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Show Image"]) {
                if ([segue.destinationViewController respondsToSelector:@selector(setImageURL:)]) {
                    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
                    [segue.destinationViewController performSelector:@selector(setImageURL:) withObject:[NSURL URLWithString:photo.imageURL]];
                    [segue.destinationViewController performSelector:@selector(setTitle:) withObject:photo.title];
                    [Recent recentPhoto:photo];
                    [[SharedDocumentHandler sharedDocumentHandler] saveDocument];
                    
                }
            }
        }
    }
}

#pragma mark - Table view data source

- (NSString *) titleForPhoto: (Photo *)photo {
    NSString *title = [photo.title description];
    if ([title length] == 0) {
        title = @"None";
    }
    return title;
}

- (NSString *) subtitleForPhoto: (Photo *)photo {
    return [photo.subtitle description];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Flickr Photo";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [self titleForPhoto:photo];
    cell.detailTextLabel.text = [self subtitleForPhoto:photo];
    cell.imageView.image = [UIImage imageWithData:photo.thumbnail];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    if (!cell.imageView.image) {
        dispatch_queue_t thumnailQ = dispatch_queue_create("thumbnail Loader", NULL);
        dispatch_async(thumnailQ, ^{
            NSData *thumnailData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:photo.thumbnailURL]];
            [photo.managedObjectContext performBlock:^{
                photo.thumbnail = thumnailData;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell setNeedsLayout];
                });
            }];
        });
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"EEE, dd MMMM yyyy HH:mm:ss VVVV"];
    
    NSString *formattedDateString = [dateFormatter stringFromDate:photo.recent.lastViewed];
    
    NSString *infoMessage = [NSString stringWithFormat:@"Last viewed on \n%@", formattedDateString];
    
    UIAlertView *alertInfo = [[UIAlertView alloc] initWithTitle:[self titleForPhoto:photo]
                                                        message:infoMessage
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
    [alertInfo show];
}

-  (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [photo.managedObjectContext performBlock:^{
            [photo deletePhoto];
            [[SharedDocumentHandler sharedDocumentHandler] saveDocument];
        }];
    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.searchButton;
}

@end