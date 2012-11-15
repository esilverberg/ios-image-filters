//
//  ImageFilter.m
//  iphone-filters
//
//  Created by Eric Silverberg on 6/16/11.
//  Copyright 2011 Perry Street Software, Inc. 
//
//  Licensed under the MIT License.
//
//  Some filters in the file are licensed under the ImageMagick License (the "License"); you may not use
//  this file except in compliance with the License.  You may obtain a copy
//  of the License at
// 
//  http://www.imagemagick.org/script/license.php
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations
//  under the License.
//
//  Original ImageMagick filters source code is found at:
//  http://www.google.com/codesearch#I0cABDTB4TA/pub/FreeBSD/ports/distfiles/ImageMagick-6.3.2-0.tar.bz2%7Cqy9T8VaIuJE/ImageMagick-6.3.2/magick/effect.c
//

#include <math.h>
#import "ImageFilter.h"
#import "CatmullRomSpline.h"

/* These constants are used by ImageMagick */
typedef unsigned char Quantum;
typedef double MagickRealType;

#define RoundToQuantum(quantum)  ClampToQuantum(quantum)
#define ScaleCharToQuantum(value)  ((Quantum) (value))
#define SigmaGaussian  ScaleCharToQuantum(4)
#define TauGaussian  ScaleCharToQuantum(20)
#define QuantumRange  ((Quantum) 65535)

/* These are our own constants */
#define SAFECOLOR(color) MIN(255,MAX(0,color))

typedef void (*FilterCallback)(UInt8 *pixelBuf, UInt32 offset, void *context);
typedef void (*FilterBlendCallback)(UInt8 *pixelBuf, UInt8 *pixelBlendBuf, UInt32 offset, void *context);

@implementation UIImage (ImageFilter)

#pragma mark -
#pragma mark Basic Filters
#pragma mark Internals
- (UIImage*) applyFilter:(FilterCallback)filter context:(void*)context
{
	CGImageRef inImage = self.CGImage;
    size_t width = CGImageGetWidth(inImage);
    size_t height = CGImageGetHeight(inImage);
    size_t bits = CGImageGetBitsPerComponent(inImage);
    size_t bitsPerRow = CGImageGetBytesPerRow(inImage);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(inImage);
    int alphaInfo = CGImageGetAlphaInfo(inImage);
    
    if (alphaInfo != kCGImageAlphaPremultipliedLast &&
        alphaInfo != kCGImageAlphaNoneSkipLast) {
        if (alphaInfo == kCGImageAlphaNone ||
            alphaInfo == kCGImageAlphaNoneSkipFirst) {
            alphaInfo = kCGImageAlphaNoneSkipLast;
        }else {
            alphaInfo = kCGImageAlphaPremultipliedLast;
        }
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     width,
                                                     height,
                                                     bits,
                                                     bitsPerRow,
                                                     colorSpace,
                                                     alphaInfo);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), inImage);
        inImage = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
    }else {
        CGImageRetain(inImage);
    }
    
	CFDataRef m_DataRef = CGDataProviderCopyData(CGImageGetDataProvider(inImage));  
	int length = CFDataGetLength(m_DataRef);
	CFMutableDataRef m_DataRefEdit = CFDataCreateMutableCopy(NULL,length,m_DataRef);
	CFRelease(m_DataRef);
    UInt8 * m_PixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_DataRefEdit);

	for (int i=0; i<length; i+=4)
	{
		filter(m_PixelBuf,i,context);
	}
    CGImageRelease(inImage);
	
	CGContextRef ctx = CGBitmapContextCreate(m_PixelBuf,  
											 width,
											 height,
											 bits,
											 bitsPerRow,
											 colorSpace,
											 alphaInfo
											 ); 
	
	CGImageRef imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef
                                              scale:self.scale
                                        orientation:self.imageOrientation];
	CGImageRelease(imageRef);
    CFRelease(m_DataRefEdit);
	return finalImage;
	
}

#pragma mark C Implementation
void filterGreyscale(UInt8 *pixelBuf, UInt32 offset, void *context)
{	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	uint32_t gray = 0.3 * red + 0.59 * green + 0.11 * blue;
	
	pixelBuf[r] = gray;
	pixelBuf[g] = gray;  
	pixelBuf[b] = gray;  
}

void filterSepia(UInt8 *pixelBuf, UInt32 offset, void *context)
{	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR((red * 0.393) + (green * 0.769) + (blue * 0.189));
	pixelBuf[g] = SAFECOLOR((red * 0.349) + (green * 0.686) + (blue * 0.168));
	pixelBuf[b] = SAFECOLOR((red * 0.272) + (green * 0.534) + (blue * 0.131));
}

void filterPosterize(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	int levels = *((int*)context);
	if (levels == 0) levels = 1; // avoid divide by zero
	int step = 255 / levels;
	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR((red / step) * step);
	pixelBuf[g] = SAFECOLOR((green / step) * step);
	pixelBuf[b] = SAFECOLOR((blue / step) * step);
}


void filterSaturate(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	double t = *((double*)context);
	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	int avg = ( red + green + blue ) / 3;
	
	pixelBuf[r] = SAFECOLOR((avg + t * (red - avg)));
	pixelBuf[g] = SAFECOLOR((avg + t * (green - avg)));
	pixelBuf[b] = SAFECOLOR((avg + t * (blue - avg)));	
}

void filterBrightness(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	double t = *((double*)context);
	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR(red*t);
	pixelBuf[g] = SAFECOLOR(green*t);
	pixelBuf[b] = SAFECOLOR(blue*t);
}

void filterGamma(UInt8 *pixelBuf, UInt32 offset, void *context)
{	
	double amount = *((double*)context);
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR(pow(red,amount));
	pixelBuf[g] = SAFECOLOR(pow(green,amount));
	pixelBuf[b] = SAFECOLOR(pow(blue,amount));
}

void filterOpacity(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	double val = *((double*)context);
	
	int a = offset+3;
	
	int alpha = pixelBuf[a];
	
	pixelBuf[a] = SAFECOLOR(alpha * val);
}

double calcContrast(double f, double c){
	return (f-0.5) * c + 0.5;
}

void filterContrast(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	double val = *((double*)context);
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR(255 * calcContrast((double)((double)red / 255.0f), val));
	pixelBuf[g] = SAFECOLOR(255 * calcContrast((double)((double)green / 255.0f), val));
	pixelBuf[b] = SAFECOLOR(255 * calcContrast((double)((double)blue / 255.0f), val));
}

double calcBias(double f, double bi){
	return (double) (f / ((1.0 / bi - 1.9) * (0.9 - f) + 1));
}

void filterBias(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	double val = *((double*)context);
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR((red * calcBias(((double)red / 255.0f), val)));
	pixelBuf[g] = SAFECOLOR((green * calcBias(((double)green / 255.0f), val)));
	pixelBuf[b] = SAFECOLOR((blue * calcBias(((double)blue / 255.0f), val)));
}

void filterInvert(UInt8 *pixelBuf, UInt32 offset, void *context)
{	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR(255-red);
	pixelBuf[g] = SAFECOLOR(255-green);
	pixelBuf[b] = SAFECOLOR(255-blue);
}

//
// Noise filter was adapted from ImageMagick
//
static inline Quantum ClampToQuantum(const MagickRealType value)
{
	if (value <= 0.0)
		return((Quantum) 0);
	if (value >= (MagickRealType) QuantumRange)
		return((Quantum) QuantumRange);
	return((Quantum) (value+0.5));
}

static inline double RandBetweenZeroAndOne() 
{
	double value = arc4random() % 1000000;
	value = value / 1000000;
	return value;
}	

static inline Quantum GenerateGaussianNoise(double alpha, const Quantum pixel)
{	
	double beta = RandBetweenZeroAndOne();
	double sigma = sqrt(-2.0*log((double) alpha))*cos((double) (2.0*M_PI*beta));
	double tau = sqrt(-2.0*log((double) alpha))*sin((double) (2.0*M_PI*beta));
	double noise = (MagickRealType) pixel+sqrt((double) pixel)*SigmaGaussian*sigma+TauGaussian*tau;

	return RoundToQuantum(noise);
}	

void filterNoise(UInt8 *pixelBuf, UInt32 offset, void *context)
{	
	double alpha = 1.0 - *((double*)context);
       
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	   	
	pixelBuf[r] = GenerateGaussianNoise(alpha, red);
	pixelBuf[g] = GenerateGaussianNoise(alpha, green);
	pixelBuf[b] = GenerateGaussianNoise(alpha, blue);
}

#pragma mark Filters
-(UIImage*)greyscale 
{
	return [self applyFilter:filterGreyscale context:nil];
}

- (UIImage*)sepia
{
	return [self applyFilter:filterSepia context:nil];
}

- (UIImage*)posterize:(int)levels
{
	return [self applyFilter:filterPosterize context:&levels];
}

- (UIImage*)saturate:(double)amount
{
	return [self applyFilter:filterSaturate context:&amount];
}

- (UIImage*)brightness:(double)amount
{
	return [self applyFilter:filterBrightness context:&amount];
}

- (UIImage*)gamma:(double)amount
{
	return [self applyFilter:filterGamma context:&amount];	
}

- (UIImage*)opacity:(double)amount
{
	return [self applyFilter:filterOpacity context:&amount];	
}

- (UIImage*)contrast:(double)amount
{
	return [self applyFilter:filterContrast context:&amount];
}

- (UIImage*)bias:(double)amount
{
	return [self applyFilter:filterBias context:&amount];	
}

- (UIImage*)invert
{
	return [self applyFilter:filterInvert context:nil];
}

- (UIImage*)noise:(double)amount
{
	return [self applyFilter:filterNoise context:&amount];
}

#pragma mark -
#pragma mark Blends
#pragma mark Internals
- (UIImage*) applyBlendFilter:(FilterBlendCallback)filter other:(UIImage*)other context:(void*)context
{
	CGImageRef inImage = self.CGImage;
    
    
    size_t width = CGImageGetWidth(inImage);
    size_t height = CGImageGetHeight(inImage);
    size_t bits = CGImageGetBitsPerComponent(inImage);
    size_t bitsPerRow = CGImageGetBytesPerRow(inImage);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(inImage);
    int alphaInfo = CGImageGetAlphaInfo(inImage);
    
    if (alphaInfo != kCGImageAlphaPremultipliedLast ||
        alphaInfo != kCGImageAlphaNoneSkipLast) {
        if (alphaInfo == kCGImageAlphaNone ||
            alphaInfo == kCGImageAlphaNoneSkipFirst) {
            alphaInfo = kCGImageAlphaNoneSkipLast;
        }else {
            alphaInfo = kCGImageAlphaPremultipliedLast;
        }
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     width,
                                                     height,
                                                     bits,
                                                     bitsPerRow,
                                                     colorSpace,
                                                     alphaInfo);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), inImage);
        inImage = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
    }else {
        CGImageRetain(inImage);
    }
    
	CFDataRef m_DataRef = CGDataProviderCopyData(CGImageGetDataProvider(inImage));  
	int length = CFDataGetLength(m_DataRef);
	CFMutableDataRef m_DataRefEdit = CFDataCreateMutableCopy(NULL,length,m_DataRef);
    CFRelease(m_DataRef);
    UInt8 * m_PixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_DataRefEdit);
	
	CGImageRef otherImage = other.CGImage;
	CFDataRef m_OtherDataRef = CGDataProviderCopyData(CGImageGetDataProvider(otherImage));  
	int otherLength = CFDataGetLength(m_OtherDataRef);
	CFMutableDataRef m_OtherDataRefEdit = CFDataCreateMutableCopy(NULL,otherLength,m_OtherDataRef);
	CFRelease(m_OtherDataRef);
	UInt8 * m_OtherPixelBuf = (UInt8 *) CFDataGetBytePtr(m_OtherDataRef);  	
	
	int h = self.size.height;
	int w = self.size.width;
	
	
	for (int i=0; i<h; i++)
	{
		for (int j = 0; j < w; j++)
		{
			int index = (i*w*4) + (j*4);
			filter(m_PixelBuf,m_OtherPixelBuf,index,context);			
		}
	}
    
    CGImageRelease(inImage);
	
	CGContextRef ctx = CGBitmapContextCreate(m_PixelBuf,
											 width,
											 height,
											 bits,
											 bitsPerRow,
											 colorSpace,
											 alphaInfo
											 );
	
	CGImageRef imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
    CFRelease(m_DataRefEdit);
	CFRelease(m_OtherDataRefEdit);
	return finalImage;
	
}
#pragma mark C Implementation
double calcOverlay(float b, float t) {
	return (b > 128.0f) ? 255.0f - 2.0f * (255.0f - t) * (255.0f - b) / 255.0f: (b * t * 2.0f) / 255.0f;
}

void filterOverlay(UInt8 *pixelBuf, UInt8 *pixedBlendBuf, UInt32 offset, void *context)
{	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	int a = offset+3;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	int blendRed = pixedBlendBuf[r];
	int blendGreen = pixedBlendBuf[g];
	int blendBlue = pixedBlendBuf[b];
	double blendAlpha = pixedBlendBuf[a] / 255.0f;
	
	// http://en.wikipedia.org/wiki/Alpha_compositing
	//	double blendAlpha = pixedBlendBuf[a] / 255.0f;
	//	double blendRed = pixedBlendBuf[r] * blendAlpha + red * (1-blendAlpha);
	//	double blendGreen = pixedBlendBuf[g] * blendAlpha + green * (1-blendAlpha);
	//	double blendBlue = pixedBlendBuf[b] * blendAlpha + blue * (1-blendAlpha);
	
	int resultR = SAFECOLOR(calcOverlay(red, blendRed));
	int resultG = SAFECOLOR(calcOverlay(green, blendGreen));
	int resultB = SAFECOLOR(calcOverlay(blue, blendBlue));
	
	// take this result, and blend it back again using the alpha of the top guy	
	pixelBuf[r] = SAFECOLOR(resultR * blendAlpha + red * (1 - blendAlpha));
	pixelBuf[g] = SAFECOLOR(resultG * blendAlpha + green * (1 - blendAlpha));
	pixelBuf[b] = SAFECOLOR(resultB * blendAlpha + blue * (1 - blendAlpha));
	
}

void filterMask(UInt8 *pixelBuf, UInt8 *pixedBlendBuf, UInt32 offset, void *context)
{	
	int r = offset;
//	int g = offset+1;
//	int b = offset+2;
	int a = offset+3;

	// take this result, and blend it back again using the alpha of the top guy	
	pixelBuf[a] = pixedBlendBuf[r];
}

void filterMerge(UInt8 *pixelBuf, UInt8 *pixedBlendBuf, UInt32 offset, void *context)
{	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	int a = offset+3;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	int blendRed = pixedBlendBuf[r];
	int blendGreen = pixedBlendBuf[g];
	int blendBlue = pixedBlendBuf[b];
	double blendAlpha = pixedBlendBuf[a] / 255.0f;
			
	// take this result, and blend it back again using the alpha of the top guy	
	pixelBuf[r] = SAFECOLOR(blendRed * blendAlpha + red * (1 - blendAlpha));
	pixelBuf[g] = SAFECOLOR(blendGreen * blendAlpha + green * (1 - blendAlpha));
	pixelBuf[b] = SAFECOLOR(blendBlue * blendAlpha + blue * (1 - blendAlpha));	
}

#pragma mark Filters
- (UIImage*) overlay:(UIImage*)other;
{
	return [self applyBlendFilter:filterOverlay other:other context:nil];
}

- (UIImage*) mask:(UIImage*)other;
{
	return [self applyBlendFilter:filterMask other:other context:nil];
}

- (UIImage*) merge:(UIImage*)other;
{
	return [self applyBlendFilter:filterMerge other:other context:nil];
}


#pragma mark -
#pragma mark Color Correction
#pragma mark C Implementation
typedef struct
{
	int blackPoint;
	int whitePoint;
	int midPoint;
} LevelsOptions;

int calcLevelColor(int color, int black, int mid, int white)
{
	if (color < black) {
		return 0;
	} else if (color < mid) {
		int width = (mid - black);
		double stepSize = ((double)width / 128.0f);
		return (int)((double)(color - black) / stepSize);		
	} else if (color < white) {
		int width = (white - mid);
		double stepSize = ((double)width / 128.0f);
		return 128 + (int)((double)(color - mid) / stepSize);		
	}
	
	return 255;
}
void filterLevels(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	LevelsOptions val = *((LevelsOptions*)context);
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR(calcLevelColor(red, val.blackPoint, val.midPoint, val.whitePoint));
	pixelBuf[g] = SAFECOLOR(calcLevelColor(green, val.blackPoint, val.midPoint, val.whitePoint));
	pixelBuf[b] = SAFECOLOR(calcLevelColor(blue, val.blackPoint, val.midPoint, val.whitePoint));
}

typedef struct
{
	CurveChannel channel;
	CGPoint *points;
	int length;
} CurveEquation;

double valueGivenCurve(CurveEquation equation, double xValue)
{
	assert(xValue <= 255);
	assert(xValue >= 0);
	
	CGPoint point1 = CGPointZero;
	CGPoint point2 = CGPointZero;
	NSInteger idx = 0;
	
	for (idx = 0; idx < equation.length; idx++)
	{
		CGPoint point = equation.points[idx];
		if (xValue < point.x)
		{
			point2 = point;
			if (idx - 1 >= 0)
			{
				point1 = equation.points[idx-1];
			}
			else
			{
				point1 = point2;
			}
			
			break;
		}		
	}
	
	double m = (point2.y - point1.y)/(point2.x - point1.x);
	double b = point2.y - (m * point2.x);
	double y = m * xValue + b;
	return y;
}

void filterCurve(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	CurveEquation equation = *((CurveEquation*)context);
	
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	red = equation.channel & CurveChannelRed ? valueGivenCurve(equation, red) : red;
	green = equation.channel & CurveChannelGreen ? valueGivenCurve(equation, green) : green;
	blue = equation.channel & CurveChannelBlue ? valueGivenCurve(equation, blue) : blue;
	
	pixelBuf[r] = SAFECOLOR(red);
	pixelBuf[g] = SAFECOLOR(green);
	pixelBuf[b] = SAFECOLOR(blue);
}
typedef struct 
{
	double r;
	double g;
	double b;
} RGBAdjust;


void filterAdjust(UInt8 *pixelBuf, UInt32 offset, void *context)
{
	RGBAdjust val = *((RGBAdjust*)context);
	int r = offset;
	int g = offset+1;
	int b = offset+2;
	
	int red = pixelBuf[r];
	int green = pixelBuf[g];
	int blue = pixelBuf[b];
	
	pixelBuf[r] = SAFECOLOR(red * (1 + val.r));
	pixelBuf[g] = SAFECOLOR(green * (1 + val.g));
	pixelBuf[b] = SAFECOLOR(blue * (1 + val.b));
}

#pragma mark Filters
/*
 * Levels: Similar to levels in photoshop. 
 * todo: Specify per-channel
 *
 * Parameters:
 *   black: 0-255
 *   mid: 0-255
 *   white: 0-255
 */
- (UIImage*) levels:(NSInteger)black mid:(NSInteger)mid white:(NSInteger)white
{
	LevelsOptions l;
	l.midPoint = mid;
	l.whitePoint = white;
	l.blackPoint = black;
	
	return [self applyFilter:filterLevels context:&l];
}

/*
 * Levels: Similar to curves in photoshop. 
 * todo: Use a Bicubic spline not a catmull rom spline
 *
 * Parameters:
 *   points: An NSArray of CGPoints through which the curve runs
 *   toChannel: A bitmask of the channels to which the curve gets applied
 */
- (UIImage*) applyCurve:(NSArray*)points toChannel:(CurveChannel)channel
{
	assert([points count] > 1);
	
	CGPoint firstPoint = ((NSValue*)[points objectAtIndex:0]).CGPointValue;
	CatmullRomSpline *spline = [CatmullRomSpline catmullRomSplineAtPoint:firstPoint];	
	NSInteger idx = 0;
	NSInteger length = [points count];
	for (idx = 1; idx < length; idx++)
	{
		CGPoint point = ((NSValue*)[points objectAtIndex:idx]).CGPointValue;
		[spline addPoint:point];
		NSLog(@"Adding point %@",NSStringFromCGPoint(point));
	}		
	
	NSArray *splinePoints = [spline asPointArray];		
	length = [splinePoints count];
	CGPoint *cgPoints = malloc(sizeof(CGPoint) * length);
	memset(cgPoints, 0, sizeof(CGPoint) * length);
	for (idx = 0; idx < length; idx++)
	{
		CGPoint point = ((NSValue*)[splinePoints objectAtIndex:idx]).CGPointValue;
		NSLog(@"Adding point %@",NSStringFromCGPoint(point));
		cgPoints[idx].x = point.x;
		cgPoints[idx].y = point.y;
	}
	
	CurveEquation equation;
	equation.length = length;
	equation.points = cgPoints;	
	equation.channel = channel;
	UIImage *result = [self applyFilter:filterCurve context:&equation];	
	free(cgPoints);
	return result;
}


/*
 * adjust: Similar to color balance
 *
 * Parameters:
 *   r: Multiplier of r. Make < 0 to reduce red, > 0 to increase red
 *   g: Multiplier of g. Make < 0 to reduce green, > 0 to increase green
 *   b: Multiplier of b. Make < 0 to reduce blue, > 0 to increase blue
 */
- (UIImage*)adjust:(double)r g:(double)g b:(double)b
{
	RGBAdjust adjust;
	adjust.r = r;
	adjust.g = g;
	adjust.b = b;
	
	return [self applyFilter:filterAdjust context:&adjust];	
}

#pragma mark -
#pragma mark Convolve Operations
#pragma mark Internals
- (UIImage*) applyConvolve:(NSArray*)kernel
{
	CGImageRef inImage = self.CGImage;
	CFDataRef m_DataRef = CGDataProviderCopyData(CGImageGetDataProvider(inImage));  
	CFDataRef m_OutDataRef = CGDataProviderCopyData(CGImageGetDataProvider(inImage));  

	int length = CFDataGetLength(m_DataRef);
	CFMutableDataRef m_DataRefEdit = CFDataCreateMutableCopy(NULL,length,m_DataRef);
	CFRelease(m_DataRef);
    UInt8 * m_PixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_DataRefEdit);

    int outputLength = CFDataGetLength(m_OutDataRef);
	CFMutableDataRef m_OutDataRefEdit = CFDataCreateMutableCopy(NULL,outputLength,m_DataRef);
    CFRelease(m_OutDataRef);
    UInt8 * m_OutPixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_OutDataRefEdit);
	
	int h = CGImageGetHeight(inImage);
	int w = CGImageGetWidth(inImage);
	
	int kh = [kernel count] / 2;
	int kw = [[kernel objectAtIndex:0] count] / 2;
	int i = 0, j = 0, n = 0, m = 0;
	
	for (i = 0; i < h; i++) {
		for (j = 0; j < w; j++) {
			int outIndex = (i*w*4) + (j*4);
			double r = 0, g = 0, b = 0;
			for (n = -kh; n <= kh; n++) {
				for (m = -kw; m <= kw; m++) {
					if (i + n >= 0 && i + n < h) {
						if (j + m >= 0 && j + m < w) {
							double f = [[[kernel objectAtIndex:(n + kh)] objectAtIndex:(m + kw)] doubleValue];
							if (f == 0) {continue;}
							int inIndex = ((i+n)*w*4) + ((j+m)*4);
							r += m_PixelBuf[inIndex] * f;
							g += m_PixelBuf[inIndex + 1] * f;
							b += m_PixelBuf[inIndex + 2] * f;
						}
					}
				}
			}
			m_OutPixelBuf[outIndex]     = SAFECOLOR((int)r);
			m_OutPixelBuf[outIndex + 1] = SAFECOLOR((int)g);
			m_OutPixelBuf[outIndex + 2] = SAFECOLOR((int)b);
			m_OutPixelBuf[outIndex + 3] = 255;
		}
	}
	
	CGContextRef ctx = CGBitmapContextCreate(m_OutPixelBuf,  
											 CGImageGetWidth(inImage),  
											 CGImageGetHeight(inImage),  
											 CGImageGetBitsPerComponent(inImage),
											 CGImageGetBytesPerRow(inImage),  
											 CGImageGetColorSpace(inImage),  
											 CGImageGetBitmapInfo(inImage) 
											 ); 
	
	CGImageRef imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
    CFRelease(m_DataRefEdit);
    CFRelease(m_OutDataRefEdit);
	return finalImage;
	
}
#pragma mark Filters
- (UIImage*) sharpen
{
	double dKernel[5][5]={ 
		{0, 0.0, -0.2,  0.0, 0},
		{0, -0.2, 1.8, -0.2, 0},
		{0, 0.0, -0.2,  0.0, 0}};
		
	NSMutableArray *kernel = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
	for (int i = 0; i < 5; i++) {
		NSMutableArray *row = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
		for (int j = 0; j < 5; j++) {
			[row addObject:[NSNumber numberWithDouble:dKernel[i][j]]];
		}
		[kernel addObject:row];
	}
	return [self applyConvolve:kernel];
}

- (UIImage*) edgeDetect
{
	double dKernel[5][5]={ 
		{0, 0.0, 1.0,  0.0, 0},
		{0, 1.0, -4.0, 1.0, 0},
		{0, 0.0, 1.0,  0.0, 0}};
	
	NSMutableArray *kernel = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
	for (int i = 0; i < 5; i++) {
		NSMutableArray *row = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
		for (int j = 0; j < 5; j++) {
			[row addObject:[NSNumber numberWithDouble:dKernel[i][j]]];
		}
		[kernel addObject:row];
	}
	return [self applyConvolve:kernel];
}

+ (NSArray*) makeKernel:(int)length
{
	NSMutableArray *kernel = [[[NSMutableArray alloc] initWithCapacity:10] autorelease];
	int radius = length / 2;
	
	double m = 1.0f/(2*M_PI*radius*radius);
	double a = 2.0 * radius * radius;
	double sum = 0.0;
	
	for (int y = 0-radius; y < length-radius; y++)
	{
		NSMutableArray *row = [[[NSMutableArray alloc] initWithCapacity:10] autorelease];
        for (int x = 0-radius; x < length-radius; x++)
        {
			double dist = (x*x) + (y*y);
			double val = m*exp(-(dist / a));
			[row addObject:[NSNumber numberWithDouble:val]];			
			sum += val;
        }
		[kernel addObject:row];
	}
	
	//for Kernel-Sum of 1.0
	NSMutableArray *finalKernel = [[[NSMutableArray alloc] initWithCapacity:length] autorelease];
	for (int y = 0; y < length; y++)
	{
		NSMutableArray *row = [kernel objectAtIndex:y];
		NSMutableArray *newRow = [[[NSMutableArray alloc] initWithCapacity:length] autorelease];
        for (int x = 0; x < length; x++)
        {
			NSNumber *value = [row objectAtIndex:x];
			[newRow addObject:[NSNumber numberWithDouble:([value doubleValue] / sum)]];
        }
		[finalKernel addObject:newRow];
	}
	return finalKernel;
}

- (UIImage*) gaussianBlur:(NSUInteger)radius
{
	// Pre-calculated kernel
//	double dKernel[5][5]={ 
//		{1.0f/273.0f, 4.0f/273.0f, 7.0f/273.0f, 4.0f/273.0f, 1.0f/273.0f},
//		{4.0f/273.0f, 16.0f/273.0f, 26.0f/273.0f, 16.0f/273.0f, 4.0f/273.0f},
//		{7.0f/273.0f, 26.0f/273.0f, 41.0f/273.0f, 26.0f/273.0f, 7.0f/273.0f},
//		{4.0f/273.0f, 16.0f/273.0f, 26.0f/273.0f, 16.0f/273.0f, 4.0f/273.0f},             
//		{1.0f/273.0f, 4.0f/273.0f, 7.0f/273.0f, 4.0f/273.0f, 1.0f/273.0f}};
//	
//	NSMutableArray *kernel = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
//	for (int i = 0; i < 5; i++) {
//		NSMutableArray *row = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
//		for (int j = 0; j < 5; j++) {
//			[row addObject:[NSNumber numberWithDouble:dKernel[i][j]]];
//		}
//		[kernel addObject:row];
//	}
	return [self applyConvolve:[UIImage makeKernel:((radius*2)+1)]];
}

#pragma mark -
#pragma mark Pre-packaged
- (UIImage*)lomo
{
	UIImage *image = [[self saturate:1.2] contrast:1.15];
	NSArray *redPoints = [NSArray arrayWithObjects:
					   [NSValue valueWithCGPoint:CGPointMake(0, 0)],
					   [NSValue valueWithCGPoint:CGPointMake(137, 118)],
					   [NSValue valueWithCGPoint:CGPointMake(255, 255)],
						  [NSValue valueWithCGPoint:CGPointMake(255, 255)],
					   nil];
	NSArray *greenPoints = [NSArray arrayWithObjects:
						  [NSValue valueWithCGPoint:CGPointMake(0, 0)],
						  [NSValue valueWithCGPoint:CGPointMake(64, 54)],
						  [NSValue valueWithCGPoint:CGPointMake(175, 194)],
						  [NSValue valueWithCGPoint:CGPointMake(255, 255)],
						  nil];
	NSArray *bluePoints = [NSArray arrayWithObjects:
						  [NSValue valueWithCGPoint:CGPointMake(0, 0)],
						  [NSValue valueWithCGPoint:CGPointMake(59, 64)],
						   [NSValue valueWithCGPoint:CGPointMake(203, 189)],
						  [NSValue valueWithCGPoint:CGPointMake(255, 255)],
						  nil];
	image = [[[image applyCurve:redPoints toChannel:CurveChannelRed] 
			  applyCurve:greenPoints toChannel:CurveChannelGreen]
				applyCurve:bluePoints toChannel:CurveChannelBlue];
	
	return [image darkVignette];
}

- (UIImage*) vignette
{
	CGImageRef inImage = self.CGImage;
	CFDataRef m_DataRef = CGDataProviderCopyData(CGImageGetDataProvider(inImage));  
	int length = CFDataGetLength(m_DataRef);
	CFMutableDataRef m_DataRefEdit = CFDataCreateMutableCopy(NULL,length,m_DataRef);
	CFRelease(m_DataRef);
    UInt8 * m_PixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_DataRefEdit);
	memset(m_PixelBuf,0,length);
	
	CGContextRef ctx = CGBitmapContextCreate(m_PixelBuf,  
											 CGImageGetWidth(inImage),  
											 CGImageGetHeight(inImage),  
											 CGImageGetBitsPerComponent(inImage),
											 CGImageGetBytesPerRow(inImage),  
											 CGImageGetColorSpace(inImage),  
											 CGImageGetBitmapInfo(inImage) 
											 ); 
	
	
	int borderWidth = 0.10 * self.size.width;
	CGContextSetRGBFillColor(ctx, 0,0,0,1);
	CGContextFillRect(ctx, CGRectMake(0, 0, self.size.width, self.size.height));
	CGContextSetRGBFillColor(ctx, 1.0,1.0,1.0,1);
	CGContextFillEllipseInRect(ctx, CGRectMake(borderWidth, borderWidth, 
									  self.size.width-(2*borderWidth), 
									  self.size.height-(2*borderWidth)));
	
	CGImageRef imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
    CFRelease(m_DataRefEdit);
    
	UIImage *mask = [finalImage gaussianBlur:10];
	UIImage *blurredSelf = [self gaussianBlur:2];
	UIImage *maskedSelf = [self mask:mask];
	return [blurredSelf merge:maskedSelf];
}

- (UIImage*) darkVignette
{
	CGImageRef inImage = self.CGImage;
	CFDataRef m_DataRef = CGDataProviderCopyData(CGImageGetDataProvider(inImage));  
	int length = CFDataGetLength(m_DataRef);
	CFMutableDataRef m_DataRefEdit = CFDataCreateMutableCopy(NULL,length,m_DataRef);
	CFRelease(m_DataRef);	
    UInt8 * m_PixelBuf = (UInt8 *) CFDataGetMutableBytePtr(m_DataRefEdit);
	memset(m_PixelBuf,0,length);
	
	CGContextRef ctx = CGBitmapContextCreate(m_PixelBuf,  
											 CGImageGetWidth(inImage),  
											 CGImageGetHeight(inImage),  
											 CGImageGetBitsPerComponent(inImage),
											 CGImageGetBytesPerRow(inImage),  
											 CGImageGetColorSpace(inImage),  
											 CGImageGetBitmapInfo(inImage) 
											 ); 
	
	
	int borderWidth = 0.05 * self.size.width;
	CGContextSetRGBFillColor(ctx, 1.0,1.0,1.0,1);
	CGContextFillRect(ctx, CGRectMake(0, 0, self.size.width, self.size.height));
	CGContextSetRGBFillColor(ctx, 0,0,0,1);
	CGContextFillRect(ctx, CGRectMake(borderWidth, borderWidth, 
											   self.size.width-(2*borderWidth), 
											   self.size.height-(2*borderWidth)));
	
	CGImageRef imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);	
	
	UIImage *mask = [finalImage gaussianBlur:10];

	
	ctx = CGBitmapContextCreate(m_PixelBuf,  
											 CGImageGetWidth(inImage),  
											 CGImageGetHeight(inImage),  
											 CGImageGetBitsPerComponent(inImage),
											 CGImageGetBytesPerRow(inImage),  
											 CGImageGetColorSpace(inImage),  
											 CGImageGetBitmapInfo(inImage) 
											 ); 
	CGContextSetRGBFillColor(ctx, 0,0,0,1);
	CGContextFillRect(ctx, CGRectMake(0, 0, self.size.width, self.size.height));
	imageRef = CGBitmapContextCreateImage(ctx);  
	CGContextRelease(ctx);
	UIImage *blackSquare = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);	
    CFRelease(m_DataRefEdit);
	UIImage *maskedSquare = [blackSquare mask:mask];
	return [self overlay:[maskedSquare opacity:1.0]];
}

// This filter is not done...
- (UIImage*) polaroidish
{
	NSArray *redPoints = [NSArray arrayWithObjects:
					   [NSValue valueWithCGPoint:CGPointMake(0, 0)],
					   [NSValue valueWithCGPoint:CGPointMake(93, 81)],
					   [NSValue valueWithCGPoint:CGPointMake(247, 241)],
						  [NSValue valueWithCGPoint:CGPointMake(255, 255)],
					   nil];
	NSArray *bluePoints = [NSArray arrayWithObjects:
						  [NSValue valueWithCGPoint:CGPointMake(0, 0)],
						  [NSValue valueWithCGPoint:CGPointMake(57, 59)],
						  [NSValue valueWithCGPoint:CGPointMake(223, 205)],
						  [NSValue valueWithCGPoint:CGPointMake(255, 241)],
						  nil];
	UIImage *image = [[self applyCurve:redPoints toChannel:CurveChannelRed] 
			  applyCurve:bluePoints toChannel:CurveChannelBlue];

	redPoints = [NSArray arrayWithObjects:
						  [NSValue valueWithCGPoint:CGPointMake(0, 0)],
						  [NSValue valueWithCGPoint:CGPointMake(93, 76)],
						  [NSValue valueWithCGPoint:CGPointMake(232, 226)],
						  [NSValue valueWithCGPoint:CGPointMake(255, 255)],
						  nil];
	bluePoints = [NSArray arrayWithObjects:
						   [NSValue valueWithCGPoint:CGPointMake(0, 0)],
						   [NSValue valueWithCGPoint:CGPointMake(57, 59)],
						   [NSValue valueWithCGPoint:CGPointMake(220, 202)],
						   [NSValue valueWithCGPoint:CGPointMake(255, 255)],
						   nil];
	image = [[image applyCurve:redPoints toChannel:CurveChannelRed] 
			 applyCurve:bluePoints toChannel:CurveChannelBlue];
	
	return image;
}
@end
