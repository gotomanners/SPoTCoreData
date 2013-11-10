//
//  SharedDocumentHandler.h
//  SPoTCoreData
//
//  Created by Manners Oshafi on 02/11/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SharedDocumentHandler : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+ (SharedDocumentHandler *)sharedDocumentHandler;
- (void)useDocumentWithOperation: (void (^)(BOOL))operationBlock;
- (void)saveDocument;

@end
