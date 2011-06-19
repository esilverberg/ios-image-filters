//
//  CatmullRomSpline.h
//  Curve
//	
//	CatmullRomSpline is a class representing a Catmull-Rom Spline (i.e. a spline with
//	continuous derivative, passing through a set of arbitrary control points). The tangent
//	of the spline at any control point (except the first and last) is parallel to the 
//	line connecting the previous control point with the next one.
//
//	Most of the segments of a CatmullRomSpline are cubic bezier curves. The last segment is
//	a quadratic curve. When a new point is added, the last segment is removed and replaced with a
//	cubic curve making use of the new control point information, and a new quadratic curve is
//  added to the end. Application that attempt to cache data related to the spline should be
//	aware that the final points are subject to change.
//
//  Created by Bryan Spitz on 10-01-28.
//  Copyright 2010 Bryan Spitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Spline.h"

@interface CatmullRomSpline : Spline {
	CGPoint p3, p2, p1, p;
}

+(CatmullRomSpline *)catmullRomSplineAtPoint:(CGPoint)start;

// Add a control point, through which the spline must pass, to the end of the spline.
-(void)addPoint:(CGPoint)point;

@end
