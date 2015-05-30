//
//  ZENActionSheet.h
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 28/10/12.
//  Copyright (c) 2012 Frédéric ADDA. All rights reserved.
//

/* Subclass of UIActionSheet designed to allow the use of blocks instead of delegate methods
 
 Compared to the standard UIActionSheet, there is no such a method as
 initWithTitle:delegate:cancelButtonTitle:destructiveButtonTitle:otherButtonTitles:
 
 This ZENActionSheet has to be initialized with initWithTitle:, and buttons added with methods:
 - addButtonWithTitle:block:
 - addDestructiveButtonWithTitle:block:
 - addCancelButtonWithTitle:block:

 The main advantage is that the actions caused by tapping on a button don't need to be called in a separate delegate method such as actionSheet:didDismissWithButtonIndex:, but rather directly within a block.
 
 Otherwise, they retain the UI of standard UIActionSheet.
 */

@import UIKit;

typedef void (^ZENActionSheetBlock)(void);

@interface ZENActionSheet : UIActionSheet

- (id)initWithTitle:(NSString *)title;
- (NSInteger)addButtonWithTitle:(NSString *)title block:(ZENActionSheetBlock)block;
- (NSInteger)addDestructiveButtonWithTitle:(NSString *)title block:(ZENActionSheetBlock)block;
- (NSInteger)addCancelButtonWithTitle:(NSString *)title block:(ZENActionSheetBlock)block;

@end
