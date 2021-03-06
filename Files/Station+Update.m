//
//  Station+Update.m
//  Bicyclette
//
//  Created by Nicolas on 14/12/12.
//  Copyright (c) 2012 Nicolas Bouilleaud. All rights reserved.
//

#import "Station+Update.h"
#import "BicycletteCity+Update.h"
#import "DataUpdater.h"
#import "_StationParse.h"

#pragma mark -

@interface Station (UpdatePrivate)<DataUpdaterDelegate>
@end

@implementation Station (Update)
static char kStation_associatedUpdaterKey;
- (DataUpdater*) updater { return objc_getAssociatedObject(self, &kStation_associatedUpdaterKey); }
- (void) setUpdater:(DataUpdater*)updater_ { objc_setAssociatedObject(self, &kStation_associatedUpdaterKey, updater_, OBJC_ASSOCIATION_RETAIN); }

static char kStation_associatedCompletionBlockKey;
- (void(^)(NSError*)) completionBlock { return objc_getAssociatedObject(self, &kStation_associatedCompletionBlockKey); }
- (void) setCompletionBlock:(void(^)(NSError*))completionBlock_ { objc_setAssociatedObject(self, &kStation_associatedCompletionBlockKey, completionBlock_, OBJC_ASSOCIATION_COPY); }

static char kStation_associatedQueuedforUpdateKey;
- (BOOL) queuedForUpdate { return [objc_getAssociatedObject(self, &kStation_associatedQueuedforUpdateKey) boolValue]; }
- (void) setQueuedForUpdate:(BOOL)queuedForUpdate_ { objc_setAssociatedObject(self, &kStation_associatedQueuedforUpdateKey, [NSNumber numberWithBool:queuedForUpdate_], OBJC_ASSOCIATION_RETAIN); }

- (BOOL) updating
{
    return self.updater!=nil;
}

- (void) becomeStale
{
    [self willChangeValueForKey:@"statusDataIsFresh"];
    [self didChangeValueForKey:@"statusDataIsFresh"];
    [[NSNotificationCenter defaultCenter] postNotificationName:StationStatusDidBecomeStaleNotificiation object:self];
}

- (BOOL) statusDataIsFresh
{
    NSTimeInterval stalenessInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:@"StationStatusStalenessInterval"];
    return self.status_date && [[NSDate date] timeIntervalSinceDate:self.status_date] < stalenessInterval;
}

#pragma mark -

- (void) updateWithCompletionBlock:(void (^)(NSError *))completion_
{
    NSAssert([self.city canUpdateIndividualStations],nil);
    
    if(self.updating)
    {
        if(completion_)
            completion_(nil);
        return;
    }

    if([[NSDate date] timeIntervalSinceDate:self.status_date] < [[NSUserDefaults standardUserDefaults] doubleForKey:@"DataUpdaterDelayBetweenQueues"])
    {
        if(completion_)
            completion_(nil);
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(becomeStale) object:nil];
    self.completionBlock = completion_;
    self.updater = [[DataUpdater alloc] initWithURLStrings:@[[self.city detailsURLStringForStation:self]] delegate:self];
}

@end

@implementation Station (UpdatePrivate)

- (void) updater:(DataUpdater *)updater didFailWithError:(NSError *)error
{
    self.updater = nil;
    if (self.completionBlock)
        self.completionBlock(error);
    self.completionBlock = nil;
}

- (void) updaterDidFinishWithNoNewData:(DataUpdater *)updater
{
    self.updater = nil;
    if (self.completionBlock)
        self.completionBlock(nil);
    self.completionBlock = nil;
}

- (void) updater:(DataUpdater *)updater finishedWithNewDataChunks:(NSDictionary *)datas
{
    [self.city performUpdates:^(NSManagedObjectContext *updateContext) {
        Station * station = (Station*)[updateContext objectWithID:self.objectID];
        
        Class parsingClass = [station.city stationStatusParsingClass];
        NSAssert(parsingClass, nil);
        for (NSData * data in [datas allValues]) {
            NSDictionary * attributes = [parsingClass stationAttributesWithData:data];
            [self.city setStation:station attributes:attributes];
        }
    } saveCompletion:^(NSNotification *contextDidSaveNotification) {
        __unused NSManagedObject* updatedObject = [contextDidSaveNotification.userInfo[NSUpdatedObjectsKey] anyObject];
        NSAssert(updatedObject==nil || [updatedObject.objectID isEqual:self.objectID], nil);
        self.updater = nil;
        if(self.completionBlock)
            self.completionBlock(nil);
        self.completionBlock = nil;
    }];
    
    [self performSelector:@selector(becomeStale) withObject:nil afterDelay:[[NSUserDefaults standardUserDefaults] doubleForKey:@"StationStatusStalenessInterval"]];
}

@end

NSString * const StationStatusDidBecomeStaleNotificiation = @"StationStatusDidBecomeStaleNotificiation";
