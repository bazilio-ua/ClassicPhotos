//
//  PhotoOperations.h
//  ClassicPhotos
//
//  Created by Basil Nikityuk on 6/30/18.
//  Copyright (c) 2018 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    kNew,
    kDownloaded,
    kFiltered,
    kFailed
} PhotoRecordState;

@interface PhotoRecord : NSObject
@property (nonatomic, assign)   PhotoRecordState    state;
@property (nonatomic, copy)     NSString            *name;
@property (nonatomic, strong)   NSURL               *url;
@property (nonatomic, strong)   UIImage             *image;

- (id)initWithName:(NSString *)name url:(NSURL *)url;

@end


@interface PendingOperations : NSObject
@property (nonatomic, strong)   NSMutableDictionary *downloadsInProgress;
@property (nonatomic, strong)   NSOperationQueue    *downloadQueue;

@property (nonatomic, strong)   NSMutableDictionary *filtrationsInProgress;
@property (nonatomic, strong)   NSOperationQueue    *filtrationQueue;

@end


@interface ImageDownloader: NSOperation
@property (nonatomic, strong)   PhotoRecord         *photoRecord;

- (id)initWithPhotoRecord:(PhotoRecord *)photoRecord;

@end


@interface ImageFiltration: NSOperation
@property (nonatomic, strong)   PhotoRecord         *photoRecord;

- (id)initWithPhotoRecord:(PhotoRecord *)photoRecord;

@end

