//
//  IXLocationTracker.m
//  IgniteEngineStarterKit
//
//  Created by Robert Walsh on 7/1/15.
//  Copyright (c) 2015 Apigee. All rights reserved.
//

#import "IXLocationTracker.h"

// LocationTracker Read Only Attributes
IX_STATIC_CONST_STRING kIXTripWaypoints = @"trip.waypoints";
IX_STATIC_CONST_STRING kIXTripStart = @"trip.start";
IX_STATIC_CONST_STRING kIXTripEnd = @"trip.end";

// Sound Events
IX_STATIC_CONST_STRING kIXStarted = @"started";
IX_STATIC_CONST_STRING kIXStopped = @"stopped";

// LocationTracker Functions
IX_STATIC_CONST_STRING kIXToggle = @"toggle";

@import CoreLocation;

@interface IXLocationTracker () <CLLocationManagerDelegate>

@property (nonatomic, assign) BOOL isTrackingLocation;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *waypoints;
@property (nonatomic, strong) NSDictionary *start;
@property (nonatomic, strong) NSDictionary *stop;
@property (nonatomic, strong) NSMutableDictionary *tripData;

@end

@implementation IXLocationTracker

-(void)buildView
{
    self.isTrackingLocation = NO;
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
    [self.locationManager setDistanceFilter:20.0f];

    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestAlwaysAuthorization];
    }
}

-(void)layoutControlContentsInRect:(CGRect)rect
{
}

-(void)applySettings
{
    [super applySettings];
}

-(void)applyFunction:(NSString *)functionName withParameters:(IXAttributeContainer *)parameterContainer
{
    if( [functionName isEqualToString:kIXToggle] ) {
        if( ![self isTrackingLocation] ) {
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
                [self.locationManager startUpdatingLocation];
                //clear all data before capturing new
                self.start = nil;
                self.stop = nil;
                self.waypoints = nil;
                self.tripData = nil;
                self.isTrackingLocation = YES;
                [[self actionContainer] executeActionsForEventNamed:kIXStarted];
            }
        } else {
            [self.locationManager stopUpdatingLocation];

            //remove last object from waypoints because it is already present in stop location
            [self.waypoints removeLastObject];
            if (self.tripData == nil) {
                self.tripData = [[NSMutableDictionary alloc]init];
            }
            [self.tripData setObject:self.start forKey:@"start"];
            [self.tripData setObject:self.waypoints forKey:@"waypoints"];
            [self.tripData setObject:self.stop forKey:@"stop"];
            self.isTrackingLocation = NO;
            [[self actionContainer] executeActionsForEventNamed:kIXStopped];
        }
    } else {
        [super applyFunction:functionName withParameters:parameterContainer];
    }
}

- (NSString *)toJSON:(id)object{
    if (object) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        NSString *jsonString = nil;
        if (! jsonData) {
            NSLog(@"Got an error: %@", error);
        } else {
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        return jsonString;
    } else {
        return @"";
    }
}


-(NSString *)getReadOnlyPropertyValue:(NSString *)propertyName
{
    NSString* returnString = nil;
    if( [propertyName isEqualToString:kIXTripWaypoints] ) {
        returnString = [self toJSON:[self tripData][@"waypoints"]];
    } else if( [propertyName isEqualToString:kIXTripStart]) {
        returnString = [self toJSON:[self tripData][@"start"]];
    } else if( [propertyName isEqualToString:kIXTripEnd] ) {
        returnString = [self toJSON:[self tripData][@"end"]];
    } else {
        returnString = [super getReadOnlyPropertyValue:propertyName];
    }
    return returnString;
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        if ( self.isTrackingLocation) {
            [self.locationManager startUpdatingLocation];
        }
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    if (self.waypoints == nil) {
        self.waypoints = [[NSMutableArray alloc]init];
    }

    //form dictionary from the first location object
    CLLocation *location = [locations objectAtIndex:0];
    NSDictionary *locationDict = @{@"latitude":[NSNumber numberWithDouble:location.coordinate.latitude],
                                   @"longitude":[NSNumber numberWithDouble:location.coordinate.longitude],
                                   @"timestamp":[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970] * 1000]};

    if (self.start == nil) {
        //capture the start location
        self.start = locationDict;
    }else{
        //capture waypoints
        [self.waypoints addObject:locationDict];
    }
    //every recent location is overwritten to the stop location
    self.stop = locationDict;
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"Location manager error: %@",error);
}

@end
