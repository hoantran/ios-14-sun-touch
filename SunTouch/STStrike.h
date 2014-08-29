//
//  STStrike.h
//  SunTouch
//
//  Created by James Bucanek on 1/23/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import <Foundation/Foundation.h>

// Represents a single strike defined by a coordinate (x,y) and a radius (r).
// Coordinates and radius are in the logical (0.0-1.0) game space.

@interface STStrike : NSObject

@property (nonatomic) CGPoint location;		// unit space
@property (nonatomic) CGFloat radius;		// unit radius

@end
