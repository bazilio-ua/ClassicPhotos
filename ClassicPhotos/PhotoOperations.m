//
//  PhotoOperations.m
//  ClassicPhotos
//
//  Created by Basil Nikityuk on 6/30/18.
//  Copyright (c) 2018 __MyCompanyName__. All rights reserved.
//

#import "PhotoOperations.h"

@implementation PhotoRecord

@synthesize state = _state;
@synthesize name = _name;
@synthesize url = _url;
@synthesize image = _image;

#pragma mark -
#pragma mark Initializations and Deallocations

- (id)initWithName:(NSString *)name url:(NSURL *)url {
    self = [super init];
    if (self) {
        self.state = kNew;
        self.image = [UIImage imageNamed:@"Placeholder"];
        
        self.name = name;
        self.url = url;
    }
    
    return self;
}

@end


@implementation PendingOperations

@synthesize downloadsInProgress = _downloadsInProgress;
@synthesize downloadQueue = _downloadQueue;

@synthesize filtrationsInProgress = _filtrationsInProgress;
@synthesize filtrationQueue = _filtrationQueue;

#pragma mark -
#pragma mark Initializations and Deallocations

- (id)init {
    self = [super init];
    if (self) {
        self.downloadsInProgress = [NSMutableDictionary dictionary];
        
        NSOperationQueue *downloadQueue = [[NSOperationQueue alloc] init];
        [downloadQueue setName:@"Download queue"];
        [downloadQueue setMaxConcurrentOperationCount:1];
        self.downloadQueue = downloadQueue;
        
        self.filtrationsInProgress = [NSMutableDictionary dictionary];
        
        NSOperationQueue *filtrationQueue = [[NSOperationQueue alloc] init];
        [filtrationQueue setName:@"Image Filtration queue"];
        [filtrationQueue setMaxConcurrentOperationCount:1];
        self.filtrationQueue = filtrationQueue;
    }
    
    return self;
}

@end


@implementation ImageDownloader

@synthesize photoRecord = _photoRecord;

#pragma mark -
#pragma mark Initializations and Deallocations

- (id)initWithPhotoRecord:(PhotoRecord *)photoRecord {
    self = [super init];
    if (self) {
        self.photoRecord = photoRecord;
    }
    
    return self;
}

#pragma mark -
#pragma mark NSOperation overriden

- (void)main {
    if (self.isCancelled) {
        return;
    }
    
    NSData *imageData = [NSData dataWithContentsOfURL:self.photoRecord.url];
    
    if (self.isCancelled) {
        return;
    }
    
    if (imageData.length > 0) {
        self.photoRecord.image = [UIImage imageWithData:imageData];
        self.photoRecord.state = kDownloaded;
    } else {
        self.photoRecord.image = [UIImage imageNamed:@"Failed"];
        self.photoRecord.state = kFailed;
    }
}

@end


@interface ImageFiltration ()

- (UIImage *)applySepiaFilterForImage:(UIImage *)image;

@end

@implementation ImageFiltration

@synthesize photoRecord = _photoRecord;

#pragma mark -
#pragma mark Initializations and Deallocations

- (id)initWithPhotoRecord:(PhotoRecord *)photoRecord {
    self = [super init];
    if (self) {
        self.photoRecord = photoRecord;
    }
    
    return self;
}

#pragma mark -
#pragma mark NSOperation overriden

- (void)main {
    if (self.isCancelled) {
        return;
    }
    
    if (self.photoRecord.state != kDownloaded) {
        return;
    }
    
//    UIImage *filteredImage = [self applySepiaFilterForImage:self.photoRecord.image];
//    if (filteredImage) {
//        self.photoRecord.image = filteredImage;
//        self.photoRecord.state = kFiltered;
//    }
    
    self.photoRecord.state = kFiltered;
}

#pragma mark -
#pragma mark Private

- (UIImage *)applySepiaFilterForImage:(UIImage *)image {
    NSData *data = UIImagePNGRepresentation(image);
    if (!data) {
        return nil;
    }
    
    CIImage *inputImage = [CIImage imageWithData:data];
    
    if (self.isCancelled) {
        return nil;
    }

    CIContext *context = [CIContext contextWithOptions:nil];
    CIFilter *filter = [CIFilter filterWithName:kCICategoryColorEffect];
    if (!filter) {
        return nil;
    }
    
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:0.8] forKey:kCIInputBackgroundImageKey];
    
    if (self.isCancelled) {
        return nil;
    }
    
    CIImage *outputImage = filter.outputImage;
    if (!outputImage) {
        return nil;
    }
    
    CGImageRef outImage = [context createCGImage:outputImage fromRect:outputImage.extent];
    if (!outImage) {
        return nil;
    }
    
    return [UIImage imageWithCGImage:outImage];
}

@end

