//
//  STMainViewController.h
//  SunTouch
//
//  Created by Hoan Tran on 8/25/14.
//  Copyright (c) 2014 Pego Consulting. All rights reserved.
//

#import "STFlipsideViewController.h"

@interface STMainViewController : UIViewController <STFlipsideViewControllerDelegate, UIPopoverControllerDelegate>

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;

@end
