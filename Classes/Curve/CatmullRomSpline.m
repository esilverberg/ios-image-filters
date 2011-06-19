//
//  CatmullRomSpline.m
//  Curve
//
//  Created by Bryan Spitz on 10-01-28.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CatmullRomSpline.h"
#import "CGPointArithmetic.h"


@implementation CatmullRomSpline


+(CatmullRomSpline *)catmullRomSplineAtPoint:(CGPoint)start {
	return [[[CatmullRomSpline alloc] initAtPoint:start] autorelease];
}
 

-(id)initAtPoint:(CGPoint)start {
	if (self = [super initAtPoint:start]) {
		p = start;
		p1 = start;
		p2 = start;
		p3 = start;
	}
	
	return self;
}

-(void)addPoint:(CGPoint)point {
	CGPoint diff = CGPointMake(point.x - p.x, point.y - p.y);
	double length = sqrt(pow(diff.x, 2) + pow(diff.y, 2));
	
	
	
	if ([curves count] > 0) {
		[self removeLastCurve];
	}
	 
	 
	if (length >= 15) {
		p3 = p2;
		p2 = p1;
		p1 = p;
		p = point;
		
		CGPoint tangent = CGPointMake((p1.x - p3.x), (p1.y - p3.y));
		CGFloat tangentLength = CGPointMagnitude(tangent);
		CGPoint unitTangent = (tangentLength == 0.)?tangent:CGPointScale(tangent, 1. / tangentLength);
		CGPoint diff = CGPointDifference (p1, p2);
		CGFloat desiredLength = CGPointMagnitude(diff) / 3.;
		CGPoint desiredTangent = CGPointScale(unitTangent, desiredLength);

		CGPoint ctrl1 = CGPointMake(p2.x + desiredTangent.x, p2.y + desiredTangent.y);
		
		tangent = CGPointMake((p.x - p2.x), (p.y - p2.y));
		tangentLength = CGPointMagnitude(tangent);
		unitTangent = (tangentLength == 0.)?tangent:CGPointScale(tangent, 1. / tangentLength);
		desiredTangent = CGPointScale(unitTangent, desiredLength);
		
		CGPoint ctrl2 = CGPointMake(p1.x - desiredTangent.x, p1.y - desiredTangent.y);
		
		[self addCubicCurveWithControl1:ctrl1 control2:ctrl2 toPoint:p1];

		
	}
	
	CGPoint currtemp = current;
	CGPoint tangent2 = CGPointMake((p.x - p2.x)/5., (p.y - p2.y)/5.);
	CGPoint ctrl = CGPointMake(p1.x + tangent2.x, p1.y + tangent2.y);
	[self addQuadCurveWithControl:ctrl toPoint:point];
	current = currtemp;
	 
	
}
@end
