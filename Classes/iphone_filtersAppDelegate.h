//
//  iphone_filtersAppDelegate.h
//  iphone-filters
//
//  Created by Eric Silverberg on 6/16/11.
//  Copyright 2011 Perry Street Software, Inc. 
//
//  Licensed under the MIT License.
//

#import <UIKit/UIKit.h>

@class iphone_filtersViewController;

@interface iphone_filtersAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    iphone_filtersViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet iphone_filtersViewController *viewController;

@end

