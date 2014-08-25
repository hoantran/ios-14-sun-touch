//
//  STFlipsideViewController.h
//  SunTouch
//
//  Created by Hoan Tran on 8/25/14.
//  Copyright (c) 2014 Pego Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STFlipsideViewController;

@protocol STFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(STFlipsideViewController *)controller;
@end

@interface STFlipsideViewController : UIViewController

@property (weak, nonatomic) id <STFlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end
