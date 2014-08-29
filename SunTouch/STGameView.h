//
//  STGameView.h
//  SunTouch
//
//  Created by James Bucanek on 1/23/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STGame;
@class STGameViewController;

// STGameView is the game's view object.
// It maintains and draws the state of the game view and uses subviews to
//	animate strikes and sun captures.
// Almost all of this information is received from notifications
//	posted by the game and game view controller objects.


@interface STGameView : UIView

@property (readonly,nonatomic) UIImage *strikeImage;

- (void)reset;
- (void)observeNotificationsFromGame:(STGame*)game;

- (CGPoint)unitPointFromPoint:(CGPoint)viewPoint;
- (CGPoint)pointFromUnitPoint:(CGPoint)unitPoint;
- (CGFloat)unitRadiusFromRadius:(CGFloat)viewRadius;
- (CGFloat)radiusFromUnitRadius:(CGFloat)unitRadius;

@end
