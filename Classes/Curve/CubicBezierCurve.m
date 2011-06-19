//
//  CubicBezierCurve.m
//  Curve
//
//  Created by Bryan Spitz on 10-01-28.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CubicBezierCurve.h"
#import "CGPointArithmetic.h"


@implementation CubicBezierCurve

+(CubicBezierCurve *)cubicCurveWithStart:(CGPoint)start controlPoint1:(CGPoint)control1 controlPoint2:(CGPoint)control2 end:(CGPoint)end {
	return [[[CubicBezierCurve alloc] initWithStart:start
									  controlPoint1:control1
									  controlPoint2:control2 
												end:end] autorelease];
}

-(id)initWithStart:(CGPoint)start controlPoint1:(CGPoint)control1 controlPoint2:(CGPoint)control2 end:(CGPoint)end {
	if (self = [super init]) {
		p1 = start;
		p2 = end;
		ctrl1 = control1;
		ctrl2 = control2;
	}
	
	return self;
}

-(BOOL)isNearLinear {
	
	if (CGPointEqualToPoint(p1, p2)) {
		return YES;
	}
	
	CGPoint p1Ctrl1 = CGPointDifference(ctrl1, p1);
	CGPoint p1p2 = CGPointDifference(p2, p1);
	
	CGFloat p1p2length = CGPointMagnitude(p1p2);
	CGFloat projectionLength = (p1Ctrl1.x * p1p2.x + p1Ctrl1.y * p1p2.y) / (p1p2length * p1p2length);
	
	CGPoint projectedPt = CGPointScale(p1p2, projectionLength);
	
	CGPoint diff = CGPointDifference(p1Ctrl1, projectedPt);
	CGFloat distance = CGPointMagnitude(diff);
	
	CGPoint p2Ctrl2 = CGPointDifference(ctrl2, p2);	
	projectionLength = (p2Ctrl2.x * -p1p2.x + p2Ctrl2.y * -p1p2.y) / (p1p2length * p1p2length);
	projectedPt = CGPointScale(p1p2, -projectionLength);
	diff = CGPointDifference(p2Ctrl2, projectedPt);
	CGFloat distance2 = CGPointMagnitude(diff);

	return distance < 0.5 && distance2 < 0.5;
	
}

-(NSArray *)subdivided {
	CGPoint midStartCtrl1 = CGPointMidpoint(p1, ctrl1);
	CGPoint midCtrl1Ctrl2 = CGPointMidpoint(ctrl1, ctrl2);
	CGPoint midCtrl2End = CGPointMidpoint(ctrl2, p2);
	CGPoint newCtrl1 = CGPointMidpoint(midStartCtrl1, midCtrl1Ctrl2);
	CGPoint newCtrl2 = CGPointMidpoint(midCtrl1Ctrl2, midCtrl2End);
	CGPoint mid = CGPointMidpoint(newCtrl1, newCtrl2);
	
	CubicBezierCurve *curve1 = [[CubicBezierCurve alloc] initWithStart:p1
														 controlPoint1:midStartCtrl1
														 controlPoint2:newCtrl1 
																   end:mid];
	CubicBezierCurve *curve2 = [[CubicBezierCurve alloc] initWithStart:mid 
														 controlPoint1:newCtrl2 
														 controlPoint2:midCtrl2End 
																   end:p2];
								
	NSArray *result = [NSArray arrayWithObjects:curve1, curve2, nil];
	
	[curve1 release];
	[curve2 release];
	
	return result;
}

-(NSArray *)asPointArray {
	/*
	if (pointArray != nil) {
		return pointArray;
	}
	*/
	if ([self isNearLinear]) {
		return [NSArray arrayWithObjects:[NSValue valueWithCGPoint:p1], [NSValue valueWithCGPoint:p2], nil];
	} else {
		NSArray *div = [self subdivided];
		NSMutableArray *pointArray = [[NSMutableArray alloc] initWithArray:[[div objectAtIndex:0] asPointArray]];
		[pointArray autorelease];
		[pointArray removeLastObject];
		[pointArray addObjectsFromArray:[[div objectAtIndex:1] asPointArray]];
		
		return pointArray;
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


-(void)dealloc {
	//[pointArray release];
	[super dealloc];
}

@end
