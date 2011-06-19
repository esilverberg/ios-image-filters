//
//  LinearBezierCurve.h
//  Curve
//
//  Created by Bryan Spitz on 10-01-26.
//  Copyright 2010 Bryan Spitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BezierCurve.h"

@interface LinearBezierCurve : BezierCurve {
}

+(LinearBezierCurve *)linearCurveWithStartPoint:(CGPoint)start endPoint:(CGPoint)end;
-(id)initWithStartPoint:(CGPoint)start endPoint:(CGPoint)end;

@end
