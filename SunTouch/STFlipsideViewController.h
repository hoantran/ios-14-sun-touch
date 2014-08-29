//
//  STFlipsideViewController.h
//  SunTouch
//
//  Created by James Bucanek on 10/31/13.
//  Copyright (c) 2013 Apress. All rights reserved.
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
