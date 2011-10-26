//
//  iphone_filtersViewController.h
//  iphone-filters
//
//  Created by Eric Silverberg on 6/16/11.
//  Copyright 2011 Perry Street Software, Inc. 
//
//  Licensed under the MIT License.
//

#import <UIKit/UIKit.h>

typedef enum
{
	FilterPosterize = 0,
	FilterSaturate,
	FilterBrightness,
	FilterContrast,
	FilterGamma,
    FilterNoise,
    FilterInvert,
	FilterTotal
} FilterOptions;

@interface iphone_filtersViewController : UIViewController <UIActionSheetDelegate> {
	UIImageView *imageView;
	UIButton *buttonAdjustable;
	UIButton *buttonPackaged;
	UISlider *slider;
	UIActionSheet *actionSheetAdjustable;
	UIActionSheet *actionSheetPackaged;
	FilterOptions activeFilter;
	
}

@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIButton *buttonAdjustable;
@property (nonatomic, retain) IBOutlet UIButton *buttonPackaged;
@property (nonatomic, retain) IBOutlet UISlider *slider;
@property (nonatomic, retain) UIActionSheet *actionSheetAdjustable;
@property (nonatomic, retain) UIActionSheet *actionSheetPackaged;

@end

