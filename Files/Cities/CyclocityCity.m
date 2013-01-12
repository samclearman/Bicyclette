//
//  CyclocityCity.m
//  Bicyclette
//
//  Created by Nicolas on 12/12/12.
//  Copyright (c) 2012 Nicolas Bouilleaud. All rights reserved.
//

#import "CyclocityCity.h"
#import "BicycletteCity.mogenerated.h"
#import "NSStringAdditions.h"
#import "_StationParse.h"

@implementation CyclocityCity
#pragma mark Annotations

- (NSString*) titleForStation:(Station*)station
{
    NSString * title = station.name;
    title = [title stringByTrimmingZeros];
    title = [title stringByDeletingPrefix:station.number];
    title = [title stringByTrimmingWhitespace];
    title = [title stringByDeletingPrefix:@"-"];
    title = [title stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    title = [title stringByTrimmingWhitespace];
    title = [title capitalizedStringWithCurrentLocale];
    return title;
}

#pragma mark Stations Individual Data Updates

- (Class) stationStatusParsingClass { return [XMLSubnodesStationParse class]; }

#pragma mark City Data Updates

- (NSString*) stationElementName
{
    return @"marker";
}

- (NSDictionary*) KVCMapping
{
    return @{
             @"address" : StationAttributes.address,
             @"bonus" : StationAttributes.bonus,
             @"fullAddress" : StationAttributes.fullAddress,
             @"name" : StationAttributes.name,
             @"number" : StationAttributes.number,
             @"open" : StationAttributes.open,
             @"lat" : StationAttributes.latitude,
             @"lng" : StationAttributes.longitude,
             
             @"available" : StationAttributes.status_available,
             @"free" : StationAttributes.status_free,
             @"ticket": StationAttributes.status_ticket,
             @"total" : StationAttributes.status_total
             };
}

@end

