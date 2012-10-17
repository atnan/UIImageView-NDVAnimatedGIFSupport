/*
 * UIImageView+NDVAnimatedGIFSupport.m
 *
 * Copyright (c) 2012, Nathan de Vries.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of any
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <ImageIO/ImageIO.h>
#import <QuartzCore/QuartzCore.h>

@implementation UIImageView (NDVAnimatedGIFSupport)

- (id)ndv_initWithAnimatedGIFURL:(NSURL *)url {
  CGImageSourceRef sourceRef = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
  if (!sourceRef) return nil;

  UIImageView *imageView = [self _ndv_initWithCGImageSource:sourceRef];
  CFRelease(sourceRef);

  return imageView;
}

- (id)ndv_initWithAnimatedGIFData:(NSData *)data {
  CGImageSourceRef sourceRef = CGImageSourceCreateWithData((CFDataRef)data, NULL);
  if (!sourceRef) return nil;

  UIImageView *imageView = [self _ndv_initWithCGImageSource:sourceRef];
  CFRelease(sourceRef);

  return imageView;
}

- (id)_ndv_initWithCGImageSource:(CGImageSourceRef)sourceRef {
  size_t frameCount = CGImageSourceGetCount(sourceRef);

  NSMutableArray* frameImages = [NSMutableArray arrayWithCapacity:frameCount];
  NSMutableArray* frameDurations = [NSMutableArray arrayWithCapacity:frameCount];

  CFTimeInterval totalFrameDuration = 0.0;

  for (NSUInteger frameIndex = 0; frameIndex < frameCount; frameIndex++) {
    CGImageRef frameImageRef = CGImageSourceCreateImageAtIndex(sourceRef, frameIndex, NULL);
    [frameImages addObject:(id)frameImageRef];
    CGImageRelease(frameImageRef);

    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, frameIndex, NULL);
    CFDictionaryRef GIFProperties = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);

    NSNumber* duration = (NSNumber *)CFDictionaryGetValue(GIFProperties, kCGImagePropertyGIFDelayTime);
    [frameDurations addObject:duration];

    totalFrameDuration += [duration doubleValue];

    CFRelease(properties);
  }

  NSMutableArray* framePercentageDurations = [NSMutableArray arrayWithCapacity:frameCount];

  for (NSUInteger frameIndex = 0; frameIndex < frameCount; frameIndex++) {
    float currentDurationPercentage;

    if (frameIndex == 0) {
      currentDurationPercentage = 0.0;

    } else {
      NSNumber* previousDuration = [frameDurations objectAtIndex:frameIndex - 1];
      NSNumber* previousDurationPercentage = [framePercentageDurations objectAtIndex:frameIndex - 1];

      currentDurationPercentage = [previousDurationPercentage floatValue] + ([previousDuration floatValue] / totalFrameDuration);
    }

    [framePercentageDurations insertObject:[NSNumber numberWithFloat:currentDurationPercentage]
                                   atIndex:frameIndex];
  }

  CFDictionaryRef imageSourceProperties = CGImageSourceCopyProperties(sourceRef, NULL);
  CFDictionaryRef imageSourceGIFProperties = (CFDictionaryRef)CFDictionaryGetValue(imageSourceProperties, kCGImagePropertyGIFDictionary);
  NSNumber* imageSourceLoopCount = (NSNumber *)CFDictionaryGetValue(imageSourceGIFProperties, kCGImagePropertyGIFLoopCount);

  CFRelease(imageSourceProperties);

  CAKeyframeAnimation* frameAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];

  if ([imageSourceLoopCount floatValue] == 0.f) {
    frameAnimation.repeatCount = HUGE_VALF;

  } else {
    frameAnimation.repeatCount = [imageSourceLoopCount floatValue];
  }

  frameAnimation.calculationMode = kCAAnimationDiscrete;
  frameAnimation.values = frameImages;
  frameAnimation.duration = totalFrameDuration;
  frameAnimation.keyTimes = framePercentageDurations;
  frameAnimation.removedOnCompletion = NO;

  CGImageRef firstFrame = (CGImageRef)[frameImages objectAtIndex:0];
  UIImageView* imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, CGImageGetWidth(firstFrame), CGImageGetHeight(firstFrame))] autorelease];
  [[imageView layer] addAnimation:frameAnimation forKey:@"contents"];

  return imageView;
}

@end
