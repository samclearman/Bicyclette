//
//  VelibModel.m
//  Bicyclette
//
//  Created by Nicolas on 09/10/10.
//  Copyright 2010 Nicolas Bouilleaud. All rights reserved.
//

#import "VelibModel.h"
#import "Station.h"
#import "Region.h"
#import "NSArrayAdditions.h"
#import "NSStringAdditions.h"
#import "NSObject+KVCMapping.h"

#import "DataUpdater.h"

/****************************************************************************/
#pragma mark -

@interface VelibModel () <DataUpdaterDelegate, NSXMLParserDelegate>
@property (nonatomic, strong) DataUpdater * updater;
@property BOOL updatingXML;
// -
@property (nonatomic, strong) NSDictionary * stationsHardcodedFixes;
@property (readwrite, nonatomic, strong) CLRegion * hardcodedLimits;
// -
@property (nonatomic, readwrite) MKCoordinateRegion regionContainingData;
// - 
@property (nonatomic, strong) NSMutableDictionary * parsing_regionsByCodePostal;
@end

/****************************************************************************/
#pragma mark -

@implementation VelibModel

@synthesize updater;
@synthesize updatingXML;
@synthesize stationsHardcodedFixes;
@synthesize hardcodedLimits;
@synthesize regionContainingData;
@synthesize parsing_regionsByCodePostal;

- (id)init {
    self = [super init];
    if (self) {
        self.updater = [DataUpdater updaterWithDelegate:self];
    }
    return self;
}

/****************************************************************************/
#pragma mark Hardcoded Fixes

- (NSDictionary*) hardcodedFixes
{
    return [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"VelibHardcodedFixes" ofType:@"plist"]];
}

- (NSDictionary*) stationsHardcodedFixes
{
	if(nil==stationsHardcodedFixes)
	{
		self.stationsHardcodedFixes = [self.hardcodedFixes objectForKey:@"stations"];
	}
	return stationsHardcodedFixes;
}

- (CLRegion*) hardcodedLimits
{
	if( nil==hardcodedLimits )
	{
        NSDictionary * dict = [self.hardcodedFixes objectForKey:@"limits"];
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([[dict objectForKey:@"latitude"] doubleValue], [[dict objectForKey:@"longitude"] doubleValue]);
        CLLocationDistance distance = [[dict objectForKey:@"distance"] doubleValue];
        self.hardcodedLimits = [[CLRegion alloc] initCircularRegionWithCenter:coord radius:distance identifier:NSStringFromClass([self class])];
	}
	return hardcodedLimits;
}

/****************************************************************************/
#pragma mark Parsing

- (NSTimeInterval) refreshIntervalForUpdater:(DataUpdater *)updater
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:@"DatabaseReloadInterval"];
}

- (NSURL*) urlForUpdater:(DataUpdater *)updater
{
    return [NSURL URLWithString:kVelibStationsListURL];    
}
- (NSString*) knownDataSha1ForUpdater:(DataUpdater*)updater
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"Database_XML_SHA1"];
}

- (void) setUpdater:(DataUpdater*)updater knownDataSha1:(NSString*)sha1
{
    [[NSUserDefaults standardUserDefaults] setObject:sha1 forKey:@"Database_XML_SHA1"];
}

- (NSDate*) dataDateForUpdater:(DataUpdater*)updater
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"DatabaseCreateDate"];
}

- (void) setUpdater:(DataUpdater*)updater dataDate:(NSDate*)date
{
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:@"DatabaseCreateDate"];
}

- (void) updaterDidFinish:(DataUpdater*)updater
{
    self.updater = nil;
}

- (void) updater:(DataUpdater *)updater didFailWithError:(NSError *)error
{
    // No specific error handling
    self.updater = nil;
}

- (void) updater:(DataUpdater*)updater receivedUpdatedData:(NSData*)xml
{
	self.updatingXML = YES;
    
	NSError * requestError = nil;
	
	// Remove old stations and regions
	NSFetchRequest * oldStationsRequest = [NSFetchRequest new];
	[oldStationsRequest setEntity:[Station entityInManagedObjectContext:self.moc]];
	NSArray * oldStations = [self.moc executeFetchRequest:oldStationsRequest error:&requestError];
	for (Station * oldStation in oldStations) {
		[self.moc deleteObject:oldStation];
	}
	
	// Parse
    self.parsing_regionsByCodePostal = [NSMutableDictionary dictionary];
	NSXMLParser * parser = [[NSXMLParser alloc] initWithData:xml];
	parser.delegate = self;
	[parser parse];
    
	// Compute regions coordinates
    [[self.parsing_regionsByCodePostal allValues] makeObjectsPerformSelector:@selector(setupCoordinates)];
    self.parsing_regionsByCodePostal = nil;

	// Save
	[self save];
	self.updatingXML = NO;
}

- (NSDictionary*) stationKVCMapping
{
    static NSDictionary * s_mapping = nil;
    if(nil==s_mapping)
        s_mapping = [[NSDictionary alloc] initWithObjectsAndKeys:
                     @"address",@"address",
                     @"bonus",@"bonus",
                     @"fullAddress",@"fullAddress",
                     @"name",@"name",
                     @"number",@"number",
                     @"open",@"open",

                     @"latitude",@"lat",
                     @"longitude",@"lng",
                     nil];
    
    return s_mapping;
}


- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if([elementName isEqualToString:@"marker"])
	{
		Station * station = [Station insertInManagedObjectContext:self.moc];
		[station setValuesForKeysWithDictionary:attributeDict withMappingDictionary:self.stationKVCMapping]; // Yay!
		NSDictionary * fixes = [self.stationsHardcodedFixes objectForKey:station.number];
		if(fixes)
		{
			NSLog(@"using hardcoded fixes for %@.\n\tReceived Data : %@.\n\tFixes : %@",station.number, attributeDict, fixes);
			[station setValuesForKeysWithDictionary:fixes withMappingDictionary:self.stationKVCMapping]; // Yay! again
		}
        
        // Setup region
        if([station.fullAddress hasPrefix:station.address])
        {
            NSString * endOfAddress = [station.fullAddress stringByDeletingPrefix:station.address];
            endOfAddress = [endOfAddress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString * lCodePostal = nil;
            if(endOfAddress.length>=5)
                lCodePostal = [endOfAddress substringToIndex:5];
            if(nil==lCodePostal || [lCodePostal isEqualToString:@"75000"])
            {
                unichar firstChar = [station.number characterAtIndex:0];
                switch (firstChar) {
                    case '0': case '1':				// Paris
                        lCodePostal = [NSString stringWithFormat:@"750%@",[station.number substringToIndex:2]];
                        break;
                    case '2': case '3': case '4':	// Banlieue
                        lCodePostal = [NSString stringWithFormat:@"9%@0",[station.number substringToIndex:3]];
                        break;
                    default:						// Stations Mobiles et autres bugs
                        lCodePostal = [fixes objectForKey:@"codePostal"];
                        if(nil==lCodePostal)		// Dernier recours
                            lCodePostal = @"75000";
                        break;
                }
                
                NSLog(@"endOfAddress \"%@\" trop court, %@, trouvé %@",endOfAddress, station.name, lCodePostal);
            }
            NSAssert1([lCodePostal rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location == NSNotFound,@"codePostal %@ contient des caractères invalides",lCodePostal);
            
            // Keep regions in an array locally, to avoid fetching a Region for every Station parsed.
            Region * region = [self.parsing_regionsByCodePostal objectForKey:lCodePostal];
            if(nil==region)
            {
                region = [Region insertInManagedObjectContext:self.moc];
                [self.parsing_regionsByCodePostal setObject:region forKey:lCodePostal];
                region.number = lCodePostal;
                NSString * cityName = [[[endOfAddress stringByDeletingPrefix:region.number]
                                        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                       capitalizedString];
                if([lCodePostal hasPrefix:@"75"])
                    region.name = [NSString stringWithFormat:@"%@ %@",cityName,[[lCodePostal substringFromIndex:3] stringByDeletingPrefix:@"0"]];
                else
                    region.name = cityName;
            }
            station.region = region;
        }
        else
        {
            NSLog(@"full address \"%@\" does not begin with address \"%@\"", station.fullAddress, station.address);
            NSLog(@"Invalid data : %@",attributeDict);
            [self.moc deleteObject:station];
        }
    }
}

/****************************************************************************/
#pragma mark Coordinates

- (MKCoordinateRegion) regionContainingData
{
	if(regionContainingData.center.latitude == 0 &&
	   regionContainingData.center.longitude == 0 &&
	   regionContainingData.span.latitudeDelta == 0 &&
	   regionContainingData.span.longitudeDelta == 0 )
	{
		NSFetchRequest * regionsRequest = [NSFetchRequest new];
		[regionsRequest setEntity:[Region entityInManagedObjectContext:self.moc]];
		NSError * requestError = nil;
		NSArray * regions = [self.moc executeFetchRequest:regionsRequest error:&requestError];
        
		NSNumber * minLat = [regions valueForKeyPath:@"@min.minLatitude"];
		NSNumber * maxLat = [regions valueForKeyPath:@"@max.maxLatitude"];
		NSNumber * minLng = [regions valueForKeyPath:@"@min.minLongitude"];
		NSNumber * maxLng = [regions valueForKeyPath:@"@max.maxLongitude"];
		
		CLLocationCoordinate2D center;
		center.latitude = ([minLat doubleValue] + [maxLat doubleValue]) / 2.0f;
		center.longitude = ([minLng doubleValue] + [maxLng doubleValue]) / 2.0f; // This is very wrong ! Do I really need a if?
		MKCoordinateSpan span;
		span.latitudeDelta = fabs([minLat doubleValue] - [maxLat doubleValue]);
		span.longitudeDelta = fabs([minLng doubleValue] - [maxLng doubleValue]);
		self.regionContainingData = MKCoordinateRegionMake(center, span);
	}
	return regionContainingData;
}

@end

/****************************************************************************/
#pragma mark -

@implementation  NSManagedObjectContext (AssociatedModel)
- (VelibModel *) model
{
    return (VelibModel*) self.coreDataManager;
}
@end