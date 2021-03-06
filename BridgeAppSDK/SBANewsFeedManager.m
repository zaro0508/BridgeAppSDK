//
//  SBANewsFeedManager.m
//  BridgeAppSDK
//
// Copyright © 2016 Sage Bionetworks. All rights reserved.
// Copyright (c) 2015, Apple Inc.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//


#import "SBANewsFeedManager.h"
#import "SBANewsFeedParser.h"
#import "SBALog.h"
#import <BridgeAppSDK/BridgeAppSDK-Swift.h>

NSString * const SBANewsFeedUpdateNotificationKey = @"SBANewsFeedUpdateNotification";

static NSString * const kAPCReadPostsKey = @"ReadPostsKey";
static NSString * const kAPCBlogUrlKey   = @"BlogUrlKey";

@interface SBANewsFeedManager()

@property (nonatomic, strong) SBANewsFeedParser *feedParser;

@property (nonatomic, strong) NSArray *readPosts;

@end

@implementation SBANewsFeedManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        id <SBAAppInfoDelegate> appDelegate = (id <SBAAppInfoDelegate>)[[UIApplication sharedApplication] delegate];
        NSString *urlString = [[appDelegate bridgeInfo] newsfeedURLString];
        _feedParser = [[SBANewsFeedParser alloc] initWithFeedURL:[NSURL URLWithString:urlString]];
        
        NSString *savedBlogUrl = [[NSUserDefaults standardUserDefaults] stringForKey:kAPCBlogUrlKey];
        
        //Clear read links if blog URL has changed.
        if (![savedBlogUrl isEqualToString:urlString]) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAPCReadPostsKey];
            
            [[NSUserDefaults standardUserDefaults] setObject:urlString forKey:kAPCBlogUrlKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
    }
    return self;
}

/**********************************/
#pragma mark - Public methods
/**********************************/

- (void)fetchFeedWithCompletion:(SBANewsFeedManagerCompletionBlock)completion
{
    __weak typeof(self) weakSelf = self;
    
    [self.feedParser fetchFeedWithCompletion:^(NSArray *results, NSError *error) {
        
        __strong typeof(self) strongSelf = weakSelf;
        
        strongSelf.feedPosts = results;
        
        SBALogError2(error);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(results, error);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SBANewsFeedUpdateNotificationKey object:self];
        });
    }];
}

- (BOOL)hasUserReadPostWithURL:(NSString *)postURL
{
    return [self.readPosts containsObject:postURL];
}

- (void)userDidReadPostWithURL:(NSString *)postURL
{
    if (![self.readPosts containsObject:postURL]) {
        NSMutableArray *readPosts = [[NSMutableArray alloc] initWithArray:self.readPosts];
        [readPosts addObject:postURL];
        self.readPosts = [NSArray arrayWithArray:readPosts];
        [[NSNotificationCenter defaultCenter] postNotificationName:SBANewsFeedUpdateNotificationKey object:self];
    }
}

- (NSUInteger)unreadPostsCount
{
    NSUInteger totalCount = (self.feedPosts) ? [self.feedPosts count] : 0;
    NSUInteger readCount = (self.readPosts) ? MIN([self.readPosts count], totalCount)  : 0;
    
    NSUInteger unreadCount = totalCount - readCount;
    
    return unreadCount;
}

/**********************************/
#pragma mark - Getter/Setter methods
/**********************************/

- (NSArray *)readPosts
{
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kAPCReadPostsKey];
}

- (void)setReadPosts:(NSArray *)readPosts
{
    [[NSUserDefaults standardUserDefaults] setObject:readPosts forKey:kAPCReadPostsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
