//
//  STGame+STDataMessaging.h
//  SunTouch
//
//  Created by James Bucanek on 5/31/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import "STGame.h"

#import "STGameDefs.h"

@class STStrike;


// Methods and definitions used to exchange messages with remote game objects.

// These type are defined here so they can be changed, as needed, so they are
//  always transportable across hardware and CPU architectures.

typedef uint32_t STMessage;				// 32 bit (4 byte) integer
enum {
	kSTStartGameMessage,
	kSTStrikeMessage,
	kSTCaptureMessage
};

// The __attribute__((aligned(4), packed)) compiler attribute packs the structs
//	at 4 byte boundries. Since all of the fields are multiples of 4 bytes,
//	structures will contain no padding and be unformly aligned on all machines.

typedef float STFloat;					// IEEE 754 (binary32) on all platforms
typedef struct {
	STFloat	x;
	STFloat	y;
} __attribute__((aligned(4), packed)) STMessagePoint;

struct STStartGameMessage {
	STMessage		message;			// = kSTStartGameMessage
	uint32_t		coinToss;			// random number used to choose a set of suns
	STMessagePoint	sun[kSunCount];		// randomly selected suns
} __attribute__((aligned(4), packed));

struct STStrikeMessage {
	STMessage		message;			// = kSTStrikeMessage
	STMessagePoint	location;			// location of strike
	STFloat			radius;				// radius of strike
} __attribute__((aligned(4), packed));

struct STCaptureMessage {
	STMessage		message;			// = kSTCaptureMessage
	uint32_t		sunIndex;			// sun identifier
	STFloat			gameTime;			// time of capture
} __attribute__((aligned(4), packed));


@interface STGame (STDataMessaging) <GKMatchDelegate>

- (void)sendGameStart;
- (void)sendStrike:(STStrike*)strike;
- (void)sendCaptureForSunIndex:(NSUInteger)index;;

@end

