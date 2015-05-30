//
//  CECrossfadeAnimationController.h
//  TransitionsDemo
//
//  Created by Colin Eberhardt on 11/09/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "CEReversibleAnimationController.h"

/**
 Animates between the two view controllers by performing a simple cross-fade. 
 */
@interface CECrossfadeAnimationController : CEReversibleAnimationController

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext fromVC:(UIViewController *)fromVC toVC:(UIViewController *)toVC fromView:(UIView *)fromView toView:(UIView *)toView;

@end
