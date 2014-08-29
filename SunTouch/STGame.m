//
//  STHitList.m
//  SunTouch
//
//  Created by James Bucanek on 1/23/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import "STGame.h"
//#import "STGame+Messaging.h"

#import "STGameDefs.h"
#import "STStrike.h"
#import "STSun.h"
#import "STGameView.h"


@interface STGame () // private interface
- (void)postCapture:(NSNumber*)sunIndex;
@end


@implementation STGame

+ (NSArray*)randomSuns
{
	// Generate an array of randomly placed suns
	STSun* suns[kSunCount];
	for ( NSUInteger i=0; i<kSunCount; i++) {
		STSun* sun;
collision:
		sun = [STSun randomSun];
		// If the sun location is too close to any other sun, try again
		for ( NSUInteger j=0; j<i; j++ ) {
			if (DistanceBetweenPoints(sun.location,suns[j].location)<kSunDistanceMin)
				goto collision;
		}
		suns[i] = sun;
	}
	
	// Convert the C array of sun objects into an immutable Cocoa array, and return it
	return [NSArray arrayWithObjects:suns count:kSunCount];
}

#pragma mark Properties

- (BOOL)started
{
	return startTime!=0;
}

- (NSTimeInterval)gameTime
{
	return [NSDate timeIntervalSinceReferenceDate]-startTime;
}

- (NSUInteger)weightAtTime:(NSTimeInterval)gameTime
{
	// Return the score weight for a given time.
	// The score weight is the points a player gets for bagging
	//	a star.
	
	// The weight value begins at kWeightMax at the beginning of
	//	the game, and goes down, asymptotically, until it eventually
	//	arrives at kWeightMin after kWeightToZeroTime has elapsed.
	
	// If the elapsed game time has gone beyond kWeightToZeroTime,
	//	return the minimum weight
	if (gameTime>=kWeightToZeroTime)
		return kWeightMin;
	
	// Convert the max score into a current weight by converting
	//	the elapsed game time to a value between e and 1.
	// The log of that value returns a number between 1.0 and 0.0, which
	//	is then multiplied by kWeightMax to obtain the weight.
	// (Note: M_E is the library constant for the mathematical value of "e")
	double relWeight = log(1.0+((gameTime/kWeightToZeroTime)*(M_E-1.0)));
	NSUInteger weight = kWeightMax-(NSUInteger)(relWeight*kWeightMax);
	
	// Clamp the return value so it is never less than kWeightMin
	if (weight<kWeightMin)
		weight = kWeightMin;
	
	return weight;
}

- (NSUInteger)score
{
	// Calculate the score for the player.
	// The total score is calculated by adding up the weighted score
	//	 of every captured sun, after its capture time has elapsed.
	NSTimeInterval gameTime = self.gameTime;
	NSUInteger score = 0;
	for ( STSun* sun in suns )
		if (sun.captured && sun.time<=gameTime)
			score += [self weightAtTime:sun.time];
	return score;
}

- (BOOL)over
{
	// Return YES if the game is over
	// The game is over when all of the suns have been captured
	for ( STSun* sun in suns )
		if (!sun.captured)
			return NO;
	return YES;
}

#pragma mark Gameplay

- (void)startSinglePlayer
{
	// Start a single player game
	startTime = [NSDate timeIntervalSinceReferenceDate];
	suns = [STGame randomSuns];				// create a random set of suns
}

#pragma Game Logic

- (void)strike:(CGPoint)viewLocation
		radius:(CGFloat)viewRadius
		inView:(STGameView*)gameView
{
//    [self showSuns];
//    NSLog(@"notificationCenter: %p", [NSNotificationCenter defaultCenter]);
    
	// location and radius are in view coordinates
	// (this has to be done so the aspect ratio of the game view is taken into
	//	account when searching for sun collisions)
	
	// Create a strike object, converting game view into unit coordinates
	STStrike* strike = [STStrike new];
	strike.location = [gameView unitPointFromPoint:viewLocation];
	strike.radius = [gameView unitRadiusFromRadius:viewRadius];
	
	// Post a "strike" notification so all observers know a strike occurred.
	// The notification includes the strike object and a flag to indicate this
	//	strike belongs to the local player. (Opponent strike notifications are
	//	posted elsewhere.)
	NSDictionary *strikeInfo = @{ kGameInfoStrike: strike };
	[[NSNotificationCenter defaultCenter] postNotificationName:kGameStrikeNotification
														object:self
													  userInfo:strikeInfo];
	
	// Search to see if this strike will hit any suns
	for ( NSUInteger i=0; i<kSunCount; i++ )
		{
		STSun* sun = suns[i];
		if (sun.captured)
			// ignore suns that have already been captured
			continue;
		
		// Calculate distance from the strike point
		CGPoint sunPoint = [gameView pointFromUnitPoint:sun.location];
		CGFloat sunDistance = DistanceBetweenPoints(sunPoint,viewLocation);
		if (sunDistance<=viewRadius)
			{
			// It's a hit!
			// Calculate the (approximate) time the strike will hit this sun
			NSTimeInterval strikeTime = self.gameTime+kStrikeAnimationDuration/2*(sunDistance/viewRadius);
			[self willCaptureSunAtIndex:i gameTime:strikeTime /*localPlayer:YES*/];
			}
		}
}

- (void)willCaptureSunAtIndex:(NSUInteger)sunIndex
				gameTime:(NSTimeInterval)gameTime
{
	// Schedule a sun capture in the near future
	
	// This also arbitrates between competing sun strikes received from remote players.
	// The rule is simple: the first capture wins.
	// Because of race conditions, network delays, etc., the competing sun capture event
	//	could occur *after* the a local capture has already been started. For this reason,
	//	kGameSunCaptureNotification observers have to deal with a capture changing
	//	spontaniously from an "ours" to a "theirs" even after the animation has started.
	
	// Get the sun object
	STSun* sun = suns[sunIndex];
	if (!sun.captured || gameTime<sun.time)
		{
		// This sun has never been captured by anyone OR the game time of the capture
		//	is after the game time for this event.
		sun.time = gameTime;
		
		// Schedule a timer to start (or update) the sun capture animation, score, etc.
		NSTimeInterval delay = gameTime-self.gameTime;
		if (delay<0)
			delay = 0;
		[self performSelector:@selector(postCapture:)
				   withObject:@(sunIndex)
				   afterDelay:delay];
		}
}

- (void)postCapture:(NSNumber*)sunIndex
{
	// Generate and post the notification associated with capturing a sun.
	STSun *sun = suns[sunIndex.unsignedIntegerValue];
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	// Post a "sun captured" notification
	[notificationCenter postNotificationName:kGameSunCaptureNotification
									  object:self
									userInfo:@{ kGameInfoSun: sun,
												kGameInfoSunKey: sunIndex }];
	// Post a notification that the score (might have) changed
	[notificationCenter postNotificationName:kGameScoreDidChangeNotification
									  object:self];
}

- (void)showSuns
{
    NSLog(@"suns: %p", suns);
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    NSLog(@"notificationCenter: %p", notificationCenter);
    
    // Post a "Show all of the suns" notification
    [notificationCenter postNotificationName:kGameShowSuns
                                      object:self
                                    userInfo:@{ kGameInfoSunArray: suns }];
}

@end
