//
//  FlickrTagTVC.m
//  SPoT
//
//  Created by Manners Oshafi on 20/10/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import "FlickrTagTVC.h"
#import "FlickrFetcher.h"
#import "SharedDocumentHandler.h"
#import "Tag+Flickr.h"
#import "Photo+Flickr.h"

@interface FlickrTagTVC () <UISplitViewControllerDelegate, UISearchBarDelegate>
@property (nonatomic, strong) SharedDocumentHandler *sh;
@property (nonatomic, strong) UIBarButtonItem *searchButton;
@property (nonatomic, strong) NSPredicate *searchPredicate;
@property (nonatomic, strong) UISearchBar *searchBar;
@end

@implementation FlickrTagTVC

- (UISearchBar *)searchBar {
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] initWithFrame:self.navigationController.navigationBar.frame];
        self.searchBar.delegate = self;
    }
    return _searchBar;
}

- (UIBarButtonItem *) searchButton {
    if (!_searchButton) {
        _searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonPressed:)];
    }
    return _searchButton;
}

- (SharedDocumentHandler *)sh {
    if (!_sh) {
        _sh = [SharedDocumentHandler sharedDocumentHandler];
    }
    return _sh;
}

- (void) setupFetchedResultsController {
    if (self.sh.managedObjectContext) {
        NSFetchRequest *request  = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES
                                                                   selector:@selector(localizedCaseInsensitiveCompare:)]];
        request.predicate = self.searchPredicate;
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:self.sh.managedObjectContext
                                                                              sectionNameKeyPath:nil cacheName:nil];
    } else {
        self.fetchedResultsController = nil;
    }
}

- (void)loadPhotosFromFlickr {
    if (!self.sh.managedObjectContext) {
        [self.sh useDocumentWithOperation:^(BOOL success) {
            [self setupFetchedResultsController];
        }];
    }
    [self.refreshControl beginRefreshing];
    dispatch_queue_t loaderQ = dispatch_queue_create("Flickr Loader", NULL);
    dispatch_async(loaderQ, ^{
        NSArray *stanfordPhotos = [FlickrFetcher latestGeoreferencedPhotos];
        [self.sh.managedObjectContext performBlock:^{
            for (NSDictionary *photo in stanfordPhotos) {
                [Photo photoWithFlickrInfo:photo
                    inManagedObjectContext:self.sh.managedObjectContext];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
                [self.sh saveDocument];
            });
        }];
    });
    [self setupFetchedResultsController];
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
        self.searchPredicate = [NSPredicate predicateWithFormat:@"name contains[cd] %@ OR name contains %@", searchText, ALL_TAGS_VALUE];
    } else {
        self.searchPredicate = nil;
    }
    [self setupFetchedResultsController];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.tableView.tableHeaderView = nil;
}

#pragma mark - UISplitViewControllerDelegate

- (void)awakeFromNib {
    self.splitViewController.delegate = self;
}

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
    return NO;
}

#pragma mark - segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Show Photos For Tag"]) {
                if ([segue.destinationViewController respondsToSelector:@selector(setTag:)]) {
                    Tag *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];
                    [segue.destinationViewController performSelector:@selector(setTag:) withObject:tag];
                }
            }
        }
    }
}

#pragma mark - Table view data source

- (NSString *) titleForTag: (Tag *)tag {
    NSString *title = [tag.name capitalizedString];
    if ([title isEqualToString:ALL_TAGS_VALUE]) {
        title = ALL_TAGS_STRING;
    }
    if ([title length] == 0) {
        title = @"None";
    }
    return title;
}

- (NSString *) subtitleForTag: (Tag *)tag {
    int photoCount = [tag.photos count];
    return [NSString stringWithFormat:@"%d photo%@", photoCount, photoCount > 1 ? @"s" : @""];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Flickr Tag";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Tag *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [self titleForTag:tag];
    cell.detailTextLabel.text = [self subtitleForTag:tag];
    
    return cell;
}

#pragma mark viewController Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.refreshControl addTarget:self action:@selector(loadPhotosFromFlickr) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.rightBarButtonItem = self.searchButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.sh.managedObjectContext && !self.refreshControl.refreshing) {
        [self.sh useDocumentWithOperation:^(BOOL success) {
            [self setupFetchedResultsController];
            if ([self.fetchedResultsController.fetchedObjects count] == 0) {
                [self loadPhotosFromFlickr];
            }
        }];
    }
}


@end
