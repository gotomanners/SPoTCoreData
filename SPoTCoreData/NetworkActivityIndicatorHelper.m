//
//  NetworkActivityIndicatorHelper.m
//  SPoT
//
//  Created by Manners Oshafi on 27/10/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import "NetworkActivityIndicatorHelper.h"

@implementation NetworkActivityIndicatorHelper

+ (void)start {
    [self counterChange:1];
}

+ (void)stop {
    [self counterChange:-1];
}

+ (void)counterChange:(NSUInteger) change {
    static NSUInteger counter = 0;
    static dispatch_queue_t networkActivityIndicatorQueue;
    if (!networkActivityIndicatorQueue) {
        networkActivityIndicatorQueue = dispatch_queue_create("n=NetworkActivityIndicator Queue", NULL);
    }
    dispatch_sync(networkActivityIndicatorQueue, ^{
        if (counter + change <= 0) {
            counter = 0;
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        } else {
            counter += change;
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        }
    });
}
@end
