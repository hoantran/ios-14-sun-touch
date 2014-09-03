//
//  STSun.h
//  SunTouch
//
//  Created by James Bucanek on 1/23/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import <Foundation/Foundation.h>


// A single sun object.
// Coordidnates are in logical (0.0-1.0) game-space coordinates.
// When captured, the game time of the event is set.

@interface STSun : NSObject

+ (STSun*)randomSun;
+ (STSun*)sunAt:(CGFloat)x :(CGFloat)y;

@property CGPoint			location;		// location (unit coordinates)
@property (readonly) BOOL	captured;		// sun has been captured
@property NSTimeInterval	time;			// game time of capture
@property BOOL				localPlayer;	// the local player captured this sun

@property (readonly,nonatomic) NSUInteger score;

@end
