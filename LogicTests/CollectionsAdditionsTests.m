//
//  CollectionsAdditionsTests.m
//  Bicyclette
//
//  Created by Nicolas Bouilleaud on 17/11/12.
//  Copyright (c) 2012 Nicolas Bouilleaud. All rights reserved.
//

#import "CollectionsAdditions.h"

@interface NSArrayAdditionsTests : SenTestCase
@end

@implementation NSArrayAdditionsTests

- (void) testFirstObjectWithValue
{
    NSArray * testdata = (@[
                          @{@"key" : @"v", @"id": @1},
                          @{@"key" : @"a", @"id": @2},
                          @{@"key" : @"l", @"id": @3},
                          @{@"key" : @"u", @"id": @4},
                          @{@"key" : @"e", @"id": @5},
                          ]);
    
    STAssertEqualObjects([[testdata firstObjectWithValue:@"a" forKeyPath:@"key"] objectForKey:@"id"], @2, nil);
}

- (void) testFilteredArrayWithValueForKey
{
    NSArray * testdata = (@[
                          @{@"key" : @"b", @"id": @1},
                          @{@"key" : @"a", @"id": @2},
                          @{@"key" : @"b", @"id": @3},
                          @{@"key" : @"a", @"id": @4},
                          @{@"key" : @"b", @"id": @5},
                          ]);
    
    NSArray * expectedResult = (@[
                                @{@"key" : @"b", @"id": @1},
                                @{@"key" : @"b", @"id": @3},
                                @{@"key" : @"b", @"id": @5},
                                ]);
    STAssertEqualObjects([testdata filteredArrayWithValue:@"b" forKeyPath:@"key"], expectedResult, nil);
}

@end

@interface NSSetAdditionsTests : SenTestCase
@end

@implementation NSSetAdditionsTests

- (void) testAnyObjectWithValue
{
    NSSet * testdata = [NSSet setWithArray:@[
                        @{@"key" : @"v", @"id": @1},
                        @{@"key" : @"a", @"id": @2},
                        @{@"key" : @"l", @"id": @3},
                        @{@"key" : @"u", @"id": @4},
                        @{@"key" : @"e", @"id": @5},
                        ]];
    
    STAssertEqualObjects([[testdata anyObjectWithValue:@"a" forKeyPath:@"key"] objectForKey:@"id"], @2, nil);
}

- (void) testFilteredSetWithValueForKey
{
    NSSet * testdata = [NSSet setWithArray:@[
                        @{@"key" : @"b", @"id": @1},
                        @{@"key" : @"a", @"id": @2},
                        @{@"key" : @"b", @"id": @3},
                        @{@"key" : @"a", @"id": @4},
                        @{@"key" : @"b", @"id": @5},
                        ]];
    
    NSSet * expectedResult = [NSSet setWithArray:@[
                              @{@"key" : @"b", @"id": @1},
                              @{@"key" : @"b", @"id": @3},
                              @{@"key" : @"b", @"id": @5},
                              ]];
    STAssertEqualObjects([testdata filteredSetWithValue:@"b" forKeyPath:@"key"], expectedResult, nil);
}

@end
