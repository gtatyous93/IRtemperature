//
//  IntegratingViewController.m
//  TEXAS_INSTRUMENTS
//
//  Created by Ian Bacus on 2/28/16.
//  Copyright © 2016 Ian Bacus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IntegratingViewController.h"

/*
 This will be used for combining the data collected by the three modules: audio, motion, camera
 
 These modules need to be refadtored such that htey can be initialized with sampling frequencies and callbacks, where the callbacks should be inside of the integrating view controller
 
 */


@implementation IntegratingViewController

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
fromConnection:(AVCaptureConnection *)connection
{
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    CIImage *image = [_vidControl imageFromSampleBuffer:sampleBuffer];
    bool face_test = [_vidControl getFeatureWidth:image];
    //_axial_displacement = [self displacement_capture_reset]; //positive: closer, negative: farther
    //_delta_width = [[_widths objectAtIndex:0] floatValue] - [[_previous_widths objectAtIndex:0] floatValue];
    //_depth = [self calculate_depth:_delta_width withDisplacement:_axial_displacement];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self drawme]; //must be in the main thread
        if(face_test) _face_bool.text = @"Face detected";
        else _face_bool.text = @"No face";
    }];    /*
            
            //Update previous_widths
            for (NSNumber* width_reading in _widths) //iterate through LE_RE, RE_M, LE_M, facewidth
            {
            if ([width_reading compare:zero]) //reset case: measured width feature was reset
            {
            //reset state information about previous reading
            [_previous_widths replaceObjectAtIndex:[_widths indexOfObject:width_reading]withObject:zero];
            
            }
            else
            {
            //previous_widths should have the same size as _widths. determine the difference in width for this feature from the previous capture
            NSNumber *new_num = [NSNumber numberWithFloat: [width_reading floatValue] - [[ _previous_widths objectAtIndex:[_widths indexOfObject:width_reading] ] floatValue] ];
            [_previous_widths replaceObjectAtIndex:[_widths indexOfObject:width_reading]withObject:new_num];
            }
            
            }*/
}

- (void)drawLayer:(CALayer*)layer inContext:(CGContextRef)ctx
{
    /*
    if(trianglePoints.valid){
        //Draw a triangle path (inverted across x and y) using 3 points determined from facial feature recognizer
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, (offsetX-scalex*trianglePoints.LE_x), (offsetY-scaley*trianglePoints.LE_y));
        CGContextAddLineToPoint(ctx, (offsetX-scalex*trianglePoints.RE_x), (offsetY-scaley*trianglePoints.RE_y));
        CGContextAddLineToPoint(ctx, (offsetX-scalex*trianglePoints.Mouth_x), (offsetY-scaley*trianglePoints.Mouth_y));
        CGContextClosePath(ctx);
        
        //Leave the fill empty, create a dashed line along the perimeter of the triangle path
        CGContextSetFillColor(ctx, CGColorGetComponents([UIColor clearColor].CGColor));
        //CGContextSetFillColor(ctx, CGColorGetComponents(color1.CGColor));
        [[UIColor whiteColor] setStroke];
        CGContextSetLineWidth(ctx, 5.0);
        CGFloat dash1[] = {5.0, 2.0};
        CGContextSetLineDash(ctx, 0.0, dash1, 2);
        
        CGContextStrokePath(ctx);
        CGContextDrawPath(ctx, kCGPathFill);
    }
     */
}

- (void)drawme
{
   // [self.drawLayer setNeedsDisplay];
}

@end

