
//
//  Style.h
//  Bicyclette
//
//  Created by Nicolas Bouilleaud on 29/06/12.
//  Copyright (c) 2012 Nicolas Bouilleaud. All rights reserved.
//

#import "UIColor+hsb.h"

#define kBicycletteBlue					[UIColor colorWithHue:0.611 saturation:1.000 brightness:0.600 alpha:1.000]
#define kRegionAnnotationViewSize 		40

#define kStationAnnotationViewSize		30

#define kAnnotationFrame1Color			[UIColor colorWithWhite:.95 alpha:.7]
#define kAnnotationFrame2Color			[UIColor colorWithWhite:.1 alpha:1]
#define kAnnotationFrame3Color			[UIColor colorWithWhite:.7 alpha:1]


#define kRegionColor					[UIColor colorWithHue:0 saturation:.02 brightness:1 alpha:1]

#define kRegionFrame1Color				[UIColor colorWithWhite:.95 alpha:1]
#define kRegionFrame2Color				[UIColor colorWithHue:0.01 saturation:1 brightness:.84 alpha:1]
#define kRegionFrame3Color				[UIColor colorWithWhite:.95 alpha:1]

#define kGoodValueColor					[UIColor colorWithRed:25/255.0f green:188/255.0f blue:63/255.0f alpha:1.0]
#define kWarningValueColor				[UIColor colorWithRed:221/255.0f green:170/255.0f blue:59/255.0f alpha:1.0]
#define kCriticalValueColor				[UIColor colorWithRed:229/255.0f green:0/255.0f blue:15/255.0f alpha:1.0]

#define kFenceBackgroundColor			[UIColor colorWithRed:47/255.0f green:112/255.0f blue:225/255.0f alpha:.5f]

#define kAnnotationDash1Color			[UIColor colorWithRed:47/255.0f green:112/255.0f blue:225/255.0f alpha:1.0]
#define kAnnotationDash2Color			[UIColor whiteColor]
#define kDashedBorderWidth				2
#define kDashLength						4

#define kUnknownValueColor				[UIColor colorWithHue:0 saturation:.02 brightness:.8 alpha:1]

#define kAnnotationTextColor			[UIColor colorWithHue:0 saturation:.02 brightness:1 alpha:1]

#define kAnnotationTitleTextColor		[kAnnotationTextColor colorWithBrightness:.07]
#define kAnnotationTitleShadowColor		[kAnnotationTextColor colorWithBrightness:1]
#define kAnnotationTitleFont			[UIFont fontWithName:@"AvenirNext-Bold" size:19]

#define kAnnotationDetailTextColor		[kAnnotationTextColor colorWithBrightness:.07]
#define kAnnotationDetailShadowColor	[kAnnotationTextColor colorWithBrightness:1]
#define kAnnotationDetailFont			[UIFont fontWithName:@"AvenirNext-Medium" size:16]

#define kAnnotationValueTextColor		[kAnnotationTextColor colorWithBrightness:.07]
#define kAnnotationValueTextColorAlt	[kAnnotationTextColor colorWithBrightness:.4]
#define kAnnotationValueShadowColor		[kAnnotationTextColor colorWithBrightness:1]
#define kAnnotationValueFont			[UIFont fontWithName:@"AvenirNext-Medium" size:18]
