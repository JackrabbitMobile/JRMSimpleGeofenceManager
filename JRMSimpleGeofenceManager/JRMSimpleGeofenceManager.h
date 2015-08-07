//
//  JRMSimpleGeofenceManager.h
//
//  Created by Matt Wanninger on 8/6/15.
//  Copyright (c) 2015 Jackrabbit Mobile. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@class JRMSimpleGeofenceManager;

@protocol JRMSimpleGeofenceManagerDataSource <NSObject>

@required
- (NSArray *)geofencesForGeofenceManager:(JRMSimpleGeofenceManager *)geofenceManager;

@end

@protocol JRMSimpleGeofenceManagerDelegate <NSObject>

@optional
- (void)geofenceManager:(JRMSimpleGeofenceManager *)geofenceManager didEnterGeofence:(CLRegion *)geofence;
- (void)geofenceManager:(JRMSimpleGeofenceManager *)geofenceManager didExitGeofence:(CLRegion *)geofence;
- (void)geofenceManager:(JRMSimpleGeofenceManager *)geofenceManager didFailWithError:(NSError *)error;

@end

@interface JRMSimpleGeofenceManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, weak) id<JRMSimpleGeofenceManagerDelegate> delegate;
@property (nonatomic, weak) id<JRMSimpleGeofenceManagerDataSource> dataSource;

+ (instancetype)sharedGeofenceManager;

- (void)reloadGeofences;
- (void)requestRegionState:(CLRegion*)region;

@end
