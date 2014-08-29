//
//  STMainViewController.m
//  SunTouch
//
//  Created by James Bucanek on 10/31/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import "STMainViewController.h"

#import "STGameViewController.h"


@interface STMainViewController ()
- (void)gameEndedNotification:(NSNotification*)notification;
@end


@implementation STMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Obtain the Game Kit's local player object (the player logged into Game Center)
	__weak GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];	// (singleton)
    // Set the Game Kit authentication handler code block. This block will be executed
    //	as needed to authenticate/reauthenticate the local player.
    // More importantly, the act of setting authenticationHandler triggers the Game Kit
    //	framework to authenticate the player in the background. If the player is already
    //	logged in, it will indicate that when the block is executed. If the player needs
    //	to log in, the -showAuthentication: message is sent, causing the Game Center
    //	authentication view controller to appear. If the user is not logged in, refuses, or
    //	there's something broken, -disableGameCenter disables the game.
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
		if (viewController!= nil)
			// There is no local user: show the authentication view so the user can log in
			[self showAuthenticationView:viewController];
		else if (localPlayer.authenticated)
			// We have a local user!
			[self authenticatePlayer:localPlayer];
		else
			// User won't long in, or game kit is not available
			[self disableGameCenter];
        };
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(STFlipsideViewController *)controller
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.flipsidePopoverController = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            self.flipsidePopoverController = popoverController;
            popoverController.delegate = self;
        }
    }
	else if ([segue.destinationViewController isKindOfClass:[STGameViewController class]])
		{
		// Register to receive "game over" notifications.
		// It's the main controller's responsibility to close the modal
		//	game view controller when the game is over.
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(gameEndedNotification:)
													 name:kGameDidEndNotifcation
												   object:nil];
		}
}

- (IBAction)togglePopover:(id)sender
{
    if (self.flipsidePopoverController) {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
        self.flipsidePopoverController = nil;
    } else {
        [self performSegueWithIdentifier:@"showAlternate" sender:sender];
    }
}

#pragma mark Game View Controller

- (void)gameEndedNotification:(NSNotification *)notification
{
	// The kGameDidEndNotifcation is when the game is over and
	//	it wants the game view controller to return to the main view.
	
	// Receiving a kGameDidEndNotifcation implies that this view controller has presented
	//	the model STGameViewController, and now it wants it to close.
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark Game Kit

- (void)showAuthenticationView:(UIViewController*)viewController
{
	[self presentViewController:viewController animated:YES completion:NULL];
}

- (void)authenticatePlayer:(GKLocalPlayer*)player
{
	// The local player is authenticated: enable game play
	self.singlePlayButton.hidden = NO;
	self.multiPlayButton.hidden = NO;
}

- (void)disableGameCenter
{
	// No Game Kit: No game
	self.singlePlayButton.hidden = YES;
	self.multiPlayButton.hidden = YES;
}

- (IBAction)showGameCenter
{
	// Present the standard game center view controller
    GKGameCenterViewController *gameCenterController = [GKGameCenterViewController new];
	
    if (gameCenterController!=nil)
		{
		gameCenterController.gameCenterDelegate = self;
		[self presentViewController:gameCenterController animated:YES completion:nil];
		}
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
	// Game Center authentication/leaderboard/settings/whatever controller is done; dismiss it
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
