//
//  STGameViewController.m
//  SunTouch
//
//  Created by James Bucanek on 5/23/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "STGameViewController.h"

#import "STGameDefs.h"

@import AVFoundation;

@interface STGameViewController ()
{
	NSNumberFormatter	*scoreFormatter;
	__weak NSTimer		*weightUpdateTimer;
	NSDate				*strikePreviewStartDate;
	UIAlertView			*endGameAlert;
}
@property (strong,nonatomic)			STGame		*game;
@property (strong,nonatomic) IBOutlet	STGameView	*gameView;

@property (assign) SystemSoundID pewPewSound;

- (void)startStrikeGrowAnimation;
- (void)updateScoreNotification:(NSNotification*)notification;
- (void)startWeightTimer;
- (void)stopWeightTimer;
- (void)updateWeightTime:(NSTimer*)timer;

- (IBAction)showSuns:(UITapGestureRecognizer*)gesture;

@end


@implementation STGameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Create a formatter that will be used to display scores
	scoreFormatter = [NSNumberFormatter new];
	[scoreFormatter setPositiveFormat:@"#,##0"];
    
    //
    NSLog(@"** viewDidLoad **");
    if (self) {
        [self configureSystemSound];
    }
    
//    [self playSystemSound];
}

- (void)configureSystemSound {
    // This is the simplest way to play a sound.
	// But note with System Sound services you can only use:
	// File Formats (a.k.a. audio containers or extensions): CAF, AIF, WAV
	// Data Formats (a.k.a. audio encoding): linear PCM (such as LEI16) or IMA4
	// Sounds must be 30 sec or less
	// And only one sound plays at a time!
//	NSString *pewPewPath = [[NSBundle mainBundle] pathForResource:@"pew-pew-lei" ofType:@"caf"];
    NSString *pewPewPath = [[NSBundle mainBundle] pathForResource:@"explosion-02" ofType:@"wav"];
	NSURL *pewPewURL = [NSURL fileURLWithPath:pewPewPath];
	AudioServicesCreateSystemSoundID((__bridge CFURLRef)pewPewURL, &_pewPewSound);
}

- (void)playSystemSound {
    NSLog(@"playSystemSound: %d", (unsigned int)self.pewPewSound);
    AudioServicesPlaySystemSound(self.pewPewSound);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
	// The view is about to appear.
	// Perform any setup or initialization that needs to be done _before_
	//	any of the views are displayed for the first time.
	
	// Reset the score and weight fields before they are shown
	self.scoreLabel.text = @"0";
	self.weightLabel.text = @"0";
	
	// If a strike preview view has been previously created, hide it
	//	until we're ready to animate it
	self.strikePreview.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
	// The view has (re)appeared
	
	// -viewDidAppear is a good place to trigger things that should start with the view appears.
	// However, some care must be taken because this message can be received multiple times.
	// In a multi-player iPhone game, for example, the game begins by presenting a GKMatchmakerViewController.
	// The presented view causes this view to disappear, and then reappear again after the match.
	// So if this method blindly started a game by initiating a match, the game would start over
	//	again as soon as it started.
	
	// Whenever the view is visible, run a timer to update the weight field
	[self startWeightTimer];
	
	// Listen for score change notifications
	// (it's possible for this to be called multiple times, so make it safe by first unsubscribing
	//	from all notifications before subscribing again).
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
	[notificationCenter addObserver:self
						   selector:@selector(updateScoreNotification:)
							   name:kGameScoreDidChangeNotification
							 object:self.game];
    
    // triple tap
    UITapGestureRecognizer *tripleTapGesture;
    tripleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                               action:@selector(showSuns:)];
    tripleTapGesture.numberOfTapsRequired = 3;
    [self.gameView addGestureRecognizer:tripleTapGesture];
	
	// Start/resume the game
	[self startGame];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// Stop updating the weight field
	[self stopWeightTimer];
	
	// Stop listening for notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)prefersStatusBarHidden
{
    // This controller does not want a status bar at the top
    return YES;
}

#pragma mark Game Management

- (void)startGame
{
	if (self.game==nil)
		{
		// Create the game object
		STGame *game = [STGame new];
		self.game = game;
		
		// Clear/reset the game views
		[self.gameView reset];
		
        // A single player game begins immediately
        
        // Tell the single game view to observe game notifications from this game
        [self.gameView observeNotificationsFromGame:game];
        
        // Start the game
        [game startSinglePlayer];
        
        // Start the strike preview growing
        [self startStrikeGrowAnimation];
		}
}

- (void)finishGame
{
    // The game is finished. Tell the player their score and record it in Game Center.
    
	// (endGameAlert also acts as a flag to indicate that a -finishGame message has been recieved already.
    //  That could happen if the game ended near time the player pinched to stop.)
	if (endGameAlert==nil)
		{
		// Display a pop-up with the final score
		NSUInteger score = self.game.score;
		NSNumber *scoreValue = @(score);
		NSString *title = @"Congratulations!";
		NSString *message = [NSString stringWithFormat:@"Your score: %@",
                             [scoreFormatter stringFromNumber:scoreValue]];
		
		endGameAlert = [[UIAlertView alloc] initWithTitle:title
												  message:message
												 delegate:self
										cancelButtonTitle:nil
										otherButtonTitles:@"OK",nil];
		[endGameAlert show];
		
		// Hide the strike preview
		self.strikePreview.hidden = YES;
        
		// Record the score and end the game
		GKScore *scoreReport = [[GKScore alloc] initWithLeaderboardIdentifier:kSinglePlayerLeaderboardID];
		scoreReport.value = score;
        [GKScore reportScores:@[scoreReport] withCompletionHandler:^(NSError *error) {
            // TODO: check for errors or get leaderboard results
            }];
		}
}

- (void)gameOver
{
	if (self.game!=nil)
		{
		// Post "game over" notification to any listeners
		// This will be caught by the main view controller and will dismiss, and destroy, this
		//	view controller, its view, the game objects, and everything else intereseting.
		[[NSNotificationCenter defaultCenter] postNotificationName:kGameDidEndNotifcation
															object:self];
		// Discard the game object: this destroys the game and debounces this method
		self.game = nil;
		}
}

#pragma mark User Events

- (void)touchInGame:(STGameView*)gameView event:(UIEvent*)event
{
	STGame *game = self.game;
	if (!game.started)
		// If the game isn't running yet, ignore this gesture.
		// This can happen at the beginning of a multi-player game while the
		//	game view controller is waiting for the other players to connect.
		return;
	
	// Local player tapped the game view: create a strike at that location
	NSSet *touches = [event touchesForView:gameView];
	CGPoint strikeLocation = [[touches anyObject] locationInView:gameView];
	
	// Based on the elapsed time since the preview was last started, determine the
	//	size (radius) of the strike.
	// The size starts at kStrikePreviewMinRadius and grows up to a calculated maximum
	//	for kStrikePreviewGrowDuration seconds, at which time it stops growing.
	NSTimeInterval elapsed = -[strikePreviewStartDate timeIntervalSinceNow];
	if (elapsed>kStrikePreviewGrowDuration)
		elapsed = kStrikePreviewGrowDuration;
	// Calculate the fraction (0.0-1.0) of the maximum strike size
	CGFloat strikeFraction = elapsed/kStrikePreviewGrowDuration;
	// Calculate the radius of the strike
	CGFloat maxRadius = [gameView radiusFromUnitRadius:kStrikePreviewMaxUnit];
	CGFloat strikeRadius = STFloor((maxRadius-kStrikePreviewMinRadius)
								   *STSquareRoot(strikeFraction)
								   +kStrikePreviewMinRadius);
	
	// Tell the game engine a strike occurred
	// The game object will search for hits and schedule any sun strike events
	[game strike:strikeLocation radius:strikeRadius inView:gameView];
	
	// Last, but not least, restart the strike size over at its minimum again
	[self startStrikeGrowAnimation];
    
    // sound
    [self playSystemSound];
	
}

- (void)pinchGesture
{
	// The user used the "pinch to end" gesture.
	// Terminate the game (don't record a score)
	[self gameOver];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// User touched OK (not that there was any other choice)
	
	// It's all over!
	[self gameOver];
}

- (IBAction)showSuns:(UITapGestureRecognizer *)gesture
{
    NSLog(@"Triple Tap!");
    if (self.game!=nil)
    {
        [self.game showSuns];
    }
}

#pragma mark Periodic Maintenance

- (void)startStrikeGrowAnimation
{
	// Start the animation that shows the size of the strike.
	
	// Determine the starting and ending radius of the strike preview
	CGFloat maxRadius = [self.gameView radiusFromUnitRadius:kStrikePreviewMaxUnit];
	// (minRadius is always kStrikePreviewMinRadius)
	
	// Lazily create the strike preview
	UIImageView *previewView = self.strikePreview;
	if (previewView==nil)
		{
		// Create the strike preview image view.
		// This is done programmatically because Interface Builder will attach all kinds of
		//	constraints to the view that essentially prohibit it from being dynamically resized
		//	or repositioned later. Creating this view from scratch is a lot simplier than trying
		//	to work around the contraints.
		// The frame of the image view is centered in its superview, at the maximum size
		//	of the strike. This will be the "resting" image when there is no amimation.
		// (Remember that the animation doesn't change the properties/layout of a view, it simply
		//	changes how the view appears for a brief period of time. The amimation starts small
		//	and grows to its final size. When the animation is over, you want the view to display
		//	at its final size.)
		
		// Calculate where the view will be centered
		CGRect superviewBounds = self.strikePreviewSuperview.bounds;
		CGPoint strikePreviewCenter = CGPointMake(CGRectGetMidX(superviewBounds),
												  CGRectGetMidY(superviewBounds));
		// Create a new UIImageView objest centered at the location
		previewView = [[UIImageView alloc] initWithFrame:CircleRect(strikePreviewCenter,
																	maxRadius)];
		// Assign the image the same image used by the local game view
		previewView.image = self.gameView.strikeImage;
		// Insert the view
		[self.strikePreviewSuperview addSubview:previewView];
		// Remember the new view; we'll need it again later
		self.strikePreview = previewView;
		}
	previewView.hidden = NO;			// unhide a previously hidden view (see -viewWillAppear:)
	
	// Create an animation that logrithmically grows the radius of the strike so its total
	//	area (pi*r^2) grows linearly. This animation is approximated using a keyframe animation.
	// Create a matched pair of arrays that define the keyframe times and values
	//	that the size of the strike preview will grow over time.
	// These keyframes grow the size of the circle so that the *area* of the strike circle
	//	increases linearly over time.
	NSMutableArray *times = [NSMutableArray new];
	NSMutableArray *values = [NSMutableArray new];
	CGRect rect;
	for ( float time=0.0f; time<=1.01f; time+=0.1f )
		{
		// Calculate what the radius of the strike circle should be at a given fraction of the animation
		CGFloat r = STFloor((maxRadius-kStrikePreviewMinRadius)
							*STSquareRoot(time)
							+kStrikePreviewMinRadius);
		// Turn the radius into a bounding rect
		rect = CGRectMake(0,0,r*2,r*2);
		// Add the keyframe time and rect to the arrays as objects
		[times addObject:@(time)];
		[values addObject:[NSValue valueWithCGRect:rect]];
		}
	// Make sure the last keyframe time is exactly 1.0
	[times replaceObjectAtIndex:10 withObject:@1.0f];
	
	// Create an animation object that changes the bounds of strikePreview
	CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"bounds"];
	animation.duration = kStrikePreviewGrowDuration;
	animation.beginTime = 0;
	animation.calculationMode = kCAAnimationCubic;		// this should closely approximate the actual curve
	animation.keyTimes = times;
	animation.values = values;
	
	// Attach the animation to the view's core animation layer (this starts the animation)
	[previewView.layer addAnimation:animation forKey:@"grow"];
	
	// Remember the time the strike preview started growing
	strikePreviewStartDate = [NSDate date];
}

- (void)updateScoreNotification:(NSNotification*)notification
{
	// Received when the game's score has changed
	// Update the on-screen display of the score, which it calculated by the game object
	STGame *game = notification.object;
	self.scoreLabel.text = [scoreFormatter stringFromNumber:@(game.score)];
	
	// This is a good as place as any to check to see if the game is over, since the game ends
	//	when all suns have been captured (and the score only changes when a sun is captured)
	if (self.game.over)
		// 1.5 seconds after the last sun is captured, fire a -finishGame message
		// Note that this gives our networked opponent that long to resolve any
		//	sun capture conflicts (and vice versa).
		[self performSelector:@selector(finishGame)
				   withObject:nil
				   afterDelay:1.5];
}

- (void)startWeightTimer
{
	// If not already done, create a timer to update the weight field periodically
	// Save a (weak) reference to it becuase we'll need to stop it again later.
	if (weightUpdateTimer==nil)
		weightUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/6.0 /* update ~6x a second */
															 target:self
														   selector:@selector(updateWeightTime:)
														   userInfo:nil
															repeats:YES];
}

- (void)stopWeightTimer
{
	// Stop the timer that updates the weight
	[weightUpdateTimer invalidate];
	weightUpdateTimer = nil;
}

- (void)updateWeightTime:(NSTimer*)timer
{
	// Periodically update the "weight" field so it shows the player the points they will get if they
	//	captured a sun a this moment.
	NSNumber *value = @([_game weightAtTime:_game.gameTime]);
	self.weightLabel.text = [scoreFormatter stringFromNumber:value];
}

@end
