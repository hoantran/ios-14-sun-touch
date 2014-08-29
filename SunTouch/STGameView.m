//
//  STGameView.m
//  SunTouch
//
//  Created by James Bucanek on 1/23/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "STGameView.h"

#import "STGameDefs.h"
#import "STGameViewController.h"
#import "STGame.h"
#import "STStrike.h"
#import "STSun.h"


#pragma mark Private Constants

#define kBackgroundImageName	@"Starfield.jpg"
#define kStrikeImageName		@"Strike"


@interface STGameView () // private methods
{
	NSMutableArray		*strikes;				// STSun[]: strikes that have occurred
	NSMutableDictionary	*sunViews;				// UIImageView[]: sun capture views
	CGPoint				sunSettlePoint;
    BOOL                sunsShown;
}
- (CGPoint)nextSunSettlePoint;
- (void)strikeNotification:(NSNotification*)notification;
- (void)captureNotification:(NSNotification*)notification;
- (void)setStrikeDrawColor;
- (void)drawBackground;
@end


#pragma mark -
@implementation STGameView


//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        //
//    }
//    
//    NSLog(@"initWithFrame");
//    
//    return self;
//}


- (void)dealloc
{
    [self observeNotificationsFromGame:nil];	// remove all observers
}

- (void)reset
{
    NSLog(@"---- RESET ----");
    NSLog(sunsShown ? @"Yes" : @"No");
    
	// Clear/setup the strike and sun collections
	strikes = [NSMutableArray new];
	sunViews = [NSMutableDictionary new];
	// Reset the location of where the captured suns will settle
	// (set y so that next pre-increment will set it to the first position)
	CGRect bounds = self.bounds;
	sunSettlePoint = CGPointMake(CGRectGetMaxX(bounds)-(kSunStrikeEndRadius+2),
								 -kSunStrikeEndRadius);
    
    // clear sun-hint locations
    if (sunsShown) {
        [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        sunsShown = NO;
    }
}

- (void)observeNotificationsFromGame:(STGame*)game
{
    NSLog(@"observeNotificationsFromGame");
    NSLog(@"game: %p", game);
    
	// Begin observing notification from the given game object
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	// remove all previous observers
	[notificationCenter removeObserver:self];
	
	if (game!=nil)
		{
            [notificationCenter addObserver:self
                                   selector:@selector(strikeNotification:)
                                       name:kGameStrikeNotification
                                     object:game];
            [notificationCenter addObserver:self
                                   selector:@selector(captureNotification:)
                                       name:kGameSunCaptureNotification
                                     object:game];
            [notificationCenter     addObserver:self
                                       selector:@selector(showSunsNotification:)
                                           name:kGameShowSuns
                                         object:game];
            [notificationCenter     addObserver:self
                                       selector:@selector(hideSunsNotification:)
                                           name:kGameHideSuns
                                         object:game];
        }

}

#pragma mark Properties

- (UIImage*)strikeImage
{
	// Local player view returns the "hot" strike image
	return [UIImage imageNamed:kStrikeImageName];
}

- (CGFloat)radiusScale
{
	// The scale of a strike radius.
	// Strike and sun coordinates are always in logical (0.0-1.0) game
	//	space values.
	// This scale is used to convert a logical (unit) radius to/from
	//	a graphic coordinate radius.
	CGRect bounds = self.bounds;
	
	// The conversion is currently the average of the height & width
	return (bounds.size.height+bounds.size.width)/2;
}

#pragma mark Animation

- (void)strikeNotification:(NSNotification*)notification
{
	// Notification sent when a stike occurs.
	// Record and start the strike animation.
	
	NSDictionary *info = notification.userInfo;
	STStrike *strike = info[kGameInfoStrike];
	
	// Determine the location of the strike in the view and create the image subview
	CGPoint location = [self pointFromUnitPoint:strike.location];
	CGFloat strikeRadius = [self radiusFromUnitRadius:strike.radius];
	CGRect minFrame = CircleRect(location,kStrikePreviewMinRadius);
	UIImageView *strikeImage = [[UIImageView alloc] initWithFrame:minFrame];
	strikeImage.image = self.strikeImage;
	[self addSubview:strikeImage];
	
	// Animate the strike image so it:
	//	(a) "explodes", growing to its maximum size in the first half of the animation
	//	(b) "collapses" back to its minimum size in the second half of the animation, and
	//	(c) finally disappears
	// This is done using the (modern) block animation interface
	CGRect maxFrame = CircleRect(location,strikeRadius);
	// Start first part of animation
	[UIView animateWithDuration:kStrikeAnimationDuration/2.0
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^{
						 // First half: grow to max size
						 strikeImage.frame = maxFrame;
						 }
					 completion:^(BOOL finished){
						 // This completion block executes after the first animation is finished
						 // Start second half of animation
						 if (finished) {
							 strikeImage.frame = maxFrame;	// set size to max (no animation)
							 [UIView animateWithDuration:kStrikeAnimationDuration/2.0
												   delay:0.0
												 options:UIViewAnimationOptionCurveEaseIn
											  animations:^{
												  // Second half: shrink back down to min size
												  strikeImage.frame = minFrame;
											  }
											  completion:^(BOOL finished){
												  // This  block executes after the last animation is finished
												  // When done, remove strike image from view
												  [strikeImage removeFromSuperview];
											  }];
							 // The hole left by the strike is now ready to draw.
							 // Add the strike to the array of "holes" and trigger a redraw
							 [strikes addObject:strike];
							 [self setNeedsDisplay];
						 } else {
							 [strikeImage removeFromSuperview];
						 }
					 }];
}

- (void)showASun:(STSun *)sun
{
//    NSLog(@"%@", NSStringFromCGPoint(sun.location));
    
    CGPoint sunLocation = [self pointFromUnitPoint:sun.location];
    CGRect beginRect = CircleRect(sunLocation,kSunStrikeBeginRadius);
    
    // Create the sun view object
    UIImageView *sunView = [[UIImageView alloc] initWithFrame:beginRect];
    sunView.opaque = YES;
    [self addSubview:sunView];
    sunView.image = [UIImage imageNamed:@"SunCold"];
}


- (void)showSunsNotification:(NSNotification*)notification
{
    if (!sunsShown) {
        NSLog(@"showSunsNotification");
        NSDictionary *info = notification.userInfo;
        NSArray *suns = info[kGameInfoSunArray];
        for ( STSun* sun in suns )
        {
            [self showASun:sun];
        }
        sunsShown = YES;
    }
}

- (void)hideSunsNotification:(NSNotification*)notification
{
    NSLog(@"hideSunsNotification");
}



- (void)captureNotification:(NSNotification*)notification
{
	// Notification sent when a capture occurs.
	
	// Record and start the capture animation.
	// The animation of captures for both players (local and opponent)
	//	occur in the local game view.
	
	NSDictionary *info = notification.userInfo;
	STSun *sun = info[kGameInfoSun];
	NSNumber *sunKey = info[kGameInfoSunKey];
	
	// Begin (or update) the animation of a sun capture
	//	sun		sun object to animate
	//	sunKey	key that identifies this sun (currently an NSNumber of its game index)
	
	// If this is an update, the previously animated sun view object
	//	will be in the dictionary.
	UIImageView *sunView = sunViews[sunKey];
	if (sunView==nil)
		{
		// This is the first request to animate this sun.
		// Create a sun view object and start its animation.
		CGPoint strikePoint = [self pointFromUnitPoint:sun.location];
		// With the location (in view coordinate), calculate the frame rects for
		//	(a) the size/location where the animation starts
		//	(b) the size/location where it peaks
		//	(c) the size/location of its final resting place
		CGRect beginRect = CircleRect(strikePoint,kSunStrikeBeginRadius);
		CGRect peakRect = CircleRect(strikePoint,kSunStrikeMaxRadius);
		CGRect settleRect = CircleRect([self nextSunSettlePoint],kSunStrikeEndRadius);
		
		// Create the sun view object
		sunView = [[UIImageView alloc] initWithFrame:beginRect];
		sunView.opaque = NO;
		[self addSubview:sunView];
		
		// Start the animation sequence
		[UIView animateWithDuration:kSunSpinAnimationDuration
							  delay:0
							options:UIViewAnimationOptionCurveLinear
						 animations:^{
							 // Grow the sun from its initial size to its peak size
							 sunView.frame = peakRect;
						 }
						 completion:^(BOOL finished){
							 // This block executes when the first animation segment completes
							 // Set the peak size
							 sunView.frame = peakRect;
							 // Now animation from the mid-point to it's final resting place
							 [UIView animateWithDuration:kSunSettleAnimationDuration
												   delay:0
												 options:UIViewAnimationOptionCurveEaseInOut
											  animations:^{
												  // Second half: move to final location and "un-rotate" back to 0
												  sunView.frame = settleRect;
												  sunView.alpha = kSunSettleAlpha;
											  }
											  completion:^(BOOL finished){
												  // This block executes when the second animation finishes
												  // Make the animated changes permanent
												  sunView.frame = settleRect;
												  sunView.alpha = kSunSettleAlpha;
											  }];
						 }];
		// Save this view object in case it's needed again later for an update
		[sunViews setObject:sun forKey:sunKey];
		}
	
	sunView.image = [UIImage imageNamed:@"SunHot"];
}

- (CGPoint)nextSunSettlePoint
{
	sunSettlePoint.y += (kSunStrikeEndRadius*2+2);	// advance to next position
	return sunSettlePoint;
}

#pragma mark Drawing

- (void)drawRect:(CGRect)rect
{
    // Drawing code
	
	// Fill the background
	[self drawBackground];
	
	// Draw the strikes that have occurred
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self setStrikeDrawColor];
	for ( STStrike* strike in strikes )
		{
		// Get the drawing coordinates of the strike's center
		CGPoint center = [self pointFromUnitPoint:strike.location];
		// Get the drawing radius in view coordinates
		CGFloat radius = [self radiusFromUnitRadius:strike.radius];
		// Using the center and radius, create a bounding rectangle for the circle
		CGRect strikeRect = CircleRect(center,radius);
		// Draw the circle
		CGContextFillEllipseInRect(context,strikeRect);
		}
}

- (void)setStrikeDrawColor
{
	// The area of a strike is drawn one of two ways:
	//	In a single player game, the area is painted black.
	//	In a two player game, the strike area is "painted" transparent so the
	//		corresponding area of the opponent's game view shows through.
	// The two modes are inferred from the 'opaque' property of the view itself.
	// If the opaque mode is YES, then draw black circles; if not, erase circles.
	if (self.opaque)
		{
		[[UIColor blackColor] set];
		}
	else
		{
		[[UIColor clearColor] set];
		// In order to "paint" with clear, the blending mode must be set to copy.
		CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeCopy);
		}
}

- (void)drawBackground
{
	// Local game: draw the star field
	UIImage* backgroundImage = [UIImage imageNamed:kBackgroundImageName];
	[backgroundImage drawInRect:self.bounds];		// just squish to fit
}

#pragma mark Touch Events

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	// Intercept single touch events and send them up the responder chain.
	// (We can't use a recognizer for this, because a tap recognizer
	//	doesn't send its action until the player releases the touch,
	//	which is too late.)

	if (touches.count==1) {
		// Tell the game view controller a strike occurred.
		[[UIApplication sharedApplication] sendAction:@selector(touchInGame:event:)
												   to:nil
												 from:self
											 forEvent:event];
	}
}

#pragma mark Coordinate Translation

- (CGPoint)unitPointFromPoint:(CGPoint)viewPoint
{
	// Given a point in the coordinate system of the game view,
	//	return the corresponding point in the game's unit space (0.0-1.0).
	CGRect bounds = self.bounds;
	return CGPointMake((viewPoint.x-bounds.origin.x)/bounds.size.width,
					   (viewPoint.y-bounds.origin.y)/bounds.size.height);
}

- (CGPoint)pointFromUnitPoint:(CGPoint)unitPoint
{
	// Given a point in unit (0.0-1.0) space, return the corresponding point
	//	in game view coordinates.
	CGRect bounds = self.bounds;
	return CGPointMake(bounds.origin.x+(unitPoint.x*bounds.size.width),
					   bounds.origin.y+(unitPoint.y*bounds.size.height));
}

- (CGFloat)unitRadiusFromRadius:(CGFloat)viewRadius
{
	CGRect bounds = self.bounds;
	CGFloat radiusScale = RadiusScale(bounds.size);
	return viewRadius/radiusScale;
}

- (CGFloat)radiusFromUnitRadius:(CGFloat)unitRadius
{
	CGRect bounds = self.bounds;
	CGFloat radiusScale = RadiusScale(bounds.size);
	return STFloor(unitRadius*radiusScale);
}

@end
