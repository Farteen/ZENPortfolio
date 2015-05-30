//
//  BouncePresentAnimationController.m
//  ILoveCatz
//
//  Created by Frédéric ADDA on 26/09/13.
//  Copyright (c) 2013 com.razeware. All rights reserved.
//

#import "BouncePresentAnimationController.h"

@implementation BouncePresentAnimationController

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5;
}


- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // 1. obtain state from the context
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    CGRect finalFrame = [transitionContext finalFrameForViewController:toViewController];
    
    // 2. obtain the container view
    UIView *containerView = [transitionContext containerView];
    
    // 3. set initial state
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    toViewController.view.frame = CGRectOffset(screenBounds, 0, screenBounds.size.height); // Position the to-view just below the bottom of the screen

    // 4. Add the view
    [containerView addSubview:toViewController.view];
    
    // 5. animate
    NSTimeInterval duration = [self transitionDuration:transitionContext];

    
    [UIView animateWithDuration:duration
                          delay:0.0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         // Set the state to animate to
                         fromViewController.view.alpha = 0.5;
                         toViewController.view.frame = finalFrame;
                         
                     } completion:^(BOOL finished) {
                         // Inform the context of completion
                         fromViewController.view.alpha = 1.0;
                         [transitionContext completeTransition:YES];
                     }];
    
}


@end
