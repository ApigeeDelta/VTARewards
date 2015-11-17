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

@interface IXBeaconManager () <KTKLocationManagerDelegate>

@property (strong,nonatomic) KTKLocationManager *locationManager;

@property (nonatomic, strong) NSArray *regionsToMonitor;

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
    [self.delegate beaconManagerEnteredRegion:self];
}

-(void)locationManager:(KTKLocationManager *)locationManager didExitRegion:(KTKRegion *)region
{
    [self.delegate beaconManagerExitedRegion:self];
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
