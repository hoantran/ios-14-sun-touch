//
//  STGame+STDataMessaging.m
//  SunTouch
//
//  Created by James Bucanek on 5/31/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import "STGame+STDataMessaging.h"

#import "STStrike.h"
#import "STSun.h"


@implementation STGame (STDataMessaging)

- (void)sendGameStart
{
	// Assemble a start game message and send it to the other player.
	// The start message includes a list of candidate sun locations
	//	and a coin toss. The player that's the winner of the coin
	//	toss determines the list of sun locations.
	struct STStartGameMessage message;
	message.message = kSTStartGameMessage;
	message.coinToss = coinToss;
	for ( NSUInteger i=0; i<kSunCount; i++ )
		{
		STSun *sun = suns[i];
		message.sun[i].x = sun.location.x;
		message.sun[i].y = sun.location.y;
		}
	
	NSData *data = [NSData dataWithBytes:&message length:sizeof(message)];
	[multiPlayerMatch sendDataToAllPlayers:data
							  withDataMode:GKMatchSendDataReliable
									 error:NULL];
}

- (void)sendStrike:(STStrike*)strike
{
	// Assemble and send a strike message to the other player(s).
	if (multiPlayerMatch==nil)
		// single player games don't send messages
		return;
	
	// A strike consists of its location and radius, in unit (game) coordinates.
	struct STStrikeMessage message;
	message.message = kSTStrikeMessage;
	message.location.x = strike.location.x;
	message.location.y = strike.location.y;
	message.radius = strike.radius;
    
	NSData *data = [NSData dataWithBytes:&message length:sizeof(message)];
	[multiPlayerMatch sendDataToAllPlayers:data
							  withDataMode:GKMatchSendDataReliable
									 error:NULL];
}

- (void)sendCaptureForSunIndex:(NSUInteger)index
{
	// Assemble and send a capture message.
	if (multiPlayerMatch==nil)
		// single player games don't send messages
		return;
    
	// The sun is referred to by its index number and the time the capture occurred
	//	in the local game. The game time is used to resolve conflicts that might
	//	occur when two players capture the same sun before they can communicate
	//	that fact with the other player(s).
	struct STCaptureMessage message;
    STSun *sun = suns[index];
	message.message = kSTCaptureMessage;
	message.sunIndex = (uint32_t)index;
	message.gameTime = sun.time;
	
	NSData *data = [NSData dataWithBytes:&message length:sizeof(message)];
	[multiPlayerMatch sendDataToAllPlayers:data
							  withDataMode:GKMatchSendDataReliable
									 error:NULL];
}

#pragma mark <GKMatchDelegate>

- (void)match:(GKMatch*)match didReceiveData:(NSData*)data fromPlayer:(NSString*)playerID
{
	STMessage message = *((STMessage*)data.bytes);	// First word in data blob is STMessage value
	switch (message) {
		case kSTStartGameMessage: {
			// Compare the coin-toss to see which set of suns will be used
			const struct STStartGameMessage *message = data.bytes;
			if (message->coinToss>coinToss)
				{
				// We lost the coin toss: use the set of sun position from the other player.
				// Replace the array of suns, using the coordinates in the message.
				STSun *otherSuns[kSunCount];
				for ( NSUInteger i=0; i<kSunCount; i++ )
					otherSuns[i] = [STSun sunAt:message->sun[i].x:message->sun[i].y];
				suns = [NSArray arrayWithObjects:otherSuns count:kSunCount];
				}
			else if (message->coinToss==coinToss)
				{
				// One-in-a-billion chance that both players rolled the same random value:
				//	just start the game again.
				coinToss = arc4random();
				[self sendGameStart];
				return;
				}
			// else (message->coinToss<coinToss): we won, use our set of suns
            
			// Game starts now
			startTime = [NSDate timeIntervalSinceReferenceDate];
            
			// Execute the completion block so the caller who sent -startMultiPlayerWithMatch:started:
			//	knows the game has now begun.
			multiPlayStarted();
            }
			break;
			
		case kSTStrikeMessage: {
			// Received a strike event from the opposing player
			// Post an opponent strike notification so the opponent game view can animate it
			const struct STStrikeMessage *message = data.bytes;
			STStrike *strike = [STStrike new];
			strike.location = CGPointMake(message->location.x,message->location.y);
			strike.radius = message->radius;
			NSDictionary *strikeInfo = @{ kGameInfoStrike: strike, kGameInfoOpponent: @YES };
			[[NSNotificationCenter defaultCenter] postNotificationName:kGameStrikeNotification
																object:self
															  userInfo:strikeInfo];
            }
			break;
			
		case kSTCaptureMessage: {
			// Recieved a sun capture event from the opposing player
			const struct STCaptureMessage *message = data.bytes;
			[self willCaptureSunAtIndex:message->sunIndex gameTime:message->gameTime localPlayer:NO];
            }
			break;
	}
}

- (void)match:(GKMatch*)match player:(NSString*)playerID didChangeState:(GKPlayerConnectionState)state
{
	// We don't really care if the other players change state.
	// If two devices lose communications, it's sad, but we just let the local player continue to play.
	// If it comes back, the game should pick up where it left off. Sorta. Maybe. Doesn't really matter.
	// In a perfect world, we'd pause the game (or something) until the remote player connected again.
}

- (void)match:(GKMatch*)match didFailWithError:(NSError*)error
{
	// If this message is received, the communications is truely hosed.
	// Just cancel the game and let the players try again.
	[[NSNotificationCenter defaultCenter] postNotificationName:kGameDidEndNotifcation object:self];
}

- (BOOL)match:(GKMatch *)match shouldReinvitePlayer:(NSString*)playerID
{
	return YES;
}

@end
