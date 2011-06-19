//
//  CubicBezierCurve.h
//  Curve
//
//  Created by Bryan Spitz on 10-01-28.
//  Copyright 2010 Bryan Spitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BezierCurve.h"

@interface CubicBezierCurve : BezierCurve {
	CGPoint ctrl1, ctrl2;
}

+(CubicBezierCurve *)cubicCurveWithStart:(CGPoint)start controlPoint1:(CGPoint)control1 controlPoint2:(CGPoint)control2 end:(CGPoint)end;
-(id)initWithStart:(CGPoint)start controlPoint1:(CGPoint)control1 controlPoint2:(CGPoint)control2 end:(CGPoint)end;

@end
