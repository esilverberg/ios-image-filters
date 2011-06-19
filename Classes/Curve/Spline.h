//
//  Spline.h
//  Curve
//
//	An Objective-C representation of a spline made of linear, quadratic, and cubic bezier curves.
//
//  Created by Bryan Spitz on 10-01-23.
//  Copyright 2010 Bryan Spitz. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface Spline : NSObject {
	NSMutableArray *curves;
	CGPoint begin;
	CGPoint current;
}

// Initialization methods - start a spline at a particular point.
+(Spline *)splineAtPoint:(CGPoint)start;
-(id)initAtPoint:(CGPoint)start;

// Add a linear bezier curve (i.e. a line segment) to the spline, starting at the previous endpoint.
-(void)addLinearCurveToPoint:(CGPoint)end;

// Add a cubic bezier curve to the spline, starting at the previous endpoint.
-(void)addCubicCurveWithControl1:(CGPoint)ctrl1 control2:(CGPoint)ctrl2 toPoint:(CGPoint)end;

// Add a quadratic bezier curve to the spline, starting at the previous endpoint.
-(void)addQuadCurveWithControl:(CGPoint)ctrl toPoint:(CGPoint)end;

// Pop the most recently-added curve off the end of the spline.
-(void)removeLastCurve;

// Return an array of NSValues representing CGPoints dividing the spline into near-linear segments.
-(NSArray *)asPointArray;
@end
