//
//  QuadraticBezierCurve.h
//  Curve
//
//  Created by Bryan Spitz on 10-01-26.
//  Copyright 2010 Bryan Spitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BezierCurve.h"

@interface QuadraticBezierCurve : BezierCurve {
	CGPoint ctrl;
}

+(QuadraticBezierCurve *)quadraticCurveWithStartPoint:(CGPoint)start controlPoint:(CGPoint)control endPoint:(CGPoint)end;
-(id)initWithStartPoint:(CGPoint)start controlPoint:(CGPoint)control endPoint:(CGPoint)end;

@end
