/*
 *  CGPointArithmetic.h
 *  Curve
 *
 *	A set of tools for doing CGPoint calculations. For efficiency, these are preprocessor macros
 *  instead of C functions.
 *
 *  Created by Bryan Spitz on 10-01-26.
 *  Copyright 2010 Bryan Spitz. All rights reserved.
 *
 */

#import <math.h>

#define CGPointDifference(p1,p2)	(CGPointMake(((p1.x) - (p2.x)), ((p1.y) - (p2.y))))
#define CGPointMagnitude(p)			sqrt(p.x*p.x + p.y*p.y)
#define CGPointSlope(p)				(p.y / p.x)
#define CGPointScale(p, d)			CGPointMake(p.x * d, p.y * d)
#define CGPointAdd(p1, p2)			CGPointMake(p1.x + p2.x, p1.y + p2.y)
#define CGPointMidpoint(p1, p2)		CGPointMake((p1.x + p2.x)/2., (p1.y + p2.y)/2.)