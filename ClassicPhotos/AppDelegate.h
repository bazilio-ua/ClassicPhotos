//
//  AppDelegate.h
//  ClassicPhotos
//
//  Created by Basil Nikityuk on 6/30/18.
//  Copyright (c) 2018 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ListViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ListViewController *listViewController;

@end
