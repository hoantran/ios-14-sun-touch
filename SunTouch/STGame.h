//
//  STHitList.h
//  SunTouch
//
//  Created by James Bucanek on 1/23/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@class STGameView;

// STGame is the game engine.

// Global game constants
#pragma mark Constants

// Notifications
#define kGameStrikeNotification				@"STStrike"
#define kGameSunCaptureNotification			@"STCapture"
#define kGameScoreDidChangeNotification		@"STScoreDidChange"
#define kGameDidEndNotifcation				@"STGameDidEnd"
#define kGameShowSuns                       @"STGameShowSuns"
// Notification info keys
#define kGameInfoStrike						@"strike"		// STStrike
#define kGameInfoSun						@"sun"			// STSun
#define kGameInfoSunKey						@"key"			// NSNumber (int)
#define kGameInfoSunArray                   @"suns"         // STSun *
#define kGameInfoOpponent					@"opponent"		// NSNumber (BOOL)



#pragma mark -
@interface STGame : NSObject
{
	// private variables
	NSArray*			suns;					// array of sun objects
	NSTimeInterval		startTime;				// time game started
	
	GKMatch				*multiPlayerMatch;		// multi-player connection
	void				(^multiPlayStarted)(void);
	uint32_t			coinToss;
}

+ (NSArray*)randomSuns;

@property (readonly,nonatomic) BOOL				started;
@property (nonatomic) BOOL						ended;
@property (readonly,nonatomic) NSUInteger		score;
@property (readonly,nonatomic) NSUInteger		opponentScore;
@property (readonly,nonatomic) BOOL				over;

- (void)startSinglePlayer;
- (void)startMultiPlayerWithMatch:(GKMatch*)match started:(void(^)(void))started;

@property (readonly,nonatomic) NSTimeInterval gameTime;
- (NSUInteger)weightAtTime:(NSTimeInterval)time;

- (void)strike:(CGPoint)location
		radius:(CGFloat)radius
		inView:(STGameView*)gameView;

- (void)willCaptureSunAtIndex:(NSUInteger)sunIndex
					 gameTime:(NSTimeInterval)gameTime
				  localPlayer:(BOOL)local;

- (void)showSuns;
@end
