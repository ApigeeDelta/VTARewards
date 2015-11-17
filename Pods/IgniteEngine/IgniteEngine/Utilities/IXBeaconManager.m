//
//  IXBeaconManager.m
//  IgniteEngineStarterKit
//
//  Created by Robert Walsh on 10/7/15.
//  Copyright © 2015 Apigee. All rights reserved.
//

#import "IXBeaconManager.h"
#import "IXConstants.h"
#import "IXLocationManager.h"
#import "NSString+IXAdditions.h"
#import <KontaktSDK/KontaktSDK.h>

@import CoreLocation;

// Non attribute constants
IX_STATIC_CONST_STRING kIXWayPoints = @"waypoints";

@interface IXLocationManager ()

@property (nonatomic,strong) CLLocationManager* locationManager;

@end

@interface IXBeaconManager () <KTKLocationManagerDelegate,IXLocationManagerDelegate>

@property (strong,nonatomic) KTKLocationManager *locationManager;
@property (strong,nonatomic) IXLocationManager* locationTrackerManager;

@property (nonatomic, strong) NSArray *regionsToMonitor;
@property (nonatomic, strong) NSMutableArray *waypoints;
@property (nonatomic, strong) NSDictionary *start;
@property (nonatomic, strong) NSDictionary *stop;
@property (nonatomic, strong) NSMutableDictionary *tripData;
@property (nonatomic, assign) UIBackgroundTaskIdentifier locationTrackingTask;

@end

@implementation IXBeaconManager

-(void)dealloc
{
    [self.locationManager stopMonitoringBeacons];
    self.locationManager.delegate = nil;
    [self.locationTrackerManager stopTrackingLocation];
    self.locationTrackerManager.delegate = nil;
}

+(IXBeaconManager*)sharedManager
{
    static IXBeaconManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[IXBeaconManager alloc] init];
    });
    return sharedInstance;
}

-(instancetype)init
{
    self = [super init];
    if( self != nil )
    {
        self.locationManager = [[KTKLocationManager alloc]init];
        self.locationManager.delegate = self;

        self.locationTrackerManager = [[IXLocationManager alloc] init];
        [self.locationTrackerManager setDelegate:self];
        [self.locationTrackerManager.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [self.locationTrackerManager.locationManager setDistanceFilter:kCLDistanceFilterNone];
        [self.locationTrackerManager requestAccessToLocation];
    }
    return self;
}

-(void)startMonitoring
{
    if( [KTKLocationManager canMonitorBeacons] ) {
        [self.locationManager setRegions:self.regionsToMonitor];
        [self.locationManager startMonitoringBeacons];
    } else {
        NSLog(@"ERROR: Cannot monitor beacons.");
    }
}

-(void)stopMonitoring
{
    [self.locationManager stopMonitoringBeacons];
}

-(BOOL)canMonitorBeacons
{
    return [NSString ix_stringFromBOOL:[KTKLocationManager canMonitorBeacons]];
}

-(NSString*)tripDataString
{
    if( self.tripData != nil && [NSJSONSerialization isValidJSONObject:self.tripData] ) {
        NSError* err;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:self.tripData options:0 error:&err];
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return nil;
}

-(void)setRegionUUIDsToMonitor:(NSArray*)regionUUIDs
{
    NSMutableArray* regionsToMonitor = [NSMutableArray array];
    for( NSString* regionUUID in regionUUIDs ) {
        [regionsToMonitor addObject:[[KTKRegion alloc] initWithUUID:regionUUID]];
    }
    self.regionsToMonitor = regionsToMonitor;
}

- (void)locationManager:(KTKLocationManager *)locationManager didChangeState:(KTKLocationManagerState)state withError:(NSError *)error
{
    if (state == KTKLocationManagerStateFailed)
    {
        NSLog(@"Something went wrong with your Location Services settings. Check OS settings.");
    }
}

-(void)locationManager:(KTKLocationManager *)locationManager didEnterRegion:(KTKRegion *)region
{
    self.start = nil;
    self.stop = nil;
    self.waypoints = nil;
    self.tripData = nil;

    [self.locationTrackerManager.locationManager startMonitoringSignificantLocationChanges];
    [self.locationTrackerManager beginLocationTracking];

    [self.delegate beaconManagerEnteredRegion:self];
}

-(void)locationManager:(KTKLocationManager *)locationManager didExitRegion:(KTKRegion *)region
{
    [self.locationTrackerManager.locationManager stopMonitoringSignificantLocationChanges];
    [self.locationTrackerManager stopTrackingLocation];

    if (self.waypoints != nil) {
        [self.waypoints removeLastObject];
    }

    if (self.tripData == nil) {
        self.tripData = [[NSMutableDictionary alloc]init];
    }
    if (self.start!=nil) {
        [self.tripData setObject:self.start forKey:kIXStart];
    }
    if (self.waypoints!=nil) {
        [self.tripData setObject:self.waypoints forKey:kIXWayPoints];
    }
    if (self.stop!=nil) {
        [self.tripData setObject:self.stop forKey:kIXStop];
    }

    [self.delegate beaconManagerExitedRegion:self];
}

-(void)locationManagerAuthStatusChanged:(CLAuthorizationStatus)status;
{
    // Do stuff maybe?
}

-(void)locationManagerDidUpdateLocation:(CLLocation*)location
{
    self.locationTrackingTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.locationTrackingTask];
        self.locationTrackingTask = UIBackgroundTaskInvalid;
    }];

    NSNumber *timestamp = [NSNumber numberWithDouble:[location.timestamp timeIntervalSince1970]*1000];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setRoundingMode:NSNumberFormatterRoundHalfUp];
    [formatter setMaximumFractionDigits:0];

    NSDictionary *locationDict = @{@"lat":[NSNumber numberWithDouble:location.coordinate.latitude],
                                   @"lng":[NSNumber numberWithDouble:location.coordinate.longitude],
                                   @"timestamp":[formatter stringFromNumber:timestamp]};

    if (self.start == nil) {
        self.start = locationDict;
    } else {
        [self.waypoints addObject:locationDict];
    }
    self.stop = locationDict;
}

- (void)locationManager:(KTKLocationManager *)locationManager didRangeBeacons:(NSArray *)beacons
{
    NSLog(@"Ranged beacons count: %lu", (unsigned long)[beacons count]);
    [beacons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CLBeacon* beacon = (CLBeacon*)obj;
        NSLog(@"%d - major %d minor %d strength %d accuracy %f",idx,[beacon.major intValue],[beacon.minor intValue],beacon.rssi,beacon.accuracy);
    }];
}

@end
