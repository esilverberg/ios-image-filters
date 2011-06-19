//
//  BezierCurve.m
//  Curve
//
//  Created by Bryan Spitz on 10-01-26.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BezierCurve.h"


@implementation BezierCurve
@synthesize p1, p2;

- (NSArray *)subdivided {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (BOOL)isNearLinear {
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (NSArray *)asPointArray {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (void)addToPointArray:(NSMutableArray *)pointArray {
	[self doesNotRecognizeSelector:_cmd];
}

@end
