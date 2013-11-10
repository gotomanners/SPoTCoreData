//
//  SharedDocumentHandler.m
//  SPoTCoreData
//
//  Created by Manners Oshafi on 02/11/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import "SharedDocumentHandler.h"

@interface SharedDocumentHandler ()
@property (nonatomic, strong) UIManagedDocument *document;
@end

@implementation SharedDocumentHandler

+ (SharedDocumentHandler *)sharedDocumentHandler {
    __strong static SharedDocumentHandler *_sharedDocumentHandler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDocumentHandler = [[self alloc] init];
    });
    return _sharedDocumentHandler;
}

- (void)useDocumentWithOperation:(void (^)(BOOL))operationBlock {
    UIManagedDocument *document = self.document;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[document.fileURL path]]) {
        [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success){
            self.managedObjectContext = document.managedObjectContext;
            operationBlock(success);
        }];
    } else if (document.documentState == UIDocumentStateClosed) {
        [document openWithCompletionHandler:^(BOOL success) {
            self.managedObjectContext = document.managedObjectContext;
            operationBlock(success);
        }];
    } else {
        self.managedObjectContext = document.managedObjectContext;
        operationBlock(YES);
    }
}

- (void)saveDocument
{
    [self.document saveToURL:self.document.fileURL
            forSaveOperation:UIDocumentSaveForOverwriting
           completionHandler:NULL];
}

- (UIManagedDocument *)document
{
    if (!_document) {
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                             inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:@"SPoTDocument"];
        _document = [[UIManagedDocument alloc] initWithFileURL:url];
    }
    return _document;
}

@end
