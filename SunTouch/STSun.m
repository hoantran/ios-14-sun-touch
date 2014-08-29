//
//  STSun.m
//  SunTouch
//
//  Created by James Bucanek on 1/23/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import "STSun.h"
#import "STGameDefs.h"


static CGFloat RandomLocation( void );

@implementation STSun

+ (STSun*)randomSun
{
	// Create a sun at a random location
	STSun* sun = [[STSun alloc] init];
	sun.location = CGPointMake(RandomLocation(),RandomLocation());
    return sun;
}

+ (STSun*)sunAt:(CGFloat)x :(CGFloat)y
{
	// Create a new sun at a specific location
	STSun* sun = [[STSun alloc] init];
	sun.location = CGPointMake(x,y);
    return sun;
}

- (BOOL)captured
{
	// Implied property: a sun has been struck (by anyone) when it's
	//	assigned a capture time
	return (_time!=0.0);
}

@end

#pragma mark -

#define kRandomScale		10000
#define kSunLocationRange	(kSunLocationMax-kSunLocationMin)

static CGFloat RandomLocation()
{
	// Return a random, floating point, value between kSunLocationMin and kSunLocationMax, inclusive
	return (CGFloat)arc4random_uniform((uint32_t)(kSunLocationRange*kRandomScale)+1)
					/(CGFloat)kRandomScale+kSunLocationMin;
}
