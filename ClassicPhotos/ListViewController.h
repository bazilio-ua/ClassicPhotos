//
//  ListViewController.h
//  ClassicPhotos
//
//  Created by Basil Nikityuk on 6/30/18.
//  Copyright (c) 2018 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PhotoOperations.h"

@interface ListViewController : UITableViewController
@property (nonatomic, strong)   NSMutableArray      *photos;
@property (nonatomic, strong)   PendingOperations   *pendingOperations;

@end
