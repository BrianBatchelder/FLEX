//
//  FLEXFileBrowserFileOperationController.m
//  Flipboard
//
//  Created by Daniel Rodriguez Troitino on 2/13/15.
//  Copyright (c) 2015 Flipboard. All rights reserved.
//

#import "FLEXFileBrowserFileOperationController.h"
#import <UIKit/UIKit.h>

@interface FLEXFileBrowserFileDeleteOperationController () <UIAlertViewDelegate>

@property (nonatomic, copy, readonly) NSString *path;

- (instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

@end

@implementation FLEXFileBrowserFileDeleteOperationController

@synthesize delegate = _delegate;

- (instancetype)init
{
    return [self initWithPath:nil];
}

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _path = path;
    }

    return self;
}

- (void)show
{
    BOOL isDirectory = NO;
    BOOL stillExists = [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDirectory];

    if (stillExists) {
        UIAlertView *deleteWarning = [[UIAlertView alloc]
                                      initWithTitle:[NSString stringWithFormat:@"Delete %@?", self.path.lastPathComponent]
                                      message:[NSString stringWithFormat:@"The %@ will be deleted. This operation cannot be undone", isDirectory ? @"directory" : @"file"]
                                      delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"Delete", nil];
        [deleteWarning show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"File Removed" message:@"The file at the specified path no longer exists." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        // Nothing, just cancel
    } else if (buttonIndex == alertView.firstOtherButtonIndex) {
        [[NSFileManager defaultManager] removeItemAtPath:self.path error:NULL];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.delegate fileOperationControllerDidDismiss:self];
}

@end

@interface FLEXFileBrowserFileRenameOperationController () <UIAlertViewDelegate>

@property (nonatomic, copy, readonly) NSString *path;

- (instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

@end

@implementation FLEXFileBrowserFileRenameOperationController

@synthesize delegate = _delegate;

- (instancetype)init
{
    return [self initWithPath:nil];
}

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _path = path;
    }

    return self;
}

- (void)show
{
    BOOL isDirectory = NO;
    BOOL stillExists = [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDirectory];

    if (stillExists) {
        UIAlertView *renameDialog = [[UIAlertView alloc]
                                     initWithTitle:[NSString stringWithFormat:@"Rename %@?", self.path.lastPathComponent]
                                     message:nil
                                     delegate:self
                                     cancelButtonTitle:@"Cancel"
                                     otherButtonTitles:@"Rename", nil];
        renameDialog.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *textField = [renameDialog textFieldAtIndex:0];
        textField.placeholder = @"New file name";
        textField.text = self.path.lastPathComponent;
        [renameDialog show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"File Removed" message:@"The file at the specified path no longer exists." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        // Nothing, just cancel
    } else if (buttonIndex == alertView.firstOtherButtonIndex) {
        NSString *newFileName = [alertView textFieldAtIndex:0].text;
        NSString *newPath = [[self.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
        [[NSFileManager defaultManager] moveItemAtPath:self.path toPath:newPath error:NULL];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.delegate fileOperationControllerDidDismiss:self];
}

@end

@interface FLEXFileBrowserFileEmailOperationController ()

@property (nonatomic, copy, readonly) NSString *path;

@end

@implementation FLEXFileBrowserFileEmailOperationController

@synthesize delegate = _delegate;

- (instancetype)init
{
    return [self initWithPath:nil];
}

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _path = path;
    }
    
    return self;
}

- (void)show
{
    BOOL isDirectory = NO;
    BOOL stillExists = [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDirectory];
    
    if (stillExists) {
        NSArray *to = [[NSBundle mainBundle] objectForInfoDictionaryKey:kFLEXEmailRecipientsKey];
        
        if (to && ([to count] > 0)) {
            NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
            NSString *subject = [NSString stringWithFormat:@"%@.FLEX: File: %@",appName,[self.path lastPathComponent]];
            NSString *body = [NSString stringWithFormat:@"The FLEX debugging tool within the app \"%@\" sent you the file named %@ at %@.\n",appName,self.path,[self getDateTimeStamp]];
            
            // create the MFMailComposeViewController
            MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
            composer.mailComposeDelegate = self;
            
            // set standard fields
            [composer setSubject:subject];
            [composer setMessageBody:body isHTML:NO];
            [composer setToRecipients:to];
            
            // add attachment
            NSData *fileData = [[NSFileHandle fileHandleForReadingAtPath:self.path] availableData];
            [composer addAttachmentData:fileData mimeType:@"application/octet-stream" fileName:[self.path lastPathComponent]];
            
            // present it on the screen - user just needs to press "Send"
            [(UIViewController *)self.delegate presentViewController:composer animated:YES completion:NULL];
        }
    } else {
        [[[UIAlertView alloc] initWithTitle:@"File Removed" message:@"The file at the specified path no longer exists." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate methods
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    // close the Mail Interface
    [(UIViewController *)self.delegate dismissViewControllerAnimated:YES completion:NULL];
}

static NSDateFormatter *dateFormatter = nil;

- (NSString *)getDateTimeStamp
{
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss zzz";
    }
    
    NSDate *now = [NSDate date];
    
    return [dateFormatter stringFromDate:now];
}

@end

