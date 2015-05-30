//
//  ZENActionSheet.m
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 28/10/12.
//  Copyright (c) 2012 Frédéric ADDA. All rights reserved.
//

#import "ZENActionSheet.h"

@interface ZENActionSheet ()

@property (nonatomic, weak) id <UIActionSheetDelegate> externalDelegate;
@property (nonatomic, strong) NSMutableDictionary *actionsPerIndex;

@end


@implementation ZENActionSheet


- (id)initWithTitle:(NSString *)title
{
	self = [super initWithTitle:title delegate:(id)self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    
	if (self)
	{
		_actionsPerIndex = [[NSMutableDictionary alloc] init];
	}
    
	return self;
}

#pragma mark Properties

- (id <UIActionSheetDelegate>)delegate
{
	return self.externalDelegate;
}


- (void)setDelegate:(id<UIActionSheetDelegate>)delegate
{
	if (delegate == (id)self) {
		[super setDelegate:(id)self];
        
	}	else if (delegate == nil) {
		[super setDelegate:nil];
		self.externalDelegate = nil;
        
	} else {
		self.externalDelegate = delegate;
	}
}


#pragma UIActionSheetDelegate (forwarded)

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
	[self.externalDelegate actionSheetCancel:actionSheet];
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
	[self.externalDelegate willPresentActionSheet:actionSheet];
}

- (void)didPresentActionSheet:(UIActionSheet *)actionSheet
{
	[self.externalDelegate didPresentActionSheet:actionSheet];
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	[self.externalDelegate actionSheet:actionSheet willDismissWithButtonIndex:buttonIndex];
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	NSNumber *key = @(buttonIndex);
    
	ZENActionSheetBlock block = self.actionsPerIndex[key];
    
	if (block)
	{
		block();
	}
    
	[self.externalDelegate actionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
}

- (NSInteger)addButtonWithTitle:(NSString *)title block:(ZENActionSheetBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title];
    
	if (block)
	{
		NSNumber *key = @(retIndex);
		self.actionsPerIndex[key] = [block copy];
	}
    
	return retIndex;
}

- (NSInteger)addDestructiveButtonWithTitle:(NSString *)title block:(ZENActionSheetBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title block:block];
	[self setDestructiveButtonIndex:retIndex];
    
	return retIndex;
}

- (NSInteger)addCancelButtonWithTitle:(NSString *)title block:(ZENActionSheetBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title block:block];
	[self setCancelButtonIndex:retIndex];
    
	return retIndex;
}

@end
