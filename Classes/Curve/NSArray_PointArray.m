//
//  NSArray_PointArray.m
//  Curve
//
//  Created by Bryan Spitz on 10-01-27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSArray_PointArray.h"
#import "CGPointArithmetic.h"
#import <math.h>

@implementation NSArray(PointArray)

-(PointArrayLocation)locationAtDistance:(CGFloat)d {
	if (d < 0) {
		@throw [NSException exceptionWithName:@"PointNotFoundException" reason:@"Point is before start of curve" userInfo:nil];
	}
	
	PointArrayLocation result;
	
	for (NSInteger i = 1; i < [self count]; i++) {
		CGPoint current = [[self objectAtIndex:i] CGPointValue];
		CGPoint last = [[self objectAtIndex:i-1] CGPointValue];	
		
		CGPoint diff = CGPointDifference(current, last);
		CGFloat distance = CGPointMagnitude(diff);
		
		if (d >= distance) {
			d -= distance;
		} else {
			CGPoint unit = CGPointScale(diff, 1/distance);
			CGPoint scaled = CGPointScale(unit, d);
			result.location = CGPointAdd(last, scaled);
			result.angle = atan2(unit.y, unit.x);
			return result;
		}

	}
	
	result.location = [[self lastObject] CGPointValue];
	if ([self count] < 2) {
		result.angle = 0;
	} else {
		CGPoint current = [[self objectAtIndex:[self count] - 1] CGPointValue];
		CGPoint last = [[self objectAtIndex:[self count] - 2] CGPointValue];	
		
		CGPoint diff = CGPointDifference(current, last);
		result.angle = atan2(diff.y, diff.x);
	}

	return result;
	//@throw [NSException exceptionWithName:@"PointNotFoundException" reason:@"Point is beyond end of curve" userInfo:nil];
}

-(CGFloat)length {
	CGFloat result = 0;
	
	for (NSInteger i = 1; i < [self count]; i++) {
		CGPoint current = [[self objectAtIndex:i] CGPointValue];
		CGPoint last = [[self objectAtIndex:i-1] CGPointValue];	
		
		CGPoint diff = CGPointDifference(current, last);
		CGFloat distance = CGPointMagnitude(diff);
		
		result += distance;
	}
	
	return result;
}

-(PointArrayBounds)pointArrayBoundsFromDistance:(CGFloat)from to:(CGFloat)to {
	PointArrayBounds result;
	
	if (from < 0) {
		@throw [NSException exceptionWithName:@"PointNotFoundException" reason:@"Point is before start of curve" userInfo:nil];
	}
	
	CGFloat *source = &from;
	CGPoint *target = &(result.start);
	NSInteger *targetIndex = &(result.startIndex);
	BOOL foundStart = NO;
	
	CGPoint current;
	CGPoint last;
	for (NSInteger i = 1; i < [self count]; i++) {
		last = [[self objectAtIndex:i - 1] CGPointValue];
		current = [[self objectAtIndex:i] CGPointValue];
		
		CGPoint diff = CGPointDifference(current, last);
		CGFloat distance = CGPointMagnitude(diff);
		
		if (*source >= distance) {
			from -= distance;
			to -=distance;
		} else {
			CGPoint unit = CGPointScale(diff, 1/distance);
			CGPoint scaled = CGPointScale(unit, *source);
			*target = CGPointAdd(last, scaled);
			*targetIndex = i;
			if (!foundStart) {
				foundStart = YES;
				i--;
				source = &to;
				target = &(result.end);
				targetIndex = &(result.endIndex);
			} else {
				return result;
			}

		}
		
	}
	
	if (!foundStart) {
		result.start = [[self lastObject] CGPointValue];
		result.startIndex = [self count];
	}
	result.end = [[self lastObject] CGPointValue];
	result.endIndex = [self count];
	
	return result;
	
}

@end
