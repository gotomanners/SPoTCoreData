//
//  ImageViewController.m
//  SPoT
//
//  Created by Manners Oshafi on 20/10/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import "ImageViewController.h"
#import "AttributedStringViewController.h"
#import "NetworkActivityIndicatorHelper.h"
#import "FlickrCache.h"

@interface ImageViewController () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *titleBarButtonItem;
@property (strong, nonatomic) UIPopoverController *urlPopover;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@end

@implementation ImageViewController

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"Show URL"]) {
        return self.imageURL && !self.urlPopover.popoverVisible ? YES : NO;
    } else {
        return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Show URL"]) {
        if ([segue.destinationViewController isKindOfClass:[AttributedStringViewController class]]) {
            AttributedStringViewController *asc = (AttributedStringViewController *) segue.destinationViewController;
            asc.text = [[NSAttributedString alloc] initWithString:[self.imageURL description]];
            if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
                self.urlPopover = ((UIStoryboardPopoverSegue *)segue).popoverController;
            }
        }
    }
}

- (void)setTitle:(NSString *)title {
    super.title = title;
    self.titleBarButtonItem.title = self.title;
}

- (void)setImageURL:(NSURL *)imageURL {
    _imageURL = imageURL;
    [self resetImage];
}

- (void) resetImage {
    if (self.scrollView) {
        self.scrollView.contentSize = CGSizeZero;
        self.imageView.image = nil;
        
        [self.spinner startAnimating];
        NSURL *imageURL = self.imageURL; // compare with url after async
        
        dispatch_queue_t imageFetchQ = dispatch_queue_create("image fetcher", NULL);
        dispatch_async(imageFetchQ, ^{
            NSData *imageData;
            NSURL *cachedImageURL = [FlickrCache cachedURLforURL:imageURL];
            if (cachedImageURL){
                imageData = [[NSData alloc] initWithContentsOfURL:cachedImageURL];
            } else {
                [NetworkActivityIndicatorHelper start];
                 imageData = [[NSData alloc] initWithContentsOfURL:self.imageURL];
                [NetworkActivityIndicatorHelper stop];
            }
            [FlickrCache cacheData:imageData forURL:self.imageURL];
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            if (self.imageURL == imageURL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (image) {
                        self.scrollView.zoomScale = 1.0;
                        self.scrollView.contentSize = image.size;
                        self.imageView.image = image;
                        self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
                    }
                    [self.spinner stopAnimating];
                });
            }
        });
    }
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    }
    return _imageView;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    double wScale = self.scrollView.bounds.size.width / self.imageView.image.size.width;
    double hScale = self.scrollView.bounds.size.height / self.imageView.image.size.height;
    if (wScale > hScale) {
        self.scrollView.zoomScale = wScale;
    } else {
        self.scrollView.zoomScale = hScale;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.scrollView addSubview:self.imageView];
    self.scrollView.minimumZoomScale = 0.2;
    self.scrollView.maximumZoomScale = 5.0;
    self.scrollView.delegate = self;
//    [self resetImage];
    self.titleBarButtonItem.title = self.title;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self resetImage];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.imageView.image = nil;
}

@end
