//
//  STGameDefs.h
//  SunTouch
//
//  Created by James Bucanek on 1/24/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#ifndef SunTouch_STGameDefs_h
#define SunTouch_STGameDefs_h

//
// Global definitions and constants
//

#define kStrikeAnimationDuration	2.0		// time for strike animation cycle

#define kSunCount					8		// game is always to capture 8 suns

#define kSunDistanceMin				0.05	// two suns can't be closer than this
#define kSunLocationMin				0.03	// don't place suns closer then 3% of edge
#define kSunLocationMax				(1-kSunLocationMin)

#define kSunSpinAnimationDuration	0.5		// spin for 1/2 second
#define kSunSettleAnimationDuration	0.75	// take 3/4 of a second to put away
#define kSunSettleAlpha				0.6		// final alpha
#define kSunStrikeBeginRadius		4.0		// start animation with a size of 8x8
#define kSunStrikeMaxRadius			16.0	// peak with a size of 32x32
#define kSunStrikeEndRadius			12.0	// final size is 24x24

#define kWeightMax					100000	// score weight goes from 100,000 to
#define kWeightMin					100		//  100, logarithmically over a
#define kWeightToZeroTime			(2*60.0)//	2 minute period

#define kStrikePreviewMinRadius		6.0		// starting radius of the next strike
#define kStrikePreviewMaxUnit		0.25	// fraction of radius scale for max size
#define kStrikePreviewGrowDuration	20.0	// strike size grows for 20 seconds

//
// Game Kit
//

#define kSinglePlayerLeaderboardID	@"single"
#define kTwoPlayerLeaderboardID		@"multiple"

//
// Some platform independent defines
//

// These macros use the float or double library
//  function that matches the size of CGFloat so that
//  no float->double or double->float conversion occurs.
#if CGFLOAT_IS_DOUBLE
// Functions and constants to use if CGFloat is a double
#define STHypotenuse	hypot			// hypot(double,double)
#define STSquareRoot	sqrt			// sqrt(double)
#define STFloor			floor			// floor(double)
#else
// Functions and constants to use if CGFloat is a float
#define STHypotenuse	hypotf			// hypotf(float,float)
#define STSquareRoot	sqrtf			// sqrtf(float)
#define STFloor			floorf			// floorf(float)
#endif

// Some handy in-line functions for common calculations.

// Calculate the distance between two CGPoint structs
CF_INLINE CGFloat DistanceBetweenPoints( CGPoint a, CGPoint b)
{
	return STHypotenuse(a.x-b.x,a.y-b.y);
}

// Calculate the radius scale for a specific view size
CF_INLINE CGFloat RadiusScale( CGSize size )
{
	// The radius scale for a view is the average of the height & width
	return (size.width+size.height)/2;
}

// Make a bounding rect for a circle
CF_INLINE CGRect CircleRect( CGPoint point, CGFloat radius )
{
	return CGRectMake(point.x-radius,point.y-radius,radius*2,radius*2);
}

#endif
