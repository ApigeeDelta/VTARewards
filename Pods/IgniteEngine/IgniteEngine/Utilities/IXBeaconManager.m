//
//  IXBeaconManager.m
//  IgniteEngineStarterKit
//
//  Created by Robert Walsh on 10/7/15.
//  Copyright © 2015 Apigee. All rights reserved.
//

#import "IXBeaconManager.h"
#import "IXConstants.h"

#import <KontaktSDK/KontaktSDK.h>

@import CoreLocation;

@interface IXBeaconManager () <KTKLocationManagerDelegate>

@property (strong,nonatomic) KTKLocationManager *locationManager;
@property (strong,nonatomic) NSArray* rangedBeacons;

@property (nonatomic,strong) CLBeacon* closestBeacon;

@end

@implementation IXBeaconManager

-(void)dealloc
{
    [self.locationManager stopMonitoringBeacons];
    self.locationManager.delegate = nil;
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
    }
    return self;
}

-(void)startMonitoring
{
    if( [KTKLocationManager canMonitorBeacons] ) {
        [self.locationManager startMonitoringBeacons];
    } else {
        DDLogError(@"ERROR: Cannot monitor beacons.");
    }
}

-(void)stopMonitoring
{
    [self.locationManager stopMonitoringBeacons];
}

-(BOOL)canMonitorBeacons
{
    return [KTKLocationManager canMonitorBeacons];
}

-(void)setRegionUUIDsToMonitor:(NSArray*)regionUUIDs
{
    NSMutableArray* regionsToMonitor = [NSMutableArray array];
    for( NSString* regionUUID in regionUUIDs ) {
        [regionsToMonitor addObject:[[KTKRegion alloc] initWithUUID:regionUUID]];
    }
    [self.locationManager setRegions:regionsToMonitor];
}

- (void)locationManager:(KTKLocationManager *)locationManager didChangeState:(KTKLocationManagerState)state withError:(NSError *)error
{
    if (state == KTKLocationManagerStateFailed)
    {
        DDLogError(@"Error: Something went wrong with your Location Services settings. Check OS settings.");
    }
}

-(void)locationManager:(KTKLocationManager *)locationManager didEnterRegion:(KTKRegion *)region
{
    [self.delegate beaconManagerEnteredRegion:self];
}

-(void)locationManager:(KTKLocationManager *)locationManager didExitRegion:(KTKRegion *)region
{
    [self.delegate beaconManagerExitedRegion:self];

    if( self.closestBeacon != nil && [self.closestBeacon.proximityUUID.UUIDString isEqualToString:region.uuid] ) {
        [self.delegate closestBeaconExited:self];
        self.closestBeacon = nil;
    }
}

-(CLBeacon*)determineClosestBeaconAndMonitor
{
    self.closestBeacon = self.rangedBeacons.firstObject;
    return self.closestBeacon;
}

- (void)locationManager:(KTKLocationManager *)locationManager didRangeBeacons:(NSArray *)beacons
{
    self.rangedBeacons = beacons;

    if( self.closestBeacon != nil ) {

        BOOL didFindBeaconStill = NO;
        for( CLBeacon* beacon in beacons )
        {
            didFindBeaconStill = [beacon.major isEqualToNumber:self.closestBeacon.major] && [beacon.minor isEqualToNumber:self.closestBeacon.minor];
        }

        if( !didFindBeaconStill ) {

            [self.delegate closestBeaconExited:self];
            self.closestBeacon = nil;
        }
    }

    NSLog(@"Ranged beacons count: %lu", (unsigned long)[beacons count]);
    [beacons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CLBeacon* beacon = (CLBeacon*)obj;
        DDLogInfo(@"%lu - major %d minor %d strength %ld accuracy %0.4f",(unsigned long)idx,[beacon.major intValue],[beacon.minor intValue],(long)beacon.rssi,beacon.accuracy);
    }];
}

@end
