//
//  FacebookManager.m
//  Pandemos
//
//  Created by Michael Sevy on 3/22/16.
//  Copyright © 2016 Michael Sevy. All rights reserved.
//

#import "FacebookManager.h"
#import "FacebookNetwork.h"
#import "FacebookBuilder.h"
#import "User.h"

@implementation FacebookManager

+ (id)sharedSettings
{
    static FacebookManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}

-(id)init
{
    self = [super init];

    if(self)
    {
        [self allUsers];
        [self pendingMatches];
        [self matchingUsers];
    }

    return self;
}

-(void)loadParsedFacebookThumbnails
{
    [self.facebookNetworker loadFacebookThumbnails:^(BOOL success, NSError *error) {

        if (success)
        {
            NSLog(@"loaded thumb data");
        }
        else
        {
            NSLog(@"failed to load thumb data, error: %@", error);
        }
    }];
}

-(void)loadParedFBPhotoAlbums
{
    [self.facebookNetworker loadFacebookPhotoAlbums:^(BOOL success, NSError *error) {

        if (success)
        {
            NSLog(@"loaded FB Photo albums");
        }
        else
        {
            NSLog(@"failed to load FB Photo albums");
        }
    }];
}


#pragma mark -- FACEBOOK NETWORK DELEGATE
-(void)receivedFBThumbnail:(NSDictionary *)facebookThumbnails
{
    NSError *error = nil;
    NSArray *thumbnails = [FacebookBuilder parseThumbnailData:facebookThumbnails withError:error];

    if (!error)
    {
        [self.delegate didReceiveParsedThumbnails:thumbnails];
    }
    else
    {
        [self.delegate failedToReceiveParsedThumbs:error];
    }
}

-(void)failedToFetchFBThumbs:(NSError *)error
{
    [self.delegate failedToReceiveParsedThumbs:error];
}

-(void)receivedFBThumbPaing:(NSDictionary *)facebookThumbPaging
{
    NSError *error = nil;
    NSArray *thumbPages = [FacebookBuilder parseThumbnailPaging:facebookThumbPaging withError:error];

    if (!error)
    {
        [self.delegate didReceiveParsedThumbPaging:thumbPages];
    }
    else
    {
        [self.delegate failedToReceiveParsedThumbPaging:error];
    }
}

-(void)failedToFetchFBThumbPaging:(NSError *)error
{
    [self.delegate failedToReceiveParsedThumbPaging:error];
}

-(void)receivedFBPhotoAlbums:(NSDictionary *)facebookAlbums
{
    NSError *error = nil;
    NSArray *photoAlbums = [FacebookBuilder parsePhotoAlbums:facebookAlbums withError:error];

    if (!error)
    {
        [self.delegate didReceiveParsedAlbumList:photoAlbums];
    }
    else
    {
        [self.delegate failedToReceiveParsedPhotoAlbums:error];
    }
}

-(void)failedToFetchFBPhotoAlbums:(NSError *)error
{
    [self.delegate failedToReceiveParsedPhotoAlbums:error];
}

#pragma mark -- HELPERS
-(NSMutableArray *)allUsers
{
    if (!_allUsers)
    {
        _allUsers = [NSMutableArray new];
    }
    return _allUsers;
}

-(NSMutableArray *)pendingMatches
{
    if (!_pendingMatches)
    {
        _pendingMatches = [NSMutableArray new];
    }
    return _pendingMatches;
}

-(NSMutableArray *)matchingUsers
{
    if (!_matchingUsers)
    {
        _matchingUsers = [NSMutableArray new];
    }
    return _matchingUsers;
}
@end