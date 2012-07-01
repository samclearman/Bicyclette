//
//  LayerCache.m
//  Bicyclette
//
//  Created by Nicolas Bouilleaud on 24/06/12.
//  Copyright (c) 2012 Nicolas Bouilleaud. All rights reserved.
//

#import "LayerCache.h"
#import "Style.h"

#import "UIColor+hsb.h"


typedef enum {
    RoundedCornerNone = 0,
    RoundedCornerTopLeft = 1 << 0,
    RoundedCornerTopRight = 1 << 1,
    RoundedCornerTop = RoundedCornerTopLeft | RoundedCornerTopRight,
    RoundedCornerBottomLeft = 1 << 2,
    RoundedCornerBottomRight = 1 << 3,
    RoundedCornerBottom = RoundedCornerBottomLeft | RoundedCornerBottomRight,
    RoundedCornerAll = RoundedCornerTop | RoundedCornerBottom,
} RoundedCorners;


@implementation LayerCache
{
    NSMutableDictionary * _cache;
}

- (id)init
{
    self = [super init];
    if (self) {
        _cache = [NSMutableDictionary new];
    }
    return self;
}

- (CGLayerRef)sharedAnnotationViewBackgroundLayerWithSize:(CGSize)size
                                                    scale:(CGFloat)scale
                                                    shape:(BackgroundShape)shape
                                                baseColor:(UIColor*)baseColor
                                                    value:(NSString *)text
{
    NSString * key = [NSString stringWithFormat:@"background%d%d%f%d%@%@",
                      (int)size.width, (int)size.height, (float)scale, (int)shape,
                      [baseColor hsbString],text];

    NSLog(@"%d cached layers",(int)[_cache count]);
    
    CGLayerRef result = (__bridge CGLayerRef)[_cache objectForKey:key];
    if(result) return result;
    @synchronized(self)
    {
        if ([_cache objectForKey:key]==nil)
        {
            CGContextRef parentContext = UIGraphicsGetCurrentContext();
            
            CGLayerRef tempLayer = CGLayerCreateWithContext(parentContext, CGSizeMake(size.width*scale, size.height*scale), NULL);
            CGContextRef c = CGLayerGetContext(tempLayer);
            CGContextScaleCTM(c, scale, scale);

            CGRect rect = (CGRect){CGPointZero, size};

            // Draw gradient
            CGContextSaveGState(c);
            {
                CGFloat clipMargin = 2.5/scale;
                CGPathRef path = [self newShape:shape inRect:CGRectInset(rect, clipMargin, clipMargin)];
                [self clipWithPath:path inContext:c];
                CGPathRelease(path);

                [self drawSimpleGradientFromPoint1:CGPointZero toPoint2:CGPointMake(0, rect.size.height)
                                            color1:baseColor color2:[baseColor colorByAddingBrightness:-.2] inContext:c];
            }
            CGContextRestoreGState(c);

            // Draw border
            {
                CGContextSetLineWidth(c, 1/scale);
                CGPathRef path = [self newShape:shape inRect:CGRectInset(rect, 0.5/scale, 0.5/scale)];
                [self strokePath:path withColor:kAnnotationFrame1Color inContext:c];
                CGPathRelease(path);
                path = [self newShape:shape inRect:CGRectInset(rect, 1.5/scale, 1.5/scale)];
                [self strokePath:path withColor:kAnnotationFrame2Color inContext:c];
                CGPathRelease(path);
                path = [self newShape:shape inRect:CGRectInset(rect, 2.5/scale, 2.5/scale)];
                [self strokePath:path withColor:kAnnotationFrame3Color inContext:c];
                CGPathRelease(path);
            }

            // Draw text
            UIGraphicsPushContext(c);
            {
                 // Make c the current GraphicsContext
                [kAnnotationValueTextColor setFill];
                CGContextSetShadowWithColor(c, CGSizeMake(0, .5), 0, [kAnnotationValueShadowColor CGColor]);
                CGSize textSize = [text sizeWithFont:kAnnotationValueFont];
                CGPoint point = CGPointMake(CGRectGetMidX(rect)-textSize.width/2, CGRectGetMidY(rect)-textSize.height/2);
                [text drawAtPoint:point withFont:kAnnotationValueFont];
            }
            UIGraphicsPopContext();
            
            [_cache setObject:CFBridgingRelease(tempLayer) forKey:key];
        }
        return (__bridge CGLayerRef)[_cache objectForKey:key];
    }
}

- (void) clipWithPath:(CGPathRef)path inContext:(CGContextRef)c
{
    CGContextAddPath(c, path);
    CGContextClip(c);
}

- (void) strokePath:(CGPathRef)path withColor:(UIColor*)color inContext:(CGContextRef)c
{
    CGContextSetStrokeColorWithColor(c, color.CGColor);
    CGContextAddPath(c, path);
    CGContextDrawPath(c, kCGPathStroke);
}

- (void) drawSimpleGradientFromPoint1:(CGPoint)point1 toPoint2:(CGPoint)point2 color1:(UIColor*)color1 color2:(UIColor*)color2 inContext:(CGContextRef)c
{
    CGFloat locations[2] = {0,1};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                        (__bridge CFArrayRef)(@[(id)[color1 CGColor],
                                                                              (id)[color2 CGColor]]), locations);
    CGContextDrawLinearGradient(c, gradient, point1, point2, 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

- (CGPathRef) newShape:(BackgroundShape)shape inRect:(CGRect)rect
{
	CGPathRef path;
    switch (shape) {
        case BackgroundShapeRectangle: path = CGPathCreateWithRect(rect, &CGAffineTransformIdentity); break;
        case BackgroundShapeRoundedRect: path = [self newPath:rect roundedCorners:RoundedCornerAll cornerRadius:4]; break;
        case BackgroundShapeOval: path = CGPathCreateWithEllipseInRect(rect, &CGAffineTransformIdentity); break;
    }
    return path;
}

- (CGPathRef) newPath:(CGRect)rect roundedCorners:(RoundedCorners)corners cornerRadius:(CGFloat)cornerRadius
{
    CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect);
    CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect);

    CGMutablePathRef path = CGPathCreateMutable();

    CGPathMoveToPoint(path, NULL, minx, midy);

    if(corners & RoundedCornerTopLeft)
    {
        CGPathAddArcToPoint(path, NULL, minx, miny, midx, miny, cornerRadius);
    }
    else
    {
        CGPathAddLineToPoint(path, NULL, minx, miny);
        CGPathAddLineToPoint(path, NULL, midx, miny);
    }

    if(corners & RoundedCornerTopRight)
    {
        CGPathAddArcToPoint(path, NULL, maxx, miny, maxx, midy, cornerRadius);
    }
    else
    {
        CGPathAddLineToPoint(path, NULL, maxx, miny);
        CGPathAddLineToPoint(path, NULL, maxx, midy);
    }

    if(corners & RoundedCornerBottomRight)
    {
        CGPathAddArcToPoint(path, NULL, maxx, maxy, midx, maxy, cornerRadius);
    }
    else
    {
        CGPathAddLineToPoint(path, NULL, maxx, maxy);
        CGPathAddLineToPoint(path, NULL, midx, maxy);
    }

    if(corners & RoundedCornerBottomLeft)
    {
        CGPathAddArcToPoint(path, NULL, minx, maxy, minx, midy, cornerRadius);
    }
    else
    {
        CGPathAddLineToPoint(path, NULL, minx, maxy);
        CGPathAddLineToPoint(path, NULL, minx, midy);
    }

    CGPathCloseSubpath(path);

    return path;
}

@end
