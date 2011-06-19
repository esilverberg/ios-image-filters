//
//  Spline.m
//  Curve
//
//  Created by Bryan Spitz on 10-01-23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Spline.h"
#import "CubicBezierCurve.h"
#import "QuadraticBezierCurve.h"
#import "LinearBezierCurve.h"

@implementation Spline

+(Spline *)splineAtPoint:(CGPoint)start {
	return [[[Spline alloc] initAtPoint:start] autorelease];
}

-(id)initAtPoint:(CGPoint)start {
	if (self = [super init]) {
		current = start;
		begin = start;
		curves = [[NSMutableArray alloc] initWithCapacity:20];
	}
	return self;
}


-(void)addCubicCurveWithControl1:(CGPoint)ctrl1 control2:(CGPoint)ctrl2 toPoint:(CGPoint)end {
	CubicBezierCurve *cubic = [[CubicBezierCurve alloc] initWithStart:current
														controlPoint1:ctrl1
														controlPoint2:ctrl2
																  end:end];
	
	[curves addObject:cubic];
	[cubic release];
	current = end;
}

-(void)addQuadCurveWithControl:(CGPoint)ctrl toPoint:(CGPoint)end {
	QuadraticBezierCurve *quad = [[QuadraticBezierCurve alloc] initWithStartPoint:current
																	 controlPoint:ctrl
																		 endPoint:end];
	
	[curves addObject:quad];
	[quad release];
	current = end;
}

-(void)addLinearCurveToPoint:(CGPoint)end {
	LinearBezierCurve *linear = [[LinearBezierCurve alloc] initWithStartPoint:current endPoint:end];
	[curves addObject:linear];
	[linear release];
	current = end;
}


-(void)removeLastCurve {
	[curves removeLastObject];
}

-(NSArray *)asPointArray {
	if ([curves count] == 0) {
		return [NSArray arrayWithObject:[NSValue valueWithCGPoint:begin]];
	}
	
	
	NSMutableArray *pointArray = [NSMutableArray arrayWithCapacity:[curves count] * 3];
	
	for (NSInteger i = 0; i < [curves count]; i++) {
		[[curves objectAtIndex:i] addToPointArray:pointArray];
		/*
		[pointArray addObjectsFromArray:[[curves objectAtIndex:i] asPointArray]];
		if (i < [curves count] - 1) {
			[pointArray removeLastObject];
		}
		 */
	}
	[pointArray addObject:[NSValue valueWithCGPoint:[[curves lastObject] p2]]];
	
	return pointArray;
}

-(void)dealloc {
	[curves release];
	[super dealloc];
}
@end
