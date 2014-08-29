//
//  STMainViewController.h
//  SunTouch
//
//  Created by James Bucanek on 10/31/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import <GameKit/GameKit.h>

#import "STFlipsideViewController.h"

@interface STMainViewController : UIViewController <STFlipsideViewControllerDelegate,
                                                    UIPopoverControllerDelegate,
                                                    GKGameCenterControllerDelegate>

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;

@property (weak,nonatomic) IBOutlet UIButton *singlePlayButton;
@property (weak,nonatomic) IBOutlet UIButton *multiPlayButton;

- (IBAction)showGameCenter;

@end
