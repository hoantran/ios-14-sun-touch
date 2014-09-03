//
//  STOpponentGameView.m
//  SunTouch
//
//  Created by James Bucanek on 2/3/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import "STOpponentGameView.h"

#import "STGameDefs.h"
#import "STGame.h"


#define kOpponentStrikeImageName	@"StrikeBack"


@implementation STOpponentGameView

- (void)observeNotificationsFromGame:(STGame*)game
{
	[super observeNotificationsFromGame:game];
	
	// The superclass sets up observations for both "strike" and "capture" notifications.
	// The opponent view is only interested in "strike" events (capture events are
	//	animated in the local game view). So un-observe capture notifications.
	if (game!=nil)
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:kGameSunCaptureNotification
													  object:game];
}

#pragma mark Properties

- (BOOL)opponent
{
	return YES;
}

- (UIImage*)strikeImage
{
	// Opponent player view returns the "dark" strike image
	return [UIImage imageNamed:kOpponentStrikeImageName];
}

- (void)setStrikeDrawColor
{
	// The opponent view draws strike areas as black
	[[UIColor blackColor] set];
}

- (void)drawBackground
{
	// The background of the opponent's view is grey
	[[UIColor darkGrayColor] set];
	CGContextFillRect(UIGraphicsGetCurrentContext(),self.bounds);
}


@end
