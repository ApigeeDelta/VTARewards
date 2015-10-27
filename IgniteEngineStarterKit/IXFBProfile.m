//
//  IXFBProfile.m
//  VTARewards
//
//  Created by Robert Walsh on 10/27/15.
//  Copyright © 2015 Apigee. All rights reserved.
//

/****************************************************************************
 The MIT License (MIT)
 Copyright (c) 2015 Apigee Corporation
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#import "IXFBProfile.h"

#import "IXAppManager.h"
#import "IXAttributeContainer.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

// IXFBProfile ReadOnly Attributes
IX_STATIC_CONST_STRING kIXName = @"name";
IX_STATIC_CONST_STRING kIXFirstName = @"firstName";
IX_STATIC_CONST_STRING kIXMiddleName = @"middleName";
IX_STATIC_CONST_STRING kIXLastName = @"lastName";
IX_STATIC_CONST_STRING kIXLinkURL = @"linkURL";

@interface IXFBProfile ()

@property (nonatomic,retain) FBSDKProfilePictureView* pictureView;

@end

@implementation IXFBProfile

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:FBSDKProfileDidChangeNotification
                                                  object:nil];
}

-(void)buildView
{
    [super buildView];

    [self setPictureView:[[FBSDKProfilePictureView alloc] initWithFrame:CGRectZero]];
    [[self pictureView] setPictureMode:FBSDKProfilePictureModeNormal];

    [[self contentView] addSubview:[self pictureView]];

    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookProfileDidUpdate:)
                                                 name:FBSDKProfileDidChangeNotification
                                               object:nil];
}

-(void)facebookProfileDidUpdate:(NSNotification*)notification
{
    [[self pictureView] setProfileID:[[FBSDKProfile currentProfile] userID]];
}

-(CGSize)preferredSizeForSuggestedSize:(CGSize)size
{
    return size;
}

-(void)layoutControlContentsInRect:(CGRect)rect
{
    [super layoutControlContentsInRect:rect];
    if( !CGRectEqualToRect(self.pictureView.frame, rect) ) {
        [[self pictureView] setFrame:rect];
        [[self pictureView] setNeedsImageUpdate];
    }
}

-(void)applySettings
{
    [super applySettings];

    [[self pictureView] setProfileID:[[FBSDKProfile currentProfile] userID]];
}

-(NSString *)getReadOnlyPropertyValue:(NSString *)propertyName
{
    if( [propertyName isEqualToString:kIXName] ) {
        return [[FBSDKProfile currentProfile] name];
    } else if( [propertyName isEqualToString:kIXFirstName] ) {
        return [[FBSDKProfile currentProfile] firstName];
    } else if( [propertyName isEqualToString:kIXMiddleName] ) {
        return [[FBSDKProfile currentProfile] middleName];
    } else if( [propertyName isEqualToString:kIXLastName] ) {
        return [[FBSDKProfile currentProfile] lastName];
    } else if( [propertyName isEqualToString:kIXLinkURL] ) {
        return [[[FBSDKProfile currentProfile] linkURL] absoluteString];
    } else {
        return [super getReadOnlyPropertyValue:propertyName];
    }
}

@end