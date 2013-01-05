//
//  MelbourneBikeShareCity.m
//  Bicyclette
//
//  Created by Nicolas on 20/12/12.
//  Copyright (c) 2012 Nicolas Bouilleaud. All rights reserved.
//

#import "_CityWithJSONFlatListOfStations.h"
#import "BicycletteCity.mogenerated.h"

@interface MelbourneBikeShareCity : _CityWithJSONFlatListOfStations <CityWithJSONFlatListOfStations>
@end

@implementation MelbourneBikeShareCity

#pragma mark City Data Update

- (NSDictionary*) KVCMapping
{
    return @{@"id": StationAttributes.number,
             @"lat" : StationAttributes.latitude,
             @"long": StationAttributes.longitude,
             @"name" : StationAttributes.name,
             @"nbBikes" : StationAttributes.status_available,
             @"nbEmptyDocks" : StationAttributes.status_free,
             };
    
}

#pragma mark - override

- (NSArray*) stationAttributesArraysFromData:(NSData*)data
{
    // The JSON is invalid. Great.
    NSMutableString * str = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [str replaceOccurrencesOfString:@"\\x26" withString:@"&" options:0 range:NSMakeRange(0, [str length])];
    [str replaceOccurrencesOfString:@"\\'" withString:@"'" options:0 range:NSMakeRange(0, [str length])];

    return [super stationAttributesArraysFromData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}


@end
