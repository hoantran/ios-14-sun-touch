//
//  STGameViewController.h
//  SunTouch
//
//  Created by James Bucanek on 5/23/13.
//  Copyright (c) 2013 Apress. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STGame.h"
#import "STGameView.h"

@interface STGameViewController : UIViewController

@property (strong,nonatomic) IBOutlet	UILabel		*scoreLabel;
@property (strong,nonatomic) IBOutlet	UILabel		*weightLabel;

@property (strong,nonatomic) IBOutlet	UIView		*strikePreviewSuperview;
@property (strong,nonatomic)			UIImageView	*strikePreview;

- (void)startGame;
- (void)finishGame;
- (void)gameOver;

- (void)touchInGame:(STGameView*)gameView event:(UIEvent*)event;
- (IBAction)pinchGesture;

@end
