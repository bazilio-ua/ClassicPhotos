//
//  ListViewController.m
//  ClassicPhotos
//
//  Created by Basil Nikityuk on 6/30/18.
//  Copyright (c) 2018 __MyCompanyName__. All rights reserved.
//

#import "ListViewController.h"

static NSString *const dataSourceURLString = @"http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist";

@interface ListViewController ()

- (void)fetchPhotoDetails;

- (void)suspendAllOperations;
- (void)resumeAllOperations;

- (void)loadImagesForOnscreenCells;
- (void)startOperationsForPhotoRecord:(PhotoRecord *)photoRecord atIndexPath:(NSIndexPath *)indexPath;

- (void)startDownloadForPhotoRecord:(PhotoRecord *)photoRecord atIndexPath:(NSIndexPath *)indexPath;
- (void)startFiltrationForPhotoRecord:(PhotoRecord *)photoRecord atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation ListViewController

@synthesize photos = _photos;
@synthesize pendingOperations = _pendingOperations;

#pragma mark -
#pragma mark Initializations and Deallocations

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.title = @"Classic Photos";
        
        self.photos = [NSMutableArray array];
        self.pendingOperations = [PendingOperations new];
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - 
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Classic Photos";
    
    self.photos = [NSMutableArray array];
    self.pendingOperations = [PendingOperations new];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self fetchPhotoDetails];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - 
#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.photos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    if (cell.accessoryView == nil) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        cell.accessoryView = indicator;
    }
    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)cell.accessoryView;
    
    PhotoRecord *photoRecord = [self.photos objectAtIndex:indexPath.row];
    
    cell.textLabel.text = photoRecord.name;
    cell.imageView.image = photoRecord.image;
    
    switch (photoRecord.state) {
        case kFiltered:
            [indicator stopAnimating];
            break;
        case kFailed:
            [indicator stopAnimating];
            cell.textLabel.text = @"Failed to load";
            break;
        case kNew:
        case kDownloaded:
            [indicator startAnimating];
            if (!tableView.isDragging && !tableView.isDecelerating) {
                [self startOperationsForPhotoRecord:photoRecord atIndexPath:indexPath];
            }
            break;
            
        default:
            break;
    }
    
    return cell;
}

#pragma mark - 
#pragma mark Private

- (void)fetchPhotoDetails {
    NSURL *dataSourceURL = [NSURL URLWithString:dataSourceURLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:dataSourceURL];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (data && !error) {
            NSError *error2;
            NSPropertyListFormat plistFormat;
            NSDictionary *dataSourceDictionary = [NSPropertyListSerialization propertyListWithData:data 
                                                                                           options:NSPropertyListImmutable 
                                                                                            format:&plistFormat 
                                                                                             error:&error2];
            if (dataSourceDictionary && !error2) {
                [dataSourceDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
                    NSURL *url = [NSURL URLWithString:value];
                    PhotoRecord *photoRecord = [[PhotoRecord alloc] initWithName:key url:url];
                    
                    [self.photos addObject:photoRecord];
                }];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            } else if (error2) {
                // present alert
                NSLog(@"error: %@", error2.localizedDescription);
            }
            
        } else if (error) {
            // present alert
            NSLog(@"error: %@", error.localizedDescription);
        }
    }];
}


#pragma mark - 
#pragma mark Operation management

- (void)suspendAllOperations {
    [self.pendingOperations.downloadQueue setSuspended:YES];
    [self.pendingOperations.filtrationQueue setSuspended:YES];
}

- (void)resumeAllOperations {
    [self.pendingOperations.downloadQueue setSuspended:NO];
    [self.pendingOperations.filtrationQueue setSuspended:NO];
}

- (void)loadImagesForOnscreenCells {
    NSArray *indexPaths = [self.tableView indexPathsForVisibleRows];
    if (indexPaths) {
        NSSet *downloadsInProgress = [NSSet setWithArray:self.pendingOperations.downloadsInProgress.allKeys];
        NSSet *filtrationsInProgress = [NSSet setWithArray:self.pendingOperations.filtrationsInProgress.allKeys];
        NSMutableSet *allPendingOperations = [NSMutableSet set];
        [allPendingOperations unionSet:downloadsInProgress];
        [allPendingOperations unionSet:filtrationsInProgress];
        
        NSSet *visiblePaths = [NSSet setWithArray:indexPaths];
        NSMutableSet *toBeCancelled = [NSMutableSet setWithSet:allPendingOperations];
        [toBeCancelled minusSet:visiblePaths];
        
        NSMutableSet *toBeStarted = [NSMutableSet setWithSet:visiblePaths];
        [toBeStarted minusSet:allPendingOperations];
        
        for (NSIndexPath *indexPath in toBeCancelled) {
            NSOperation *pendingDownload = [self.pendingOperations.downloadsInProgress objectForKey:indexPath];
            [pendingDownload cancel];
            [self.pendingOperations.downloadsInProgress removeObjectForKey:indexPath];
            
            NSOperation *pendingFiltration = [self.pendingOperations.filtrationsInProgress objectForKey:indexPath];
            [pendingFiltration cancel];
            [self.pendingOperations.filtrationsInProgress removeObjectForKey:indexPath];
        }
        
        for (NSIndexPath *indexPath in toBeStarted) {
            PhotoRecord *recordToProcess = [self.photos objectAtIndex:indexPath.row];
            [self startOperationsForPhotoRecord:recordToProcess atIndexPath:indexPath];
        }
    }
}

- (void)startOperationsForPhotoRecord:(PhotoRecord *)photoRecord atIndexPath:(NSIndexPath *)indexPath {
    switch (photoRecord.state) {
        case kNew:
            [self startDownloadForPhotoRecord:photoRecord atIndexPath:indexPath];
            break;
        case kDownloaded:
            [self startFiltrationForPhotoRecord:photoRecord atIndexPath:indexPath];
            break;
            
        default:
            NSLog(@"do nothing");
            break;
    }
}

- (void)startDownloadForPhotoRecord:(PhotoRecord *)photoRecord atIndexPath:(NSIndexPath *)indexPath {
    if ([self.pendingOperations.downloadsInProgress objectForKey:indexPath]) {
        return;
    }
    
    ImageDownloader *downloader = [[ImageDownloader alloc] initWithPhotoRecord:photoRecord];
    ImageDownloader __weak *weakDownloader = downloader;
    downloader.completionBlock = ^{
        ImageDownloader __strong *downloader = weakDownloader;
        if (downloader.isCancelled) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.pendingOperations.downloadsInProgress removeObjectForKey:indexPath];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        });
    };
    
    [self.pendingOperations.downloadsInProgress setObject:downloader forKey:indexPath];
    [self.pendingOperations.downloadQueue addOperation:downloader];
}

- (void)startFiltrationForPhotoRecord:(PhotoRecord *)photoRecord atIndexPath:(NSIndexPath *)indexPath {
    if ([self.pendingOperations.filtrationsInProgress objectForKey:indexPath]) {
        return;
    }
    
    ImageFiltration *filterer = [[ImageFiltration alloc] initWithPhotoRecord:photoRecord];
    ImageFiltration __weak *weakFilterer = filterer;
    filterer.completionBlock = ^{
        ImageFiltration __strong *filterer = weakFilterer;
        if (filterer.isCancelled) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.pendingOperations.filtrationsInProgress removeObjectForKey:indexPath];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        });
    };
    
    [self.pendingOperations.filtrationsInProgress setObject:filterer forKey:indexPath];
    [self.pendingOperations.filtrationQueue addOperation:filterer];
}

#pragma mark -
#pragma mark <UIScrollViewDelegate>

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self suspendAllOperations];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self loadImagesForOnscreenCells];
        [self resumeAllOperations];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadImagesForOnscreenCells];
    [self resumeAllOperations];
}

#pragma mark -
#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
