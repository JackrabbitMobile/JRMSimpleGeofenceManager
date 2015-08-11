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

/**
 *  Implement this protocol method to return an array of CLRegions for JRMSimpleGeofenceManager to monitor.
 */
- (NSArray *)geofencesForGeofenceManager:(JRMSimpleGeofenceManager *)geofenceManager;

@end

@protocol JRMSimpleGeofenceManagerDelegate <NSObject>

@optional

/**
 *  Callback method for when the device has entered a geofence region.
 *
 *  @param geofenceManager The geoefence manager.
 *  @param geofence The CLRegion that was entered.
 */
- (void)geofenceManager:(JRMSimpleGeofenceManager *)geofenceManager didEnterGeofence:(CLRegion *)geofence;
/**
 *  Callback method for when the device has exited a geofence region.
 *
 *  @param geofenceManager The geoefence manager.
 *  @param geofence The CLRegion that was exited.
 */
- (void)geofenceManager:(JRMSimpleGeofenceManager *)geofenceManager didExitGeofence:(CLRegion *)geofence;
/**
 *  Callback method for when the device has entered a geofence region.
 *
 *  @param geofenceManager The geoefence manager.
 *  @param error The NSError containing the reason for geofence failure.
 */
- (void)geofenceManager:(JRMSimpleGeofenceManager *)geofenceManager didFailWithError:(NSError *)error;

@end

@interface JRMSimpleGeofenceManager : NSObject <CLLocationManagerDelegate>

/**
 *  Set this delegate to get region event callbacks.
 */
@property (nonatomic, weak) id<JRMSimpleGeofenceManagerDelegate> delegate;
/**
 *  Set the dataSource to provide the geofence manager with regions to monitor.
 */
@property (nonatomic, weak) id<JRMSimpleGeofenceManagerDataSource> dataSource;

/**
 *  Shared singleton instance.
 */
+ (instancetype)sharedGeofenceManager;

/**
 *  Reload geofences from data source.
 */
- (void)reloadGeofences;
/**
 *  Asynchronously requests the state for all monitored regions; this will call the JRMSimpleGeofenceManagerDelegate's geofenceManager:didEnterGeofence and geofenceManager:didExitGeofence for every monitored region.
 */
- (void)requestStateForAllRegions;
/**
 *  Asynchronously requests the state for one particular region; this will call the JRMSimpleGeofenceManagerDelegate's geofenceManager:didEnterGeofence and geofenceManager:didExitGeofence for the region.
 *
 *  @param region The CLRegion to get the state of.
 */
- (void)requestRegionState:(CLRegion*)region;

@end
