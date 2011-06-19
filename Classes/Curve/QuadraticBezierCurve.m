//
//  QuadraticBezierCurve.m
//  Curve
//
//  Created by Bryan Spitz on 10-01-26.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "QuadraticBezierCurve.h"
#import "CGPointArithmetic.h"
#import <math.h>


@implementation QuadraticBezierCurve

+(QuadraticBezierCurve *)quadraticCurveWithStartPoint:(CGPoint)start controlPoint:(CGPoint)control endPoint:(CGPoint)end {
	return [[[QuadraticBezierCurve alloc] initWithStartPoint:start controlPoint:control endPoint:end] autorelease];
}

-(id)initWithStartPoint:(CGPoint)start controlPoint:(CGPoint)control endPoint:(CGPoint)end {
	if (self = [super init]) {
		p1 = start;
		p2 = end;
		ctrl = control;
	}
	
	return self;
}

-(BOOL)isNearLinear {
	
	if (CGPointEqualToPoint(p1, p2) || CGPointEqualToPoint(p1, ctrl) || CGPointEqualToPoint(ctrl, p2)) {
		return YES;
	}
	
	CGPoint p1Ctrl = CGPointDifference(ctrl, p1);
	CGPoint p1p2 = CGPointDifference(p2, p1);
	
	CGFloat p1p2length = CGPointMagnitude(p1p2);
	CGFloat projectionLength = (p1Ctrl.x * p1p2.x + p1Ctrl.y * p1p2.y) / (p1p2length * p1p2length);
	
	CGPoint projectedPt = CGPointScale(p1p2, projectionLength);
	
	CGPoint diff = CGPointDifference(p1Ctrl, projectedPt);
	CGFloat distance = CGPointMagnitude(diff);
	
	return distance < 0.5;
	
}

-(NSArray *)subdivided {
	CGPoint ctrl1 = CGPointMidpoint(p1, ctrl);
	CGPoint ctrl2 = CGPointMidpoint(p2, ctrl);
	CGPoint mid = CGPointMidpoint(ctrl1, ctrl2);
	
	QuadraticBezierCurve *curve1 = [[QuadraticBezierCurve alloc] initWithStartPoint:p1 controlPoint:ctrl1 endPoint:mid];
	QuadraticBezierCurve *curve2 = [[QuadraticBezierCurve alloc] initWithStartPoint:mid controlPoint:ctrl2 endPoint:p2];
	
	NSArray *result = [NSArray arrayWithObjects:curve1, curve2, nil];
	
	[curve1 release];
	[curve2 release];
	
	return result;
}

-(NSArray *)asPointArray {
	if ([self isNearLinear]) {
		return [NSArray arrayWithObjects:[NSValue valueWithCGPoint:p1], [NSValue valueWithCGPoint:p2], nil];
	} else {
		NSArray *div = [self subdivided];
		NSMutableArray *result = [NSMutableArray arrayWithArray:[[div objectAtIndex:0] asPointArray]];
		[result removeLastObject];
		[result addObjectsFromArray:[[div objectAtIndex:1] asPointArray]];
		
		return result;
	}

}

-(void)addToPointArray:(NSMutableArray *)pointArray {
	if ([self isNearLinear]) {
		[pointArray addObject:[NSValue valueWithCGPoint:p1]];
	} else {
		NSArray *div = [self subdivided];
		[[div objectAtIndex:0] addToPointArray:pointArray];
		[[div objectAtIndex:1] addToPointArray:pointArray];
	}

}

@end
