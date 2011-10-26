//
//  iphone_filtersViewController.m
//  iphone-filters
//
//  Created by Eric Silverberg on 6/16/11.
//  Copyright 2011 Perry Street Software, Inc. 
//
//  Licensed under the MIT License.
//

#import "iphone_filtersViewController.h"
#import "ImageFilter.h"

@implementation iphone_filtersViewController

@synthesize buttonAdjustable;
@synthesize buttonPackaged;
@synthesize imageView;
@synthesize slider;
@synthesize actionSheetAdjustable;
@synthesize actionSheetPackaged;

- (void) dealloc
{
	[buttonAdjustable release];
	[buttonPackaged release];
	[imageView release];
	[slider release];
	[actionSheetAdjustable release];
	[actionSheetPackaged release];
	[super dealloc];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self.buttonAdjustable addTarget:self action:@selector(buttonAdjustableClicked:) forControlEvents:UIControlEventTouchUpInside];
	[self.buttonPackaged addTarget:self action:@selector(buttonPackagedClicked:) forControlEvents:UIControlEventTouchUpInside];
	[self.slider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventTouchUpInside];
	[self.imageView setImage:[UIImage imageNamed:@"landscape.jpg"]];
}

- (IBAction) buttonAdjustableClicked:(id)sender
{
	// open a dialog with two custom buttons
	self.actionSheetAdjustable = [[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Set Filter",@"")
																delegate:self 
													   cancelButtonTitle:NSLocalizedString(@"Cancel",@"") 
												  destructiveButtonTitle:nil
													   otherButtonTitles:
									 NSLocalizedString(@"Posterize",@""), 
									 NSLocalizedString(@"Saturate",@""),
									 NSLocalizedString(@"Brightness",@""),
									 NSLocalizedString(@"Contrast",@""),
								     NSLocalizedString(@"Gamma",@""),
								     NSLocalizedString(@"Noise",@""),                                   
									 nil] autorelease];
	self.actionSheetAdjustable.actionSheetStyle = UIActionSheetStyleDefault;
	[self.actionSheetAdjustable showInView:self.view]; // show from our table view (pops up in the middle of the table)
}

- (IBAction) buttonPackagedClicked:(id)sender
{
	// open a dialog with two custom buttons
	self.actionSheetPackaged = 
		[[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Apply Filter",@"")
									delegate:self 
									cancelButtonTitle:NSLocalizedString(@"Cancel",@"") 
									destructiveButtonTitle:NSLocalizedString(@"Reset",@"") 
									otherButtonTitles:
									NSLocalizedString(@"Sharpen",@""), 
									NSLocalizedString(@"Sepia",@""),
									NSLocalizedString(@"Lomo",@""),
									NSLocalizedString(@"Vignette",@""),
									NSLocalizedString(@"Polaroidish",@""),
									NSLocalizedString(@"Invert",@""),
									nil] autorelease];
	self.actionSheetPackaged.actionSheetStyle = UIActionSheetStyleDefault;
	[self.actionSheetPackaged showInView:self.view]; // show from our table view (pops up in the middle of the table)	

}

- (IBAction) sliderMoved:(id)sender
{

	UIImage *image = [UIImage imageNamed:@"landscape.jpg"];
	
	double value = self.slider.value;
	switch (activeFilter) {
		case FilterPosterize:
			self.imageView.image = [image posterize:(int)(value*10)];
			break;
		case FilterSaturate:
			self.imageView.image = [image saturate:(1+value-0.5)];			
			break;
		case FilterBrightness:
			self.imageView.image = [image brightness:(1+value-0.5)];			
			break;
		case FilterContrast:
			self.imageView.image = [image contrast:(1+value-0.5)];			
			break;
		case FilterGamma:
			self.imageView.image = [image gamma:(1+value-0.5)];			
			break;
		case FilterNoise:
			self.imageView.image = [image noise:value];
			break;            
		default:
			break;
	}
}
#pragma mark -
#pragma mark Action Sheet

typedef enum 
{
	ActionSheetPackagedOptionReset = 0,
	ActionSheetPackagedOptionSharpen,
	ActionSheetPackagedOptionSepia,
	ActionSheetPackagedOptionLomo,
	ActionSheetPackagedOptionVignette,
	ActionSheetPackagedOptionPolaroidish,
    ActionSheetPackagedOptionInvert,
	ActionSheetPackagedOptionTotal
} ActionSheetPackagedOptions;

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (actionSheet == self.actionSheetAdjustable) {
		self.actionSheetAdjustable = nil;
		
		activeFilter = buttonIndex;
		self.slider.value = 0.5;
	} else if (actionSheet == self.actionSheetPackaged) {
		self.actionSheetPackaged = nil;
		UIImage *image = [UIImage imageNamed:@"landscape.jpg"];

		switch (buttonIndex) {
			case ActionSheetPackagedOptionReset:
				self.imageView.image = image;
				break;
			case ActionSheetPackagedOptionSharpen:
				self.imageView.image = [image sharpen];
				break;
			case ActionSheetPackagedOptionSepia:
				self.imageView.image = [image sepia];
				break;
			case ActionSheetPackagedOptionLomo:
				self.imageView.image = [image lomo];
				break;
			case ActionSheetPackagedOptionVignette:
				self.imageView.image = [image vignette];
				break;
			case ActionSheetPackagedOptionPolaroidish:
				self.imageView.image = [image polaroidish];
				break;
			case ActionSheetPackagedOptionInvert:
				self.imageView.image = [image invert];
				break;                
			default:
				break;
		}
	}
}

@end
