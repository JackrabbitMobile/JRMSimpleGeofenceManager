//
//  JRMSimpleGeofenceManager.m
//
//  Created by Matt Wanninger on 8/6/15.
//  Copyright (c) 2015 Jackrabbit Mobile. All rights reserved.
//

#import "JRMSimpleGeofenceManager.h"

@interface JRMSimpleGeofenceManager ()

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSArray *allGeofences;
@property (nonatomic) unsigned long processingRegionStateCount;
@property (nonatomic) unsigned long processingMonitoringRegionCount;

@end

@implementation JRMSimpleGeofenceManager

// iOS gives you a maximum of 20 regions to monitor.
static const NSUInteger regionMonitoringLimit = 20;

+ (instancetype)sharedGeofenceManager
{
    static JRMSimpleGeofenceManager *geofenceManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        geofenceManager = [[self alloc] init];
    });
    return geofenceManager;
}

- (id)init
{
    if ((self = [super init])) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.processingRegionStateCount = 0;
        self.processingMonitoringRegionCount = 0;
    }
    return self;
}

#pragma mark - JRMGeofenceManager public methods

- (void)reloadGeofences {
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
            return;
        }
    }
    
    self.allGeofences = [self.dataSource geofencesForGeofenceManager:self];
    
    if (self.allGeofences.count > regionMonitoringLimit) {
        NSLog(@"JRMGeofenceManager: Warning - Trying to monitor %lu regions, but can only monitor a maximum of %lu regions.", self.allGeofences.count, regionMonitoringLimit);
    }
    
    for (CLRegion *region in [self.locationManager monitoredRegions]) {
        [self.locationManager stopMonitoringForRegion:region];
    }
    
    for (CLRegion *region in self.allGeofences) {
        self.processingMonitoringRegionCount++;
        [self.locationManager startMonitoringForRegion:region];
    }
}

- (void)requestStateForAllRegions {
    for (CLRegion *region in [self.locationManager monitoredRegions]) {
        [self requestRegionState:region];
    }
}

- (void)requestRegionState:(CLRegion*)region {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        while (self.processingMonitoringRegionCount > 0) {}
        self.processingRegionStateCount++;
        [self.locationManager requestStateForRegion:region];
    });
}

#pragma mark - JRMGeofenceManager private methods

- (void)failedProcessingGeofencesWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(geofenceManager:didFailWithError:)]) {
        if ([error isKindOfClass:[NSError class]]) {
            [self.delegate geofenceManager:self didFailWithError:error];
        }
        else {
            NSError *timeoutError = [NSError errorWithDomain:@"Geofence manager timed out" code:kCFURLErrorTimedOut userInfo:nil];
            [self.delegate geofenceManager:self didFailWithError:timeoutError];
        }
    }
    self.processingMonitoringRegionCount = 0;
    self.processingRegionStateCount = 0;
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    if ([CLLocationManager respondsToSelector:@selector(isMonitoringAvailableForClass:)]) {
        if (![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) { // Old iOS
            [self failedProcessingGeofencesWithError:error];
            return;
        }
    }
    
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        [self failedProcessingGeofencesWithError:error];
        return;
    }
    
    NSLog(@"Retry monitoring region %@", region.identifier);
    [manager performSelectorInBackground:@selector(startMonitoringForRegion:) withObject:region];
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    self.processingMonitoringRegionCount--;
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if ([self.delegate respondsToSelector:@selector(geofenceManager:didEnterGeofence:)]) {
        [self.delegate geofenceManager:self didEnterGeofence:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if ([self.delegate respondsToSelector:@selector(geofenceManager:didEnterGeofence:)]) {
        [self.delegate geofenceManager:self didExitGeofence:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        [self failedProcessingGeofencesWithError:error];
        return;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        [self reloadGeofences];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if (self.processingRegionStateCount > 0) {
        if (state == CLRegionStateInside) {
            if ([self.delegate respondsToSelector:@selector(geofenceManager:didEnterGeofence:)]) {
                [self.delegate geofenceManager:self didEnterGeofence:region];
            }
        } else if (state == CLRegionStateOutside) {
            if ([self.delegate respondsToSelector:@selector(geofenceManager:didExitGeofence:)]) {
                [self.delegate geofenceManager:self didExitGeofence:region];
            }
        }
        
        self.processingRegionStateCount--;
    }
}

@end